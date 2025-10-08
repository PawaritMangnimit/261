package com.example.campusjobs.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "jobs")
public class Job {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable=false, length=200)
    private String title;

    @Column(nullable=false, length=4000)
    private String description;

    @Column(nullable=false, length=200)
    private String creatorUsername;

    @Column(nullable=false, length=1000)
    private String questionPrompt;

    @Column(nullable=false)
    private Instant createdAt = Instant.now();

    public Job() {}
    public Job(String title, String description, String creatorUsername, String questionPrompt) {
        this.title = title;
        this.description = description;
        this.creatorUsername = creatorUsername;
        this.questionPrompt = questionPrompt;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public String getCreatorUsername() { return creatorUsername; }
    public String getQuestionPrompt() { return questionPrompt; }
    public Instant getCreatedAt() { return createdAt; }

    public void setId(Long id) { this.id = id; }
    public void setTitle(String title) { this.title = title; }
    public void setDescription(String description) { this.description = description; }
    public void setCreatorUsername(String creatorUsername) { this.creatorUsername = creatorUsername; }
    public void setQuestionPrompt(String questionPrompt) { this.questionPrompt = questionPrompt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
