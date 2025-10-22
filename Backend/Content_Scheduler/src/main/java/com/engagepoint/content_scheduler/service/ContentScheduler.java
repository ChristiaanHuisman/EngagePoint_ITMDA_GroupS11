package main.java.com.engagepoint.content_scheduler.service;

import org.springframework.context.annotation.Configuration;
import com.engagepoint.content_scheduler.model.Post;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import java.util.concurrent.TimeUnit;
import java.text.SimpleDateFormat;
import java.util.Date;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@EnableScheduling
@Component
public class ContentScheduler {
    @Scheduled(cron = "0 0/30 * * * ?") // Every 30 minutes
    public void scheduleContentPosts() {
        // Logic to check for scheduled posts and publish them
        String currentDate = new SimpleDateFormat("yyyy-MM-dd 'at' HH:mm:ss z").format(new Date());

        try {
            List<Post> postsToPublish = getPosts(currentDate);

            for (Post post : postsToPublish) {
                if (!post.isPublished() && post.getPostDate().before(new Date())) {
                    // Publish the post
                    post.setPublished(true);
                    // Update the post in Firestore
                    FirestoreClient.getFirestore()
                        .collection("posts")
                        .document(post.getPostID())
                        .set(post);
                }
                
            } catch (Exception e) {
                    System.err.println("Error scheduling posts: " + e.getMessage());
            }
        }
    }

    public List<Post> getPosts(String date) throws ExecutionException, InterruptedException {
        List<Post> posts = new ArrayList<>();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd 'at' HH:mm:ss z");
        date parsedDate = sdf.parse(date);
        QuerySnapshot querySnapshot = FirestoreClient.getFirestore()
                .collection("posts")
                .whereLessThanOrEqualTo("postDate", parsedDate)
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
