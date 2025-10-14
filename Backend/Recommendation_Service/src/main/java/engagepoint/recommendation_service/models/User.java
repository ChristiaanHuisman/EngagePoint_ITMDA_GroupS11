package engagepoint.recommendation_service.models;

import java.util.ArrayList;
import java.util.List;

public class User {
    public String username;
    public String email;
    List<Post> preferredCategories;

    public User() {
        // Default constructor required for calls to DataSnapshot.getValue(User.class)
    }

    public User(String name, String email) {
        this.username = name;
        this.email = email;
        this.preferredCategories = new ArrayList<>();
    }

    public String getUsername() {
        return username;
    }

    public String getEmail() {
        return email;
    }

    public void setUsername(String name) {
        this.username = name;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public void addPreferredCategory(Post category) {
        this.preferredCategories.add(category);
    }

    public List<Post> getPreferredCategories() {
        return preferredCategories;
    }

    @Override
    public String toString() {
        return "User{" +
                "name='" + username + '\'' +
                ", email='" + email + '\'' +
                '}';
    }
}