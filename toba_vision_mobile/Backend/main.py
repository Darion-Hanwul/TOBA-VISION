import os
import io
import datetime
import httpx
from PIL import Image
from typing import Optional, List
from pydantic import BaseModel
from dotenv import load_dotenv

import firebase_admin
from firebase_admin import credentials, firestore, auth, messaging
from google.cloud import firestore as g_firestore

from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import cloudinary
import cloudinary.uploader

# ==========================================
# 1. LOAD ENVIRONMENT VARIABLES & CONFIG
# ==========================================
load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

WEATHER_API_KEY = os.getenv("WEATHER_API_KEY")
FIREBASE_CRED_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_key.json")
MODEL_PATH = os.getenv("MODEL_PATH", os.path.join("models", "best.pt"))
ENV_MODE = os.getenv("ENV_MODE", "development")

# ==========================================
# 2. INISIALISASI FIREBASE ADMIN SDK
# ==========================================
if not firebase_admin._apps:
    if os.path.exists(FIREBASE_CRED_PATH):
        cred = credentials.Certificate(FIREBASE_CRED_PATH)
        firebase_admin.initialize_app(cred)
        print("--> [SUCCESS] Firebase Admin SDK terhubung.")
    else:
        print(f"--> [WARNING] File '{FIREBASE_CRED_PATH}' tidak ditemukan!")

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
    print(f"--> [INFO] Model belum ditemukan di '{MODEL_PATH}'. Fallback dummy active.")

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
    description="API Deteksi Grade Tembakau, Auth, Cuaca, Finansial, Panen, & Offline Sync",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 5. ENDPOINT UTAMA & UTILITY
# ==========================================
@app.get("/")
def root():
    return {
        "status": "online",
        "env_mode": ENV_MODE,
        "message": "Backend Toba Vision Aktif!",
        "model_loaded": model is not None,
        "firebase_connected": db is not None
    }

