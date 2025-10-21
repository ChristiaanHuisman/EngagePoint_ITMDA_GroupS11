package main.java.com.engagepoint.content_scheduler.service;

import org.springframework.stereotype.Service;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.Firestore;
import com.engagepoint.content_scheduler.service.FirebaseManager;

@Service
public class FirestoreService {
    private FirebaseApp firebaseApp;

    @PostConstruct
    public void listenForChanges() {
        Firestore db = FirestoreClient.getFirestore(FirebaseManager.initializeFirebase());
        
        db.collection("posts").addSnapshotListener((snapshots, e) -> {
            if (e != null) {
                System.err.println("Listen failed: " + e);
                return;
            }

            for (DocumentChange dc : snapshots.getDocumentChanges()) {
                switch (dc.getType()) {
                    case ADDED:
                        System.out.println("New post: " + dc.getDocument().getData());
                        break;
                    case MODIFIED:
                        System.out.println("Modified post: " + dc.getDocument().getData());
                        break;
                    case REMOVED:
                        System.out.println("Removed post: " + dc.getDocument().getData());
                        break;
                }
            }
        });
    }
}
