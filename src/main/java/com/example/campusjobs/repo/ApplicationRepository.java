package com.example.campusjobs.repo;

import com.example.campusjobs.model.Application;
import com.example.campusjobs.model.ApplicationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findByJobIdOrderByAppliedAtDesc(Long jobId);
    List<Application> findByJobIdAndStatus(Long jobId, ApplicationStatus status);
    List<Application> findByApplicantUsernameOrderByAppliedAtDesc(String applicantUsername);
    boolean existsByJobIdAndApplicantUsername(Long jobId, String applicantUsername);
}
