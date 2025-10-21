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

@Configuration
@EnableScheduling
@Component
public class ContentScheduler {
    // called from event listener
    public void scheduleContentTask() {
        Post post = new Post();
        // Logic to schedule content posting
        
        // Check if the 'createdAt' timestamp is older than 15 minutes
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd 'at' HH:mm:ss z");
        post.getPostDate();
        Date now = new Date();
        long diffInMillies = now.getTime() - post.getPostDate().getTime();
        long diffInMinutes = TimeUnit.MINUTES.convert(diffInMillies, TimeUnit.MILLISECONDS);
        if ((diffInMinutes >= 15) && (!post.getPublished())) {
            // Logic to post content
            System.out.println("Posting content: " + post.getContent());
            post.setPublished(true);
        } else {
            System.out.println("Post is not old enough to be posted yet.");
        }
    }
}
