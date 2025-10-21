package main.java.com.engagepoint.content_scheduler.model;

import java.util.Date;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Document(collection = "posts")
public class Post {
    private String businessID;
    private String content;
    private String postDate;
    private String postTitle;
    private String postTag;
    private String postID;
    private boolean published;

    // Constructors
    public Post() {
    }

    public Post(String businessID, String content, String postDate, String postTitle, String postTag, String postID, boolean published) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd 'at' HH:mm:ss z");
        LocalDateTime dateTime = LocalDateTime.parse(postDate, formatter);

        this.businessID = businessID;
        this.content = content;
        this.postDate = postDate;
        this.postTitle = postTitle;
        this.postTag = postTag;
        this.postID = postID;
        this.published = published;
    }

    // Getters and Setters
    public String getBusinessID() {
        return businessID;
    }

    public void setBusinessID(String businessID) {
        this.businessID = businessID;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getPostDate() {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd 'at' HH:mm:ss z");
        LocalDateTime dateTime = LocalDateTime.parse(this.postDate, formatter);

        return postDate;
    }

    public void setPostDate(String postDate) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd 'at' HH:mm:ss z");
        LocalDateTime dateTime = LocalDateTime.parse(postDate, formatter);

        this.postDate = postDate;
    }

    public String getPostTitle() {
        return postTitle;
    }

    public void setPostTitle(String postTitle) {
        this.postTitle = postTitle;
    }

    public String getPostTag() {
        return postTag;
    }

    public void setPostTag(String postTag) {
        this.postTag = postTag;
    }

    public String getPostID() {
        return postID;
    }

    public void setPostID(String postID) {
        this.postID = postID;
    }

    public boolean getPublished() {
        return published;
    }

    public void setPublished(boolean Published) {
        this.published = published;
    }

    // toString method
    @Override
    public String toString() {
        return "Post{" +
                "businessID='" + businessID + '\'' +
                ", content='" + content + '\'' +
                ", postDate=" + postDate +
                ", postTitle='" + postTitle + '\'' +
                ", postTag='" + postTag + '\'' +
                ", postID='" + postID + '\'' +
                ", published='" + published + '\'' +
                '}';
    }
}
