package com.engagepoint.content_scheduler.service;

import com.engagepoint.content_scheduler.model.Post;

import java.time.ZonedDateTime;
import java.util.List;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;

@EnableScheduling
@Component
public class ContentScheduler {
    @Scheduled(cron = "0 0/1 * * * ?") // Every 30 minutes, adjusted to a minute for testing
    public void scheduleContentPosts() {
        // Logic to check for scheduled posts and publish them
        try {
            Firestore db = FirestoreClient.getFirestore();

            QuerySnapshot querySnapshot = db.collection("posts")
                .whereEqualTo("published", false)
                .get()
                .get();

            List<QueryDocumentSnapshot> documents = querySnapshot.getDocuments();

            for (QueryDocumentSnapshot document : documents) {
                Post post = document.toObject(Post.class);

                // Skip posts with no postDate (createdAt) set
                if (post.getCreatedAt() == null) {
                    System.out.println("Skipping post " + document.getId() + " (no postDate set)");
                    continue;
                }

                ZonedDateTime postDateTime = post.getCreatedAt().toDate()
                    .toInstant()
                    .atZone(java.time.ZoneId.systemDefault());

                if (!post.getPublished() && postDateTime.isBefore(ZonedDateTime.now())) {
                    // Update the post in Firestore
                    try {
                        db.collection("posts").document(document.getId())
                            .update("published", true)
                            .get();
                        System.out.println("Updated " + document.getId());
                    } catch (Exception ex) {
                        System.err.println("Update failed for " + document.getId());
                        ex.printStackTrace();
                    }
                    
                    System.out.println("Published post: " + post.getPostID());
                }
                
            }
            
            System.out.println("Checked " + documents.size() + " posts at " + ZonedDateTime.now());

        }   catch (Exception e) {
                System.err.println("Error scheduling posts: " + e.getMessage());
                e.printStackTrace();
        }
    }
}
