package com.engagepoint.content_scheduler.model;

import com.google.cloud.Timestamp;

public class Post {
    private String businessID;
    private String content;
    private Timestamp createdAt;
    private String postTitle;
    private String postTag;
    private String postID;
    private boolean published;

    // Constructors
    public Post() {
    }

    public Post(String businessID, String content, Timestamp createdAt, String postTitle, String postTag, String postID, boolean published) {
        this.businessID = businessID;
        this.content = content;
        this.createdAt = createdAt;
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

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
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

    public void setPublished(boolean published) {
        this.published = published;
    }

    // toString method
    @Override
    public String toString() {
        return "Post{" +
                "businessID='" + businessID + '\'' +
                ", content='" + content + '\'' +
                ", postDate=" + createdAt +
                ", postTitle='" + postTitle + '\'' +
                ", postTag='" + postTag + '\'' +
                ", postID='" + postID + '\'' +
                ", published='" + published + '\'' +
                '}';
    }
}
