package main.java.com.engagepoint.content_scheduler.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.io.FileInputStream;
import java.io.IOException;
import javax.swing.text.Document;
import com.google.firebase.database.*;
import com.google.firebase.cloud.FirestoreClient;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.engagepoint.content_scheduler.model.Post;
import org.instancio.Instancio;
import com.google.android.gms.tasks.Task;
import static org.assertj.core.api.Assertions.assertThat;

@Configuration
public class FirebaseManager {
    // Private account key
    @Value ("classpath:firebase/google-services.json")
    private Resource serviceAccount;

    // DB initialiser
    @Bean
    public FirebaseApp initializeFirebase() throws IOException {
        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount.getInputStream()))
                .setDatabaseUrl("db-url") // placeholder url
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.initializeApp(options);
        } else {
            return FirebaseApp.getInstance();
        }
    }
}
