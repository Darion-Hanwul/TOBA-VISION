import os
import io
import datetime
import httpx
from PIL import Image
from typing import Optional
from pydantic import BaseModel
from dotenv import load_dotenv

import firebase_admin
from firebase_admin import credentials, firestore, auth, messaging
from google.cloud import firestore as g_firestore

from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import cloudinary
import cloudinary.uploader

# ==========================================
# 1. LOAD ENVIRONMENT VARIABLES & CONFIG
# ==========================================
load_dotenv()

# Konfigurasi Cloudinary
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY")
FIREBASE_CRED_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_key.json")
MODEL_PATH = os.getenv("MODEL_PATH", os.path.join("models", "best.pt"))

# ==========================================
# 2. INISIALISASI FIREBASE ADMIN SDK
# ==========================================
if not firebase_admin._apps:
    if os.path.exists(FIREBASE_CRED_PATH):
        cred = credentials.Certificate(FIREBASE_CRED_PATH)
        firebase_admin.initialize_app(cred)
        print("--> [SUCCESS] Firebase Admin SDK terhubung.")
    else:
        print(f"--> [WARNING] File '{FIREBASE_CRED_PATH}' tidak ditemukan! Firestore tidak akan berfungsi.")

db = firestore.client() if firebase_admin._apps else None

# ==========================================
# 3. LOAD MODEL YOLOv11 & LABEL MAPPING
# ==========================================
model = None
if os.path.exists(MODEL_PATH):
    try:
        model = YOLO(MODEL_PATH)
        print(f"--> [SUCCESS] Model YOLOv11 berhasil dimuat dari {MODEL_PATH}.")
    except Exception as e:
        print(f"--> [ERROR] Gagal memuat model YOLO: {e}")
else:
    print(f"--> [INFO] Model belum ditemukan di '{MODEL_PATH}'. Sistem menggunakan fallback dummy mode.")

LABEL_MAPPING = {
    "Mature": "Grade A",
    "Immature": "Grade B",
    "Overripe": "Grade C"
}

