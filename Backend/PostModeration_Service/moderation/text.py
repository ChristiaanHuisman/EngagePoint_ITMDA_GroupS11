from better_profanity import profanity
from textblob import TextBlob
import re

# Load the default profanity words
profanity.load_censor_words()

def moderate_text(content):
    """
    Analyze a text post and return moderation results.
    Returns:
        {
            "approved": True/False,
            "reason": <string explanation>,
            "confidence_scores": {...}
        }
    """

    # Base result template
    result = {
        "approved": True,
        "reason": "Text approved",
        "confidence_scores": {}
    }

    # Handle empty text safely
    if not content or not content.strip():
        result["approved"] = False
        result["reason"] = "Empty text content"
        result["confidence_scores"]["offensive"] = 0.0
        result["confidence_scores"]["spam"] = 0.0
        return result

    # 🔹 Check for profanity
    if profanity.contains_profanity(content):
        result["approved"] = False
        result["reason"] = "Contains offensive language"
        result["confidence_scores"]["offensive"] = 0.9
        return result
    else:
        result["confidence_scores"]["offensive"] = 0.1

    # 🔹 Spam detection: repeated words or too many links
    words = content.lower().split()
    repeated_words = [w for w in set(words) if words.count(w) > 5]  # threshold example
    links = re.findall(r"http[s]?://", content)

    if repeated_words or len(links) > 2:
        result["approved"] = False
        result["reason"] = "Possible spam or link abuse detected"
        result["confidence_scores"]["spam"] = 0.9
        return result
    else:
        result["confidence_scores"]["spam"] = 0.1

    # 🔹 Sentiment analysis (detect extremely negative or harmful tone)
    sentiment = TextBlob(content).sentiment.polarity
    if sentiment < -0.7:
        result["approved"] = False
        result["reason"] = "Overly negative or harmful tone detected"
        result["confidence_scores"]["offensive"] = max(result["confidence_scores"]["offensive"], 0.8)
        return result

    # If all checks pass
    return result