# ==========================================
# 6. ENDPOINT SYNC & GET PROFIL PETANI (AUTH)
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
        return {"status": "success", "message": "Profil petani berhasil disimpan.", "uid": data.uid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/petani/{uid}")
async def get_petani_profile(uid: str):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        doc = db.collection("petani").document(uid).get()
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Profil petani tidak ditemukan.")
        data = doc.to_dict()
        data["uid"] = uid  # type: ignore
        return data
    except HTTPException:
        raise
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
            raise HTTPException(status_code=400, detail="File harus berupa gambar.")

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
# 8. ENDPOINT INTEGRASI WEATHER API PRESISI (14 HARI) & FCM PUSH ALARM
# ==========================================
def _classify_weather_tier(temp_c: float, rain_prob: int, precip_mm: float, condition_text: str, weather_code: int = 1):
    cond = condition_text.lower()
    # MERAH: HANYA jika benar-benar hujan lebat/badai (curah hujan >= 2.0 mm atau kode hujan deras >= 63)
    is_heavy_rain = (
        weather_code >= 63
        or precip_mm >= 2.0
        or any(k in cond for k in ["heavy rain", "thunder", "storm", "torrential", "hujan lebat", "hujan deras", "badai", "petir"])
    )
    if is_heavy_rain:
        return "red", True, "BAHAYA HUJAN DERAS • Segera angkat sasak ke gudang!"

    # KUNING: Gerimis ringan, mendung tebal, peluang hujan >= 55%, atau suhu sejuk < 26.5°C
    is_caution = (
        (45 <= weather_code <= 61)
        or weather_code == 80
        or precip_mm > 0.0
        or rain_prob >= 55
        or temp_c < 26.5
        or any(k in cond for k in ["rain", "drizzle", "shower", "overcast", "mist", "fog", "gerimis", "mendung"])
    )
    if is_caution:
        return "yellow", False, "WASPADA • Mendung / Potensi Hujan, siapkan terpal."

    # HIJAU: Cerah / berawan normal dan kering
    return "green", False, "AMAN JEMUR • Panas terik optimal untuk penjemuran daun."


def _wmo_code_to_indo(code: int, hour_int: int = 12) -> str:
    if code >= 95:
        return "Badai Petir"
    if code >= 65:
        return "Hujan Sangat Deras"
    if code >= 63:
        return "Hujan Lebat"
    if code >= 51 or code == 80:
        return "Gerimis / Hujan Ringan"
    if code >= 45:
        return "Mendung Tebal"
    if code >= 2:
        return "Cerah Berawan"
    if hour_int >= 18 or hour_int < 6:
        return "Cerah Malam"
    return "Panas Terik Cerah"


def _build_day_summary_from_hours(
    date_str: str,
    max_temp: float,
    min_temp: float,
    max_prob: int,
    total_mm: float,
    cond_text: str,
    hours_list: list
):
    hot_hours = []
    rain_hours = []
    for h in hours_list:
        h_int = int(h["time"].split(":")[0])
        if 6 <= h_int <= 20:
            if h["tier"] == "green" and h["temp_c"] >= 27.0 and 7 <= h_int <= 16:
                hot_hours.append(h["time"])
            if h["tier"] == "red" or h["precip_mm"] >= 0.2 or h["chance_of_rain"] >= 60:
                rain_hours.append(h["time"])

    hot_window = (
        f"{hot_hours[0]} – {hot_hours[-1]}"
        if hot_hours
        else "Tidak ada panas terik optimal"
    )
    rain_window = (
        f"Mulai {rain_hours[0]} – {rain_hours[-1]} (Peluang maks {max_prob}%)"
        if rain_hours
        else "Aman, tidak ada potensi hujan"
    )

    if rain_hours and hot_hours:
        verdict = (
            f"Jemur pagi–siang ({hot_hours[0]}–{rain_hours[0]}), lalu wajib angkat sasak "
            f"sebelum pukul {rain_hours[0]} karena berpotensi turun hujan!"
        )
    elif not rain_hours and hot_hours:
        verdict = "Seharian cerah terik! Sangat ideal untuk menjemur daun tembakau hingga kering maksimal."
    elif rain_hours:
        verdict = f"Berpotensi hujan mulai pukul {rain_hours[0]}. Siapkan terpal atau simpan daun di gudang pengering."
    else:
        verdict = "Cuaca berawan sejuk. Jemur dengan pengawasan dan siapkan terpal pelindung."

    return {
        "date": date_str,
        "max_temp_c": round(max_temp, 1),
        "min_temp_c": round(min_temp, 1),
        "max_chance_of_rain": int(max_prob),
        "total_precip_mm": round(total_mm, 1),
        "condition": cond_text,
        "hot_window": hot_window,
        "rain_window": rain_window,
        "summary_verdict": verdict,
        "hours": hours_list,
    }


@app.get("/api/weather")
async def get_weather(
    location: str = "Jember",
    lat: Optional[float] = None,
    lon: Optional[float] = None,
    days: int = 14
):
    use_lat = lat if lat is not None else -8.1724
    use_lon = lon if lon is not None else 113.7007
    forecast_days = max(1, min(days, 14))

    om_url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={use_lat}&longitude={use_lon}"
        f"&current=temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m"
        f"&hourly=temperature_2m,precipitation_probability,precipitation,weather_code"
        f"&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max"
        f"&timezone=auto&forecast_days={forecast_days}"
    )
    async with httpx.AsyncClient(timeout=10.0) as client:
        om_res = await client.get(om_url)

    if om_res.status_code != 200:
        raise HTTPException(status_code=502, detail="Gagal mengambil data cuaca satelit dari server.")

    om = om_res.json()
    curr = om.get("current", {})
    temp_c = round(float(curr.get("temperature_2m", 28.0)), 1)
    humidity = int(curr.get("relative_humidity_2m", 65))
    precip_mm = float(curr.get("precipitation", 0.0))
    wcode = int(curr.get("weather_code", 1))
    now_hour = datetime.datetime.now().hour
    cond_text = _wmo_code_to_indo(wcode, now_hour)

    # Parse seluruh data per jam
    hourly_raw = om.get("hourly", {})
    h_times = hourly_raw.get("time", [])
    h_temps = hourly_raw.get("temperature_2m", [])
    h_probs = hourly_raw.get("precipitation_probability", [])
    h_precips = hourly_raw.get("precipitation", [])
    h_codes = hourly_raw.get("weather_code", [])

    hours_by_date = {}
    current_rain_prob = 0
    now_prefix = datetime.datetime.now().strftime("%Y-%m-%dT%H")

    for i, t_str in enumerate(h_times):
        date_part, time_part = t_str.split("T")
        h_int = int(time_part.split(":")[0])
        h_temp = round(float(h_temps[i] if i < len(h_temps) and h_temps[i] is not None else 27.0), 1)
        h_prob = int(h_probs[i] if i < len(h_probs) and h_probs[i] is not None else 0)
        h_mm = float(h_precips[i] if i < len(h_precips) and h_precips[i] is not None else 0.0)
        h_code = int(h_codes[i] if i < len(h_codes) and h_codes[i] is not None else 1)
        h_cond = _wmo_code_to_indo(h_code, h_int)
        h_tier, _, _ = _classify_weather_tier(h_temp, h_prob, h_mm, h_cond, h_code)

        if t_str.startswith(now_prefix):
            current_rain_prob = h_prob

        hours_by_date.setdefault(date_part, []).append({
            "time": time_part,
            "temp_c": h_temp,
            "condition": h_cond,
            "chance_of_rain": h_prob,
            "precip_mm": h_mm,
            "weather_code": h_code,
            "tier": h_tier,
        })

    # Parse harian (akurat hingga 14 hari ke depan)
    daily_raw = om.get("daily", {})
    d_times = daily_raw.get("time", [])
    d_max = daily_raw.get("temperature_2m_max", [])
    d_min = daily_raw.get("temperature_2m_min", [])
    d_sum = daily_raw.get("precipitation_sum", [])
    d_prob = daily_raw.get("precipitation_probability_max", [])
    d_codes = daily_raw.get("weather_code", [])

    daily_forecast = []
    for i, d_str in enumerate(d_times):
        max_t = float(d_max[i] if i < len(d_max) and d_max[i] is not None else 30.0)
        min_t = float(d_min[i] if i < len(d_min) and d_min[i] is not None else 22.0)
        sum_mm = float(d_sum[i] if i < len(d_sum) and d_sum[i] is not None else 0.0)
        max_p = int(d_prob[i] if i < len(d_prob) and d_prob[i] is not None else 0)
        d_code = int(d_codes[i] if i < len(d_codes) and d_codes[i] is not None else 1)

        day_obj = _build_day_summary_from_hours(
            date_str=d_str,
            max_temp=max_t,
            min_temp=min_t,
            max_prob=max_p,
            total_mm=sum_mm,
            cond_text=_wmo_code_to_indo(d_code, 12),
            hours_list=hours_by_date.get(d_str, []),
        )
        daily_forecast.append(day_obj)

    tier, _, status_msg = _classify_weather_tier(temp_c, current_rain_prob, precip_mm, cond_text, wcode)
    emergency_alert = (
        f"ALARM CUACA ({location}): Suhu {temp_c}°C, curah hujan {precip_mm} mm. "
        "Segera amankan sasak tembakau ke gudang!"
        if tier == "red"
        else None
    )

    today_slots = daily_forecast[0]["hours"] if daily_forecast else []
    hourly_forecast_compact = [
        {
            "time": h["time"],
            "temp_c": f"{round(h['temp_c'])}°C",
            "condition": h["condition"],
            "chance_of_rain": f"{h['chance_of_rain']}%",
        }
        for h in today_slots
        if int(h["time"].split(":")[0]) in [11, 13, 16]
    ]

    return {
        "status": "success",
        "location": location,
        "region": "Indonesia",
        "current": {
            "temp_c": f"{temp_c}°C",
            "numeric_temp_c": temp_c,
            "humidity": humidity,
            "chance_of_rain": current_rain_prob,
            "precip_mm": precip_mm,
            "weather_code": wcode,
            "condition": cond_text,
            "is_rain": tier == "red",
            "tier": tier,
        },
        "recommendation": {
            "warning_message": status_msg,
            "emergency_alert": emergency_alert,
        },
        "hourly_forecast": hourly_forecast_compact,
        "daily_forecast": daily_forecast,
    }


