import requests

def moderate_image(image_url):
    """
    Analyzes an image URL and returns a moderation result.
    Returns:
        {
            "approved": True/False,
            "reason": <string explanation>
        }
    """

    #  Handle missing or invalid image URLs
    if not image_url or not isinstance(image_url, str) or image_url.strip() == "":
        return {
            "approved": False,
            "reason": "No valid image URL provided"
        }

    #  Simple keyword-based check (placeholder logic)
    unsafe_keywords = ["nsfw", "gore", "violence", "explicit"]
    url_lower = image_url.lower()
    flagged = any(keyword in url_lower for keyword in unsafe_keywords)

    if flagged:
        return {
            "approved": False,
            "reason": "Inappropriate or unsafe image detected"
        }

    #  (Optional) Placeholder for a real AI model or API
    # Example: call Google Cloud Vision, AWS Rekognition, or NSFW model
    # response = analyze_image_with_ai(image_url)
    # return response

    # 🔹 Default safe response
    return {
        "approved": True,
        "reason": "Image approved"
    }
