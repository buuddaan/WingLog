from flask import Flask, request, jsonify
import birdnet
import tempfile
import os
import numpy as np
import soundfile as sf

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB

model = birdnet.load('acoustic', '2.4', 'tf')

@app.route("/analyze", methods=["POST"])
def analyze():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    audio_file = request.files["file"]

    ext = os.path.splitext(audio_file.filename)[1] or ".tmp"
    with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
        audio_file.save(tmp.name)
        tmp_path = tmp.name

    try:
        try:
            audio, rate = sf.read(tmp_path)
        except Exception:
            import av as pyav
            container = pyav.open(tmp_path)
            stream = container.streams.audio[0]
            rate = stream.codec_context.sample_rate
            frames = []
            for frame in container.decode(audio=0):
                frames.append(frame.to_ndarray().flatten().astype(np.float32) / 32768.0)
            container.close()
            audio = np.concatenate(frames)
        if audio.ndim > 1:
            audio = audio.mean(axis=1)

        audio = audio.astype(np.float32)
        chunk_size = model.get_segment_size_samples()
        chunks = [audio[i:i+chunk_size] for i in range(0, len(audio), chunk_size)]
        chunks = [c for c in chunks if len(c) == chunk_size]

        if not chunks:
            return jsonify({"birdName": "Unknown", "scientificName": "Unknown", "confidence": 0.0})

        tuples = [(chunk, rate) for chunk in chunks]
        results = list(model.predict_arrays(tuples))

        if not results:
            return jsonify({"birdName": "Unknown", "scientificName": "Unknown", "confidence": 0.0})

        best = max(results, key=lambda x: x['confidence'])
        parts = best['species_name'].split("_")
        scientific_name = parts[0] if len(parts) > 0 else "Unknown"
        common_name = parts[1] if len(parts) > 1 else "Unknown"

        return jsonify({
            "scientificName": scientific_name,
            "birdName": common_name,
            "confidence": float(best['confidence'])
        })
    finally:
        os.unlink(tmp_path)

if __name__ == "__main__":
    app.run(port=5000)
