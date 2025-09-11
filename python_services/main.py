
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import FileResponse
from typing import List
import uvicorn
import tempfile
import os
import pytesseract
from PIL import Image
import fitz  # PyMuPDF
import librosa
import numpy as np
import matplotlib.pyplot as plt
import uuid

app = FastAPI()

@app.post('/ocr')
async def ocr_image(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False, suffix='.png') as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    text = pytesseract.image_to_string(Image.open(tmp_path))
    os.unlink(tmp_path)
    return {"text": text}

@app.post('/pdf/process')
async def process_pdf(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    doc = fitz.open(tmp_path)
    meta = doc.metadata
    page_count = doc.page_count
    doc.close()
    os.unlink(tmp_path)
    return {"meta": meta, "page_count": page_count}

@app.post('/audio/analyze')
async def analyze_audio(file: UploadFile = File(...)):
    with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    y, sr = librosa.load(tmp_path, sr=None)
    duration = librosa.get_duration(y=y, sr=sr)
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)
    os.unlink(tmp_path)
    return {"duration": duration, "tempo": tempo}

@app.post('/chart/generate')
async def generate_chart(data: List[float] = Form(...)):
    fig, ax = plt.subplots()
    ax.plot(data)
    chart_id = str(uuid.uuid4())
    chart_path = f"/tmp/chart_{chart_id}.png"
    plt.savefig(chart_path)
    plt.close(fig)
    return FileResponse(chart_path, media_type='image/png', filename=f'chart_{chart_id}.png')

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
