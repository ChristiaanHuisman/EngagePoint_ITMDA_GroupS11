package engagepoint.recommendation_service.models;

import java.util.List;

public class Post {
    public String business;
    public String title;
    List<String> category;

    public Post() {
        // Default constructor required for calls to DataSnapshot.getValue(Post.class)
    }

    public Post(String business, String title) {
        this.business = business;
        this.title = title;
    }

    public String getBusiness() {
        return business;
    }

    public String getTitle() {
        return title;
    }

    public void setBusiness(String business) {
        this.business = business;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public List<String> getCategory() {
        return category;
    }

    public void setCategory(List<String> category) {
        this.category = category;
    }

    @Override
    public String toString() {
        return "Post{" +
                "business='" + business + '\'' +
                ", title='" + title + '\'' +
                '}';
    }

    public boolean userInteraction(String username) {
        

        return true;
    }
}
