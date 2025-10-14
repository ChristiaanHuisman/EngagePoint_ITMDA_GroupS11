package engagepoint.recommendation_service.models;

import java.util.List;

public class Post {
    public String author;
    public String title;
    List<String> category;

    public Post() {
        // Default constructor required for calls to DataSnapshot.getValue(Post.class)
    }

    public Post(String author, String title) {
        this.author = author;
        this.title = title;
    }

    public String getAuthor() {
        return Business.getBusinessName();
    }

    public String getTitle() {
        return title;
    }

    public void setAuthor(String author) {
        this.author = author;
        Business business = new Business();
        business.setBusinessName(author);
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
                "author='" + author + '\'' +
                ", title='" + title + '\'' +
                '}';
    }

    public boolean userInteraction(String username) {
        

        return true;
    }
}
