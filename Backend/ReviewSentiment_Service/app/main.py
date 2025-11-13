from flask import Flask, request, jsonify
from better_profanity import profanity
import datetime
import nltk
import random
from nltk.sentiment import SentimentIntensityAnalyzer
from model import ReviewModel
import os


nltk.download('vader_lexicon')

profanity.load_censor_words()


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
        return 'positive'
    elif score < -0.05:
        return 'negative'
    else:
        return 'neutral'


def get_timestamp():
    return datetime.datetime.now()


good = ["Thank you so much for your kind words! We're thrilled you had a great experience and look forward to serving you again. 😊",
        "We really appreciate your feedback! Your support motivates us to keep improving and providing the best service possible. 🙌",
        "Thank you for your positive review! We're delighted to know you enjoyed your experience with us. We hope to see you again soon!",
        "Thanks for your positive feedback! 😊"]
bad = ["We're really sorry to hear about your experience. Your feedback is important, and we'll do our best to improve. Please reach out so we can make things right. 😔",
       "We apologize for not meeting your expectations. We take your feedback seriously and will work to ensure a better experience next time.",
       "Thank you for letting us know about this issue. We're committed to improving and hope to provide a much better experience in the future.",
       "We're sorry to hear that. We'll try to improve. 😔"]


def get_sentiment_response(sentiment):
    if sentiment == "positive":
        return random.choice(good)
    elif sentiment == "negative":
        return random.choice(bad)
    elif sentiment == "neutral":
        return "Thanks for your feedback! We'll keep working on it. 🙂"
    else:
        return "Thank you for your input!"


app = Flask(__name__)


@app.route('/reviews', methods=["POST"])
def add_or_update_review():
    # Gets request from flutter app containing customerId, businessId, rating, and comment
    data = request.json
    if not data:
        return jsonify({"message": "Invalid request"}), 400

    business_id = data.get("businessId")
    customer_id = data.get("customerId")
    rating = data.get("rating")
    comment = data.get("comment", "")

    # Checking if business_id, customer_id, and rating have values
    if not business_id or not customer_id or rating is None:
        return jsonify({"message": "Missing required fields"}), 400

    if comment.strip():  # Checks if there is a comment before performing any operations
        sentiment_value = get_review_sentiment(comment)
        censored_review_text = censor_text(comment)
    else:
        sentiment_value = "neutral"
        censored_review_text = ""

    stamp = get_timestamp()
    # Add an if statement here to get response if required, based on the request
    auto_response = ReviewModel.auto_response(business_id)
    auto_response = ReviewModel.auto_response(business_id)
    review = {
        "customerId": customer_id,
        "businessId": business_id,
        "comment": censored_review_text,
        "rating": rating,
        "createdAt": stamp,
        "sentiment": sentiment_value
    }
    if auto_response:
        review["response"] = get_sentiment_response(sentiment_value)

    updated = ReviewModel.update(review)
    if updated:  # This will only be True if the record already existed in the firebase database
        return jsonify({"message": "Review updated successfully"}), 200

    ReviewModel.create(review)
    return jsonify({"message": "Review created successfully"}), 201


@app.route('/reviews/<businessId>', methods=["GET"])
# Reads all reviews related to businessId from the firebase database
def read_all_reviews(businessId):
    reviews = ReviewModel.read_all(businessId)
    return jsonify(reviews), 200


@app.route('/reviews', methods=["DELETE"])
def delete_review():
    data = request.json  # Gets request from flutter app containing customerId and businessId
    if data.get("businessId") and data.get("customerId"):
        deleted = ReviewModel.delete(data["businessId"], data["customerId"])
        if deleted:
            return jsonify({"message": "Review deleted successfully"}), 200
        return jsonify({"message": "No matching review found"}), 404
    return jsonify({"message": "Invalid request"}), 400


@app.route('/reviews/analytics/<businessId>', methods=["GET"])
def getReviewSentimentStats(businessId):
    # Reads all reviews related to businessId from the firebase database
    reviews = ReviewModel.read_all(businessId)
    positive = 0
    negative = 0
    neutral = 0
    for i in reviews:
        sentiment = i.get("sentiment")
        if sentiment == "positive":
            positive += 1
        elif sentiment == "negative":
            negative += 1
        elif sentiment == "neutral":
            neutral += 1
    return jsonify({"positive": positive, "negative": negative, "neutral": neutral}), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
