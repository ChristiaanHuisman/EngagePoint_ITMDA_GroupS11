from flask import Flask, request, jsonify
from better_profanity import profanity
import datetime
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer
from model import ReviewModel

nltk.download('vader_lexicon')

def censor_text(text):
    words = text.split()
    censored_words = []
    for i in words:
        if profanity.contains_profanity(i):
            if len(i) > 2:
                censored_words.append(i[0] + '*' * (len(i) - 2) + i[-1])
            elif len(i) == 2:
                censored_words.append(i[0] + '*')
            else:
                censored_words.append(i)
        else:
            censored_words.append(i)
    return ' '.join(censored_words)

sentiment = SentimentIntensityAnalyzer()
def get_review_sentiment(text):
    score = sentiment.polarity_scores(text)['compound']
    if score >= 0.05:
        return 'Positive'
    elif score < -0.05:
        return 'Negative'
    else:
        return 'Neutral'

def get_timestamp():
    stamp = datetime.datetime.now()
    stamp = stamp.strftime("%Y-%m-%d %H:%M:%S")
    return stamp

def get_sentiment_response(sentiment):
    if sentiment.lower() == "positive":
        return "Thanks for your positive feedback! 😊"
    elif sentiment.lower() == "negative":
        return "We're sorry to hear that. We'll try to improve. 😔"
    elif sentiment.lower() == "neutral":
        return "Thanks for your feedback! We'll keep working on it. 🙂"
    else:
        return "Thank you for your input!"

app = Flask(__name__)

@app.route('/reviews', methods=["POST"])
def add_or_update_review():
    data = request.json
    if not data:
        return jsonify({"message": "Invalid request"}), 400

    business_id = data.get("businessId")
    customer_id = data.get("customerId")
    rating = data.get("rating")
    comment = data.get("comment", "")

    if not business_id or not customer_id or rating is None:
        return jsonify({"message": "Missing required fields"}), 400

    if comment.strip():
        sentiment_value = get_review_sentiment(comment)
        censored_review_text = censor_text(comment)
    else:
        sentiment_value = "Neutral"
        censored_review_text = ""

    response = get_sentiment_response(sentiment_value)
    stamp = get_timestamp()

    review = {
        "customerId": customer_id,
        "businessId": business_id,
        "comment": censored_review_text,
        "rating": rating,
        "createdAt": stamp,
        "response": response,
        "sentiment": sentiment_value.lower()
    }

    updated = ReviewModel.update(review)
    if updated:
        return jsonify({"message": "Review updated successfully"}), 200

    ReviewModel.create(review)
    return jsonify({"message": "Review created successfully"}), 201

@app.route('/reviews/<businessId>', methods=["GET"])
def read_all_reviews(businessId):
    reviews = ReviewModel.read_all(businessId)
    return jsonify(reviews), 200

@app.route('/reviews', methods=["DELETE"])
def delete_review():
    data = request.json
    if data:
        if data.get("businessId") and data.get("customerId"):
            deleted = ReviewModel.delete(data["businessId"], data["customerId"])
            if deleted:
                return jsonify({"message": "Review deleted successfully"}), 200
            return jsonify({"message": "No matching review found"}), 404
        return jsonify({"message": "Invalid request"}), 400
    return jsonify({"message": "Invalid request"}), 400

@app.route('/reviews/analytics/<businessId>', methods = ["GET"])
def getReviewSentimentStats(businessId):
    reviews = ReviewModel.read_all(businessId)
    positive = 0
    negative = 0
    neutral = 0
    for i in reviews:
        sentiment = i.get("sentiment")
        if sentiment.lower() == "positive":
            positive += 1
        elif sentiment.lower() == "negative":
            negative += 1
        elif sentiment.lower() == "neutral":
            neutral += 1
    return jsonify({"positive": positive, "negative": negative, "neutral": neutral}), 200            
            
    
if __name__ == "__main__":
    app.run(host="192.168.8.131")