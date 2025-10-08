#!/usr/bin/env bash
set -euo pipefail

# Job.java
cat > src/main/java/com/example/campusjobs/model/Job.java <<'JAVA'
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
JAVA

# ApplicationStatus.java
cat > src/main/java/com/example/campusjobs/model/ApplicationStatus.java <<'JAVA'
package com.example.campusjobs.model;
public enum ApplicationStatus { PENDING, APPROVED, REJECTED }
JAVA

# Application.java
cat > src/main/java/com/example/campusjobs/model/Application.java <<'JAVA'
package com.example.campusjobs.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "applications", uniqueConstraints = @UniqueConstraint(columnNames = {"job_id", "applicantUsername"}))
public class Application {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional=false, fetch = FetchType.LAZY)
    private Job job;

    @Column(nullable=false, length=200)
    private String applicantUsername;

    @Column(nullable=false, length=150) private String fullName;
    @Column(nullable=false, length=50)  private String studentId;
    @Column(nullable=false, length=80)  private String email;
    @Column(nullable=false, length=30)  private String phone;

    @Column(nullable=false, length=4000)
    private String answerText;

    @Enumerated(EnumType.STRING)
    @Column(nullable=false, length=20)
    private ApplicationStatus status = ApplicationStatus.PENDING;

    @Column(nullable=false)
    private Instant appliedAt = Instant.now();

    public Application() {}
    public Application(Job job, String applicantUsername, String fullName, String studentId, String email, String phone, String answerText) {
        this.job = job;
        this.applicantUsername = applicantUsername;
        this.fullName = fullName;
        this.studentId = studentId;
        this.email = email;
        this.phone = phone;
        this.answerText = answerText;
    }

    public Long getId() { return id; }
    public Job getJob() { return job; }
    public String getApplicantUsername() { return applicantUsername; }
    public String getFullName() { return fullName; }
    public String getStudentId() { return studentId; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getAnswerText() { return answerText; }
    public ApplicationStatus getStatus() { return status; }
    public Instant getAppliedAt() { return appliedAt; }

    public void setId(Long id) { this.id = id; }
    public void setJob(Job job) { this.job = job; }
    public void setApplicantUsername(String applicantUsername) { this.applicantUsername = applicantUsername; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public void setStudentId(String studentId) { this.studentId = studentId; }
    public void setEmail(String email) { this.email = email; }
    public void setPhone(String phone) { this.phone = phone; }
    public void setAnswerText(String answerText) { this.answerText = answerText; }
    public void setStatus(ApplicationStatus status) { this.status = status; }
    public void setAppliedAt(Instant appliedAt) { this.appliedAt = appliedAt; }
}
JAVA

echo "ASCII Java sources re-written. Now build again."
