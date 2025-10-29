from fastapi import Depends, FastAPI, APIRouter, Query, BackgroundTasks
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse
from yt_dlp import YoutubeDL
import subprocess
import os
import uuid
from urllib.parse import quote

router = APIRouter();

DOWNLOAD_DIR = "downloads"
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

YTDLP_CMD = "yt_dlp"


@router.get("/audio")
def download_best_audio(url: str = Query(..., description="YouTube audio URL")):
    """
    🎵 Download best available audio as MP3, stream it, and auto-delete after sending.
    """
    temp_id = uuid.uuid4().hex
    temp_template = os.path.join(DOWNLOAD_DIR, f"{temp_id}.%(ext)s")

    ydl_opts = {
        "format": "bestaudio/best",
        "outtmpl": temp_template,
        "postprocessors": [
            {
                "key": "FFmpegExtractAudio",
                "preferredcodec": "mp3",
                "preferredquality": "192",
            }
        ],
        "quiet": True,
        "noprogress": True,
        "no_warnings": True,
        "ignoreerrors": True,
    }

    try:
        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
            if not info:
                raise Exception("Failed to extract audio info.")

        safe_title = info.get("title", f"audio_{temp_id}").replace('"', "").replace("'", "")
        final_path = os.path.join(DOWNLOAD_DIR, f"{safe_title[:50]}.mp3")

        # ✅ Find actual file if name mismatch occurs
        if not os.path.exists(final_path):
            possible_files = [f for f in os.listdir(DOWNLOAD_DIR) if f.endswith(".mp3")]
            if possible_files:
                latest_file = max(
                    [os.path.join(DOWNLOAD_DIR, f) for f in possible_files],
                    key=os.path.getmtime,
                )
                final_path = latest_file

        if not os.path.exists(final_path):
            raise Exception("Audio file not found after download.")

        def iterfile(path: str):
            try:
                with open(path, "rb") as file:
                    while chunk := file.read(8192):
                        yield chunk
            finally:
                if os.path.exists(path):
                    os.remove(path)

        filename_encoded = quote(os.path.basename(final_path))

        return StreamingResponse(
            iterfile(final_path),
            media_type="audio/mpeg",
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{filename_encoded}",
                "Access-Control-Expose-Headers": "Content-Disposition",
                "Cache-Control": "no-cache",
            },
        )

    except Exception as e:
        print(f"❌ Audio download error: {e}")
        return JSONResponse({"error": str(e)}, status_code=500)

    


@router.get("/video")
def download_best_video(url: str = Query(..., description="YouTube video URL")):
    temp_id = uuid.uuid4().hex
    temp_file = os.path.join(DOWNLOAD_DIR, f"{temp_id}.mp4")

    ydl_opts = {
        "format": "bestvideo+bestaudio/best",
        "merge_output_format": "mp4",
        "outtmpl": temp_file,
        "restrictfilenames": True,
        "quiet": True,
        "no_warnings": True,
    }

    try:
        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)

        safe_title = info.get("title", "video").replace('"', "").replace("'", "")
        final_path = os.path.join(DOWNLOAD_DIR, f"{safe_title[:50]}.mp4")
        os.rename(temp_file, final_path)

        def iterfile(path: str):
            try:
                with open(path, "rb") as file:
                    for chunk in file:
                        yield chunk
            finally:
                if os.path.exists(path):
                    os.remove(path)

        filename_encoded = quote(os.path.basename(final_path))

        return StreamingResponse(
            iterfile(final_path),
            media_type="video/mp4",
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{filename_encoded}",
                "Access-Control-Expose-Headers": "Content-Disposition",
                "Cache-Control": "no-cache",
            },
        )

    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)
