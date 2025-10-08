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
