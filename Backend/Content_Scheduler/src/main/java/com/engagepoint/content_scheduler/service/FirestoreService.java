package com.engagepoint.content_scheduler.service;

import com.google.cloud.firestore.DocumentChange;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

@Service
public class FirestoreService {
    private final FirebaseApp firebaseApp;
    @Value ("classpath:firebase/google-services.json")
    private Resource serviceAccount;

   @Autowired
    public FirestoreService(FirebaseApp firebaseApp) {
        this.firebaseApp = firebaseApp;
    }

    @PostConstruct
    public void listenForChanges() {
        Firestore db = FirestoreClient.getFirestore(firebaseApp);

        db.collection("posts").addSnapshotListener((snapshots, e) -> {
            if (e != null) {
                System.err.println("Listen failed: " + e);
                return;
            }

            if (snapshots == null) return;

            for (DocumentChange dc : snapshots.getDocumentChanges()) {
                switch (dc.getType()) {
                    case ADDED -> System.out.println("New post: " + dc.getDocument().getData());
                    case MODIFIED -> System.out.println("Modified post: " + dc.getDocument().getData());
                    case REMOVED -> System.out.println("Removed post: " + dc.getDocument().getData());
                }
            }
        });
    }
}
