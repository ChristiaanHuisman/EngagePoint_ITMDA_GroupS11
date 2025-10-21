package main.java.com.engagepoint.content_scheduler.service;

import org.springframework.stereotype.Service;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.Firestore;
import com.engagepoint.content_scheduler.service.FirebaseManager;

@Service
public class FirestoreService {
    private final FirebaseManager firebaseManager;

    public FirestoreService(FirebaseManager firebaseManager) {
        this.firebaseManager = firebaseManager;
    }

    public <T> T getDocumentById(String collectionName, String documentId, Class<T> clazz) {
        ApiFuture<DocumentSnapshot> future = FirestoreClient.getFirestore()
                .collection("posts")
                .document(postID)
                .get();
        DocumentSnapshot document = future.get();
        if (document.exists()) {
            return document.toObject(clazz);
        } else {
            return null;
        }
    }
}
