import os
import firebase_admin
from firebase_admin import credentials, firestore

# Build the absolute path to the Firebase credential file
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(
    BASE_DIR, "engagepoint-a2c47-firebase-adminsdk-fbsvc-1c1a597ea3.json")

# Initialize Firebase only once
if not firebase_admin._apps:
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

# Create a single Firestore client
db = firestore.client()


class ReviewModel:
    collection = db.collection("reviews")
    bUsers = db.collection("users")

    @staticmethod
    def create(data):
        ReviewModel.collection.add(data)

    @staticmethod
    def read_all(businessId):
        docs = ReviewModel.collection.where(
            "businessId", "==", businessId).stream()
        return [doc.to_dict() for doc in docs]

    @staticmethod
    def update(updated_review):
        target = ReviewModel.collection \
            .where("businessId", "==", updated_review["businessId"]) \
            .where("customerId", "==", updated_review["customerId"]) \
            .get()

        if target:
            doc = target[0]
            doc_ref = ReviewModel.collection.document(doc.id)
            doc_ref.update(updated_review)
            return "Updated"
        return None

    @staticmethod
    def delete(business_id, customer_id):
        target = ReviewModel.collection \
            .where("businessId", "==", business_id) \
            .where("customerId", "==", customer_id) \
            .get()

        if target:
            doc = target[0]
            doc_ref = ReviewModel.collection.document(doc.id)
            doc_ref.delete()
            return "Deleted"
        return None

    @staticmethod
    def auto_response(businessId):
        target_doc = ReviewModel.bUsers.document(businessId)

        if not target_doc:
            return False

        doc_dict = target_doc.get().to_dict()
        return doc_dict.get("auto_response", False)
