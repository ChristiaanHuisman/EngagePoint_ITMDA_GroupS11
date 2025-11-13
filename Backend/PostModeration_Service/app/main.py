import sys
import os
from functools import wraps
from flask import Flask, request, jsonify
import firebase_admin
from firebase_admin import credentials, auth

# Add parent directory to Python path so 'moderation' can be found
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from moderation.text import moderate_text
from moderation.media import moderate_image

app = Flask(__name__)

# Firebase Admin Initialization
cred = credentials.Certificate(os.path.join(os.path.dirname(__file__), "..", "serviceAccountKey.json"))
firebase_admin.initialize_app(cred)

# Firebase Token Verification Decorator
def verify_firebase_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get("Authorization")

        if not auth_header:
            return jsonify({"error": "Missing Authorization header"}), 401

        # Extract token
        token = None
        if auth_header.startswith("Bearer "):
            token = auth_header.split("Bearer ")[1]
        else:
            token = auth_header

        try:
            decoded_token = auth.verify_id_token(token)
            request.user = decoded_token  # you can use this to identify the user if needed
        except Exception as e:
            return jsonify({"error": "Invalid or expired token", "details": str(e)}), 401

        return f(*args, **kwargs)
    return decorated_function

# Health Check
@app.route("/health")
def health():
    return jsonify({"status": "running"})

# Single Post (Text) Moderation
@app.route("/moderate-post", methods=["POST"])
@verify_firebase_token
def moderate_post():
    data = request.get_json()
    content = data.get("content", "")
    result = moderate_text(content)

    response = {
        "approved": result.get("approved"),
        "reason": result.get("reason"),
        "confidence_scores": result.get("confidence_scores", {})
    }
    return jsonify(response)

# Single Image Moderation
@app.route("/moderate-image", methods=["POST"])
@verify_firebase_token
def moderate_image_route():
    data = request.get_json()
    image_url = data.get("image_url", "")
    result = moderate_image(image_url)

    response = {
        "approved": result.get("approved"),
        "reason": result.get("reason")
    }
    return jsonify(response)

# Run Flask App
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
