package com.engagepoint.content_scheduler.service;


import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import java.io.IOException;

@Configuration
public class FirebaseManager {
    @Value("classpath:firebase/engagepoint-a2c47-firebase-adminsdk-fbsvc-e9a19fca1e.json")
    private Resource serviceAccount;

    @Bean
    public FirebaseApp initializeFirebase() throws IOException {
        GoogleCredentials fromStream = GoogleCredentials.fromStream(serviceAccount.getInputStream());
        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(fromStream)
                .setDatabaseUrl("https://engagepoint-a2c47-default-rtdb.firebaseio.com")
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.initializeApp(options);
        }
        return FirebaseApp.getInstance();
    }
}