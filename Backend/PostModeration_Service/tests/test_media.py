import pytest
import requests

BASE_URL = "http://localhost:5000"

# -------------------------------
# Single image moderation test
# -------------------------------
@pytest.mark.parametrize("image_url,expected_approved", [
    ("http://example.com/safe_picture.jpg", True),
    ("http://example.com/nsfw_photo.jpg", False),
    ("http://example.com/violence_scene.png", False),
])
def test_single_image(image_url, expected_approved):
    data = {"image_url": image_url}
    response = requests.post(f"{BASE_URL}/moderate-image", json=data)
    result = response.json()
    assert result["approved"] == expected_approved

# -------------------------------
# Batch image moderation test
# -------------------------------
def test_batch_images():
    test_images = {
        "images": [
            {"image_id": "1", "image_url": "http://example.com/safe_picture.jpg"},
            {"image_id": "2", "image_url": "http://example.com/nsfw_photo.jpg"},
            {"image_id": "3", "image_url": "http://example.com/violence_scene.png"},
        ]
    }
    response = requests.post(f"{BASE_URL}/moderate-batch-images", json=test_images)
    results = response.json()

    # Assertions for each image
    assert results[0]["approved"] is True
    assert results[1]["approved"] is False
    assert results[2]["approved"] is False

    # Ensure each result contains the image_id
    assert all("image_id" in r for r in results)