# ==========================================
# 4. INISIALISASI FASTAPI & MIDDLEWARE
# ==========================================
app = FastAPI(
    title="Toba Vision Backend API",
    description="API untuk Deteksi Grade Tembakau, Autentikasi Petani, Cuaca, Finansial, dan Panen di Firestore",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware Helper: Verifikasi Token Firebase Auth (Opsional)
async def get_current_user_uid(authorization: str = Header(...)) -> str:
    try:
        token = authorization.split("Bearer ")[1]
        decoded_token = auth.verify_id_token(token)
        return decoded_token["uid"]
    except Exception:
        raise HTTPException(status_code=401, detail="Token Firebase tidak valid atau telah kadaluwarsa.")

# ==========================================
# 5. ENDPOINT UTAMA & UTILITY
# ==========================================
@app.get("/")
def root():
    return {
        "status": "online",
        "message": "Backend Toba Vision Aktif!",
        "model_loaded": model is not None,
        "firebase_connected": db is not None
    }

# ==========================================
# 6. ENDPOINT SYNC PROFIL PETANI (AUTH)
# ==========================================
class SyncPetaniSchema(BaseModel):
    uid: str
    nama: str
    alamat_lahan: Optional[str] = ""
    no_telepon: Optional[str] = ""
    luas_lahan: Optional[float] = 0.0

@app.post("/api/petani/sync-profile")
async def sync_petani_profile(data: SyncPetaniSchema):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    
    try:
        doc_ref = db.collection("petani").document(data.uid)
        payload = {
            "nama": data.nama,
            "alamat_lahan": data.alamat_lahan,
            "no_telepon": data.no_telepon,
            "luas_lahan": data.luas_lahan,
            "created_at": g_firestore.SERVER_TIMESTAMP
        }
        doc_ref.set(payload, merge=True)
        
        return {
            "status": "success",
            "message": "Profil petani berhasil disimpan ke Firestore.",
            "uid": data.uid
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 7. ENDPOINT DETEKSI AI & UPLOAD CLOUDINARY
# ==========================================
@app.post("/api/predict")
async def predict_tobacco_grade(
    file: UploadFile = File(...),
    id_petani: str = "guest_petani",
    id_petikan: Optional[str] = None
):
    try:
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File yang diunggah harus berupa gambar.")

        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))

        if model is not None:
            results = list(model(image))
            top1_index = int(results[0].probs.top1)  # type: ignore
            raw_label = str(model.names[top1_index])
            confidence = float(results[0].probs.top1conf)  # type: ignore
            predicted_grade = LABEL_MAPPING.get(raw_label, raw_label)
            confidence_score = round(confidence * 100, 2)
        else:
            raw_label = "Immature"
            predicted_grade = "Grade B"
            confidence_score = 98.92

        upload_result = cloudinary.uploader.upload(
            image_bytes,
            folder="toba_vision/detections",
            resource_type="image"
        )
        foto_daun_path = upload_result.get("secure_url")

        doc_id = "mock_detection_id"
        if db is not None:
            doc_ref = db.collection("riwayat_deteksi_ai").document()
            doc_id = doc_ref.id
            payload = {
                "id_deteksi": doc_id,
                "id_petani": id_petani,
                "id_petikan": id_petikan if id_petikan else "",
                "foto_daun_path": foto_daun_path,
                "predicted_grade": predicted_grade,
                "confidence_score": confidence_score,
                "anomali_warna": raw_label,
                "waktu_deteksi": g_firestore.SERVER_TIMESTAMP
            }
            doc_ref.set(payload)

        return {
            "status": "success",
            "id_deteksi": doc_id,
            "predicted_grade": predicted_grade,
            "confidence_score": confidence_score,
            "anomali_warna": raw_label,
            "foto_daun_path": foto_daun_path
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 8. ENDPOINT INTEGRASI WEATHER API
# ==========================================
@app.get("/api/weather")
async def get_weather(location: str = "Temanggung"):
    if not WEATHER_API_KEY:
        raise HTTPException(status_code=500, detail="WEATHER_API_KEY belum diisi di file .env")

    url = f"http://api.weatherapi.com/v1/forecast.json?key={WEATHER_API_KEY}&q={location}&days=1&aqi=no&alerts=no"

    async with httpx.AsyncClient() as client:
        response = await client.get(url)

    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Gagal mengambil data dari WeatherAPI.")

    data = response.json()

    temp_c = round(data["current"]["temp_c"])
    condition_text = data["current"]["condition"]["text"]
    precip_mm = data["current"].get("precip_mm", 0)
    
    is_rain = "rain" in condition_text.lower() or "hujan" in condition_text.lower() or precip_mm > 0

    if is_rain:
        warning_message = "Jangan jemur! Hujan lebat sebentar lagi."
        emergency_alert = "Awas Pak! Hujan mau turun. Segera angkat sasak ke gudang biar daun tembakau tidak rusak!"
    else:
        warning_message = "Aman untuk penjemuran daun tembakau."
        emergency_alert = None

    hourly_forecast = []
    hours_to_extract = [11, 13, 16]
    all_hours = data["forecast"]["forecastday"][0]["hour"]

    for hour_data in all_hours:
        hour_time = hour_data["time"].split(" ")[1]
        hour_int = int(hour_time.split(":")[0])

        if hour_int in hours_to_extract:
            hourly_forecast.append({
                "time": hour_time,
                "temp_c": f"{round(hour_data['temp_c'])}°C",
                "condition": hour_data["condition"]["text"],
                "chance_of_rain": f"{hour_data.get('chance_of_rain', 0)}%"
            })

    return {
        "status": "success",
        "location": data["location"]["name"],
        "region": data["location"]["region"],
        "current": {
            "temp_c": f"{temp_c}°C",
            "condition": condition_text,
            "is_rain": is_rain
        },
        "recommendation": {
            "warning_message": warning_message,
            "emergency_alert": emergency_alert
        },
        "hourly_forecast": hourly_forecast
    }

# ==========================================
# 9. ENDPOINT PANEN (SIMPAN & READ PETIKAN)
# ==========================================
class PetikanPanenSchema(BaseModel):
    id_siklus: str
    petikan_ke: int
    berat_kg: float
    total_pendapatan: float

@app.post("/api/panen/petikan")
async def simpan_petikan_panen(data: PetikanPanenSchema):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        doc_ref = db.collection("siklus_tanam").document(data.id_siklus).collection("petikan_panen").document()
        payload = {
            "id_petikan": doc_ref.id,
            "petikan_ke": data.petikan_ke,
            "berat_kg": data.berat_kg,
            "total_pendapatan": data.total_pendapatan,
            "created_at": g_firestore.SERVER_TIMESTAMP
        }
        doc_ref.set(payload)
        return {"status": "success", "message": "Catatan petikan panen berhasil disimpan.", "id_petikan": doc_ref.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/panen/{id_siklus}")
async def get_rekap_panen(id_siklus: str):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        petikan_ref = db.collection("siklus_tanam").document(id_siklus).collection("petikan_panen")
        docs = petikan_ref.stream()

        list_petikan = []
        total_bobot_kg = 0.0
        total_pendapatan = 0.0

        for doc in docs:
            data = doc.to_dict()
            data["id_petikan"] = doc.id
            list_petikan.append(data)
            
            total_bobot_kg += float(data.get("berat_kg", 0.0))
            total_pendapatan += float(data.get("total_pendapatan", 0.0))

        return {
            "status": "success",
            "total_bobot_kg": total_bobot_kg,
            "total_pendapatan": total_pendapatan,
            "riwayat_petikan": list_petikan
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 10. ENDPOINT FINANSIAL (SIMPAN & READ BIAYA)
# ==========================================
class BiayaOperasionalSchema(BaseModel):
    id_siklus: str
    nama_pengeluaran: str
    kategori: str
    jumlah_biaya: float
    keterangan: Optional[str] = ""

@app.post("/api/finansial/biaya")
async def tambah_biaya_operasional(data: BiayaOperasionalSchema):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        doc_ref = db.collection("siklus_tanam").document(data.id_siklus).collection("biaya_operasional").document()
        payload = {
            "id_biaya": doc_ref.id,
            "nama_pengeluaran": data.nama_pengeluaran,
            "kategori": data.kategori,
            "jumlah_biaya": data.jumlah_biaya,
            "keterangan": data.keterangan,
            "created_at": g_firestore.SERVER_TIMESTAMP
        }
        doc_ref.set(payload)
        return {"status": "success", "message": "Catatan pengeluaran berhasil disimpan.", "id_biaya": doc_ref.id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/finansial/{id_siklus}")
async def get_rekap_finansial(id_siklus: str):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        biaya_ref = db.collection("siklus_tanam").document(id_siklus).collection("biaya_operasional")
        docs = biaya_ref.stream()
        
        list_biaya = []
        total_biaya = 0.0
        rincian_kategori = {}

        for doc in docs:
            data = doc.to_dict()
            data["id_biaya"] = doc.id
            list_biaya.append(data)
            
            jumlah = float(data.get("jumlah_biaya", 0.0))
            kategori = data.get("kategori", "Lainnya / Tambahan")
            
            total_biaya += jumlah
            rincian_kategori[kategori] = rincian_kategori.get(kategori, 0.0) + jumlah

        return {
            "status": "success",
            "total_biaya": total_biaya,
            "rincian_kategori": rincian_kategori,
            "riwayat_pengeluaran": list_biaya
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))