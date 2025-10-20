package main.java.com.engagepoint.content_scheduler.model;

import java.util.Date;
import java.time.LocalDateTime;

public class Post {
    private String businessID;
    private String content;
    private String postDate;
    private String postTitle;
    private String postTag;
    private String postID;

    // Constructors
    public Post() {
    }

    public Post(String businessID, String content, datetime postDate, String postTitle, String postTag, String postID) {
        this.businessID = businessID;
        this.content = content;
        this.postDate = postDate;
        this.postTitle = postTitle;
        this.postTag = postTag;
        this.postID = postID;
    }

    // Getters and Setters
    public String getBusinessID() {
        return businessID;
    }

    public String getContent() {
        return content;
    }

    public String getPostDate() {
        return postDate;
    }

    public void setPostDate(datetime postDate) {
        this.postDate = postDate;
    }

    public String getPostTitle() {
        return postTitle;
    }

    public String getPostTag() {
        return postTag;
    }

    public String getPostID() {
        return postID;
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
                '}';
    }
}
