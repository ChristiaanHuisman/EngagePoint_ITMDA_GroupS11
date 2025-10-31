package com.engagepoint.content_scheduler.controller;

import org.springframework.web.bind.annotation.*;
import com.engagepoint.content_scheduler.model.Post;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;
import com.google.cloud.firestore.QuerySnapshot;

@RestController
@RequestMapping("/api/posts")
public class PostController {
    @GetMapping
    public List<Post> getAllPosts() throws ExecutionException, InterruptedException {
        QuerySnapshot snapshot = FirestoreClient.getFirestore()
                .collection("posts")
                .get()
                .get();

        return snapshot.getDocuments().stream()
                .map(doc -> doc.toObject(Post.class))
                .collect(Collectors.toList());
    }

    @PostMapping
    public ResponseEntity<String> createPost(@RequestBody Post post) {
        try {
            FirestoreClient.getFirestore()
                .collection("posts")
                .document(post.getPostID())
                .set(post);
            return ResponseEntity.status(HttpStatus.CREATED).body("Post created successfully");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error creating post: " + e.getMessage());
        }
    }
}