class RegisterFcmTokenSchema(BaseModel):
    uid_petani: str
    fcm_token: str
    platform: Optional[str] = "android"


@app.post("/api/cuaca/register-token")
async def register_fcm_token(data: RegisterFcmTokenSchema):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        db.collection("petani").document(data.uid_petani).set({
            "fcm_token": data.fcm_token,
            "fcm_platform": data.platform,
            "fcm_updated_at": g_firestore.SERVER_TIMESTAMP,
        }, merge=True)
        return {"status": "success", "message": "Token notifikasi alarm cuaca terdaftar."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class WeatherPushAlertSchema(BaseModel):
    uid_petani: Optional[str] = ""
    fcm_token: Optional[str] = None
    lokasi: str = "Kebun Tembakau"
    suhu_c: float = 22.0
    peluang_hujan: int = 85
    curah_hujan_mm: float = 5.0


@app.post("/api/cuaca/alert-push")
async def send_weather_alarm_push(data: WeatherPushAlertSchema):
    if not firebase_admin._apps:
        raise HTTPException(status_code=500, detail="Firebase Admin SDK belum terhubung.")

    target_token = data.fcm_token
    if not target_token and db is not None and data.uid_petani:
        doc = db.collection("petani").document(data.uid_petani).get()
        if doc.exists:
            target_token = (doc.to_dict() or {}).get("fcm_token")

    title = f"🚨 ALARM HUJAN DERAS • {data.lokasi}"
    body = (
        f"Suhu turun ke {data.suhu_c:.1f}°C (curah hujan {data.curah_hujan_mm:.1f} mm). "
        "Segera angkat sasak jemuran daun tembakau ke gudang!"
    )

    try:
        android_cfg = messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="toba_weather_alarm_channel",
                sound="default",
                priority="max",
                default_vibrate_timings=True,
                color="#DC2626",
            ),
        )
        webpush_cfg = messaging.WebpushConfig(
            headers={"Urgency": "high"},
            notification=messaging.WebpushNotification(
                title=title,
                body=body,
                require_interaction=True,
            ),
        )

        if target_token:
            msg = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                android=android_cfg,
                webpush=webpush_cfg,
                data={"type": "HEAVY_RAIN_ALARM", "lokasi": data.lokasi},
                token=target_token,
            )
            msg_id = messaging.send(msg)
            return {"status": "success", "message_id": msg_id, "target": "device_token"}

        topic_msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            android=android_cfg,
            webpush=webpush_cfg,
            data={"type": "HEAVY_RAIN_ALARM", "lokasi": data.lokasi},
            topic="toba_weather_alerts",
        )
        msg_id = messaging.send(topic_msg)
        return {"status": "success", "message_id": msg_id, "target": "topic_toba_weather_alerts"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal mengirim FCM push notification: {e}")

# ==========================================
# 9. ENDPOINT PANEN (POST & GET)
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
        return {"status": "success", "message": "Catatan petikan panen disimpan.", "id_petikan": doc_ref.id}
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
# 10. ENDPOINT FINANSIAL (POST & GET)
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
        return {"status": "success", "message": "Catatan pengeluaran disimpan.", "id_biaya": doc_ref.id}
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
            "riwayat_pengeluaran": list_biaya,
            "total_pengeluaran": total_biaya
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 11. ENDPOINT BATCH SYNC DATA OFFLINE
# ==========================================
class BatchSyncSchema(BaseModel):
    id_siklus: str
    list_petikan: Optional[List[PetikanPanenSchema]] = []
    list_biaya: Optional[List[BiayaOperasionalSchema]] = []

@app.post("/api/sync/offline-data")
async def sync_offline_data(data: BatchSyncSchema):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        batch = db.batch()

        if data.list_petikan:
            for item in data.list_petikan:
                doc_ref = db.collection("siklus_tanam").document(data.id_siklus).collection("petikan_panen").document()
                batch.set(doc_ref, {
                    "id_petikan": doc_ref.id,
                    "petikan_ke": item.petikan_ke,
                    "berat_kg": item.berat_kg,
                    "total_pendapatan": item.total_pendapatan,
                    "created_at": g_firestore.SERVER_TIMESTAMP
                })

        if data.list_biaya:
            for item in data.list_biaya:
                doc_ref = db.collection("siklus_tanam").document(data.id_siklus).collection("biaya_operasional").document()
                batch.set(doc_ref, {
                    "id_biaya": doc_ref.id,
                    "nama_pengeluaran": item.nama_pengeluaran,
                    "kategori": item.kategori,
                    "jumlah_biaya": item.jumlah_biaya,
                    "keterangan": item.keterangan,
                    "created_at": g_firestore.SERVER_TIMESTAMP
                })

        batch.commit()
        return {"status": "success", "message": "Data offline berhasil disinkronkan."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ==========================================
# 12. ENDPOINT TUTUP BUKU & ARSIP MUSIM (PERSISTEN FIRESTORE)
# ==========================================
class TutupSiklusSchema(BaseModel):
    uid_petani: str = "guest_petani"
    title: str
    period: str
    expenses: str
    raw_expenses: float
    revenue: str
    raw_revenue: float
    profit: str
    raw_profit: float
    harvest: str
    raw_weight: float
    category_breakdown: dict = {}
    stages: list = []

@app.post("/api/siklus/{id_siklus}/tutup")
async def tutup_siklus_panen(id_siklus: str, data: Optional[TutupSiklusSchema] = None):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        siklus_ref = db.collection("siklus_tanam").document(id_siklus)

        archive_id = None
        if data is not None:
            archive_ref = db.collection("arsip_musim").document()
            archive_id = archive_ref.id
            archive_payload = {
                "id_arsip": archive_id,
                "id_siklus": id_siklus,
                "uid_petani": data.uid_petani,
                "title": data.title,
                "period": data.period,
                "expenses": data.expenses,
                "raw_expenses": data.raw_expenses,
                "revenue": data.revenue,
                "raw_revenue": data.raw_revenue,
                "profit": data.profit,
                "raw_profit": data.raw_profit,
                "harvest": data.harvest,
                "raw_weight": data.raw_weight,
                "category_breakdown": data.category_breakdown,
                "stages": data.stages,
                "status": "Selesai",
                "closed_at": g_firestore.SERVER_TIMESTAMP,
            }
            archive_ref.set(archive_payload)

        batch = db.batch()
        for doc in siklus_ref.collection("biaya_operasional").stream():
            batch.delete(doc.reference)
        for doc in siklus_ref.collection("petikan_panen").stream():
            batch.delete(doc.reference)

        batch.set(siklus_ref, {
            "status_siklus": "Aktif",
            "last_closed_at": g_firestore.SERVER_TIMESTAMP,
        }, merge=True)
        batch.commit()

        return {
            "status": "success",
            "message": "Buku musim berhasil ditutup, diarsipkan ke Firestore, dan siklus direset ke 0.",
            "id_arsip": archive_id,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/arsip-musim/{uid_petani}")
async def get_arsip_musim_petani(uid_petani: str):
    if db is None:
        raise HTTPException(status_code=500, detail="Firestore belum terhubung.")
    try:
        docs = (
            db.collection("arsip_musim")
            .where("uid_petani", "==", uid_petani)
            .stream()
        )
        archives = []
        for doc in docs:
            item = doc.to_dict()
            if item is not None:
                item["id_arsip"] = doc.id
                if "closed_at" in item and item["closed_at"] is not None:
                    item["closed_at"] = str(item["closed_at"])
                archives.append(item)

        archives.sort(key=lambda x: str(x.get("title", "")), reverse=True)
        return {
            "status": "success",
            "data": archives,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))