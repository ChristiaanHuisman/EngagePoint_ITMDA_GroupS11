package engagepoint.recommendation_service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

import java.io.FileInputStream;
import java.io.IOException;

public class dbManager {
    private static dbManager instance;
    private FirebaseApp firebaseApp;

    private dbManager() throws IOException {
        FileInputStream serviceAccount = new FileInputStream("EngagePoint_ITMDA_GroupS11\\Frontend\\flutter_app\\android\\app\\google-services.json");

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .setDatabaseUrl("https://EngagePoint.firebaseio.com")
                .build();

        firebaseApp = FirebaseApp.initializeApp(options);
    }

    public static dbManager getInstance() throws IOException {
        if (instance == null) {
            instance = new dbManager();
        }
        return instance;
    }

    public FirebaseApp getFirebaseApp() {
        return firebaseApp;
    }
    
}
