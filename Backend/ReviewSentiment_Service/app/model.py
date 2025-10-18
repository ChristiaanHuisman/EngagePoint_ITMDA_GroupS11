import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.Certificate("Backend/ReviewSentiment_Service/app/engagepoint-a2c47-firebase-adminsdk-fbsvc-1c1a597ea3.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

class ReviewModel:
    collection = firestore.client().collection("reviews")

    @staticmethod
    def create(data):
        ReviewModel.collection.add(data)

    @staticmethod
    def read_all(businessId):
        return [doc.to_dict() for doc in ReviewModel.collection.stream() if doc.to_dict()["businessId"] == businessId]
        
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