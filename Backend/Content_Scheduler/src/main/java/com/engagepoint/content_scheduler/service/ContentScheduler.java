package com.engagepoint.content_scheduler.service;

import com.engagepoint.content_scheduler.model.Post;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.DocumentSnapshot;

@EnableScheduling
@Component
public class ContentScheduler {
    @Scheduled(cron = "0 0/30 * * * ?") // Every 30 minutes
    public void scheduleContentPosts() {
        // Logic to check for scheduled posts and publish them
        try {
            List<Post> postsToPublish = getPosts();

            for (Post post : postsToPublish) {
                if (!post.getPublished() && post.getPostDate().isBefore(ZonedDateTime.now())) {
                    // Publish the post
                    post.setPublished(true);
                    // Update the post in Firestore
                    FirestoreClient.getFirestore()
                        .collection("posts")
                        .document(post.getPostID())
                        .set(post)
                        .get();
                }
                
            } 
        }   catch (Exception e) {
                System.err.println("Error scheduling posts: " + e.getMessage());
        }
    }

    public List<Post> getPosts() throws ExecutionException, InterruptedException {
        List<Post> posts = new ArrayList<>();
        
        QuerySnapshot querySnapshot = FirestoreClient.getFirestore()
                .collection("posts")
                .whereLessThanOrEqualTo("postDate", LocalDateTime.now())
                .whereEqualTo("published", false)
                .get()
                .get();
        
        for (DocumentSnapshot document : querySnapshot.getDocuments()) {
            Post post = document.toObject(Post.class);
            posts.add(post);
        }

        return posts;
    }
}
