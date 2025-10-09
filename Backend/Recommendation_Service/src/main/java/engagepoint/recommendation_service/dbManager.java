package engagepoint.recommendation_service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;

import engagepoint.recommendation_service.models.Post;

import java.io.FileInputStream;
import java.io.IOException;

public class dbManager {
    final FirebaseDatabase firebaseDatabase;
    DatabaseReference ref;

    private static dbManager instance;
    private FirebaseApp firebaseApp;

    private dbManager() throws IOException {
        FileInputStream serviceAccount = new FileInputStream("EngagePoint_ITMDA_GroupS11\\Frontend\\flutter_app\\android\\app\\google-services.json");

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                .setDatabaseUrl("https://EngagePoint.firebaseio.com")
                .build();

        firebaseApp = FirebaseApp.initializeApp(options);
        firebaseDatabase = FirebaseDatabase.getInstance(firebaseApp);
        ref = firebaseDatabase.getReference("your_node_name");

        ref.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                Post post = dataSnapshot.getValue(Post.class);
                System.out.println(post);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                System.out.println("The read failed: " + databaseError.getCode());
            }
        });
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
