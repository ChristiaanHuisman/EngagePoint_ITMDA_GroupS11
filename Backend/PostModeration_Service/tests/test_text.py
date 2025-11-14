import pytest
import requests

BASE_URL = "http://localhost:5000"

# -------------------------------
# Single post moderation test
# -------------------------------
@pytest.mark.parametrize("content,expected_offensive", [
    ("Shit", True),
    ("Hello world", False),
    ("Buy now! http://spam.com http://spam.com", False)
])
def test_single_post(content, expected_offensive):
    data = {"content": content}
    response = requests.post(f"{BASE_URL}/moderate-post", json=data)
    result = response.json()
    assert result["offensive"] == expected_offensive

# -------------------------------
# Batch post moderation test
# -------------------------------
def test_batch_posts():
    test_posts = {
        "posts": [
            {"post_id": "1", "content": "Hello world"},
            {"post_id": "2", "content": "Shit"},
            {"post_id": "3", "content": "Buy now! http://spam.com http://spam.com http://spam.com"}
        ]
    }
    response = requests.post(f"{BASE_URL}/moderate-batch", json=test_posts)
    results = response.json()

    # Assertions
    assert results[0]["offensive"] is False
    assert results[1]["offensive"] is True
    assert results[2]["spam"] is True

    # Ensure post_id is returned
    assert all("post_id" in r for r in results)

