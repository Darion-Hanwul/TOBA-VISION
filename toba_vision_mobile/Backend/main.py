import os
import io
import requests
from PIL import Image
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud import firestore as g_firestore
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
from dotenv import load_dotenv

# 1. Load Environment Variables
load_dotenv()
IMGBB_API_KEY = os.getenv("IMGBB_API_KEY")
FIREBASE_CRED_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase_key.json")

# 2. Inisialisasi Firebase Admin SDK
if not firebase_admin._apps:
    cred = credentials.Certificate(FIREBASE_CRED_PATH)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 3. Load Model YOLOv11 & Pemetaan Label
MODEL_PATH = os.path.join("models", "best.pt")
if os.path.exists(MODEL_PATH):
    model = YOLO(MODEL_PATH)
else:
    raise FileNotFoundError(f"File model tidak ditemukan di {MODEL_PATH}")

LABEL_MAPPING = {
    "Mature": "Grade A",
    "Immature": "Grade B",
    "Overripe": "Grade C"
}

# 4. Inisialisasi Aplikasi FastAPI
app = FastAPI(title="TobaVision AI Backend API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "Backend TobaVision aktif!"}

# 5. Endpoint Prediksi AI, Upload ImgBB, & Simpan Firebase
@app.post("/api/predict")
async def predict_tobacco_grade(file: UploadFile = File(...)):
    try:
        # A. Baca File Gambar
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes))

        # B. Prediksi Gambar
        results = list(model(image))
        top1_index = int(results[0].probs.top1) # type: ignore
        raw_label = str(model.names[top1_index])
        confidence = float(results[0].probs.top1conf) # type: ignore

        # Ubah label ke format Grade
        grade_result = LABEL_MAPPING.get(raw_label, raw_label)

        print(f"--> [LOG BACKEND] Hasil Label Asli: {raw_label} | Konversi Grade: {grade_result} | Confidence: {round(confidence * 100, 2)}%")

        # C. Unggah Gambar ke ImgBB
        imgbb_response = requests.post(
            "https://api.imgbb.com/1/upload",
            data={"key": IMGBB_API_KEY},
            files={"image": image_bytes}
        )
        imgbb_data = imgbb_response.json()
        
        if not imgbb_data.get("success"):
            raise HTTPException(status_code=400, detail="Gagal mengunggah gambar ke ImgBB")

        image_url = imgbb_data["data"]["url"]

        # D. Simpan Hasil Deteksi ke Firestore Firebase
        doc_ref = db.collection("detections").document()
        payload = {
            "image_url": image_url,
            "grade": grade_result,
            "raw_label": raw_label,
            "confidence": round(confidence * 100, 2),
            "created_at": g_firestore.SERVER_TIMESTAMP
        }
        doc_ref.set(payload)

        # E. Balas Respon ke Client / Frontend
        return {
            "status": "success",
            "id": doc_ref.id,
            "grade": grade_result,
            "confidence": f"{round(confidence * 100, 2)}%",
            "image_url": image_url
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))