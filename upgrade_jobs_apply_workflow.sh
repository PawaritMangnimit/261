#!/usr/bin/env bash
set -euo pipefail

echo "==> Update Security: อนุญาตดูรายละเอียดงานแบบ public แต่การสมัครต้องเป็น STUDENT"
perl -0777 -pe 's|\.requestMatchers\("/teacher/\*\*"\)\.hasRole\("TEACHER"\)\s*\n\s*\.requestMatchers\("/student/\*\*"\)\.hasRole\("STUDENT"\)\s*\n\s*// �� action[^;]+;|.requestMatchers("/teacher/**").hasRole("TEACHER")\n                .requestMatchers("/student/**").hasRole("STUDENT")\n                .requestMatchers("/jobs/*/apply").hasRole("STUDENT")\n                .requestMatchers("/jobs/**").permitAll()\n                .anyRequest().authenticated();|s' -i src/main/java/com/example/campusjobs/config/SecurityConfig.java || true

echo "==> Model: Job (เพิ่ม creatorUsername, questionPrompt)"
mkdir -p src/main/java/com/example/campusjobs/model
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

    // ผู้สร้างงาน (อีเมลจาก Spring Security)
    @Column(nullable=false, length=200)
    private String creatorUsername;

    // คำถามที่อยากให้ผู้สมัครตอบ
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

echo "==> Model: Application + Status"
cat > src/main/java/com/example/campusjobs/model/ApplicationStatus.java <<'JAVA'
package com.example.campusjobs.model;
public enum ApplicationStatus { PENDING, APPROVED, REJECTED }
JAVA

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

    // ผู้สมัคร (อีเมล/username จาก Security)
    @Column(nullable=false, length=200)
    private String applicantUsername;

    // ข้อมูลส่วนตัวเบื้องต้น
    @Column(nullable=false, length=150) private String fullName;
    @Column(nullable=false, length=50)  private String studentId;
    @Column(nullable=false, length=80)  private String email;
    @Column(nullable=false, length=30)  private String phone;

    // คำตอบจากคำถามที่ job ตั้งไว้
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

echo "==> Repositories"
mkdir -p src/main/java/com/example/campusjobs/repo
cat > src/main/java/com/example/campusjobs/repo/JobRepository.java <<'JAVA'
package com.example.campusjobs.repo;

import com.example.campusjobs.model.Job;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findByCreatorUsernameOrderByCreatedAtDesc(String creatorUsername);
}
JAVA

cat > src/main/java/com/example/campusjobs/repo/ApplicationRepository.java <<'JAVA'
package com.example.campusjobs.repo;

import com.example.campusjobs.model.Application;
import com.example.campusjobs.model.ApplicationStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ApplicationRepository extends JpaRepository<Application, Long> {
    List<Application> findByJobIdOrderByAppliedAtDesc(Long jobId);
    List<Application> findByJobIdAndStatus(Long jobId, ApplicationStatus status);
    boolean existsByJobIdAndApplicantUsername(Long jobId, String applicantUsername);
}
JAVA

echo "==> Utils: ดึง username ปัจจุบัน"
mkdir -p src/main/java/com/example/campusjobs/util
cat > src/main/java/com/example/campusjobs/util/SecUtil.java <<'JAVA'
package com.example.campusjobs.util;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public class SecUtil {
    public static String currentUsername() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return (auth != null) ? auth.getName() : null;
    }
}
JAVA

echo "==> Controllers"
mkdir -p src/main/java/com/example/campusjobs/controller

# Home: แสดงฟีดงานทั้งหมด (public)
cat > src/main/java/com/example/campusjobs/controller/HomeController.java <<'JAVA'
package com.example.campusjobs.controller;

import com.example.campusjobs.repo.JobRepository;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {
    private final JobRepository jobRepository;

    public HomeController(JobRepository jobRepository) {
        this.jobRepository = jobRepository;
    }

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("jobs", jobRepository.findAll());
        return "index";
    }
}
JAVA

# สำหรับอาจารย์: สร้าง/ลิสต์/ดูผู้สมัคร/อนุมัติ
cat > src/main/java/com/example/campusjobs/controller/TeacherJobController.java <<'JAVA'
package com.example.campusjobs.controller;

import com.example.campusjobs.model.*;
import com.example.campusjobs.repo.ApplicationRepository;
import com.example.campusjobs.repo.JobRepository;
import com.example.campusjobs.util.SecUtil;
import jakarta.validation.constraints.NotBlank;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Optional;

@Controller
@Validated
@RequestMapping("/teacher")
public class TeacherJobController {

    private final JobRepository jobRepository;
    private final ApplicationRepository applicationRepository;

    public TeacherJobController(JobRepository jobRepository, ApplicationRepository applicationRepository) {
        this.jobRepository = jobRepository;
        this.applicationRepository = applicationRepository;
    }

    @GetMapping("/jobs")
    public String myJobs(Model model) {
        String me = SecUtil.currentUsername();
        model.addAttribute("jobs", jobRepository.findByCreatorUsernameOrderByCreatedAtDesc(me));
        return "teacher_jobs";
    }

    @GetMapping("/jobs/new")
    public String newJobForm() { return "teacher_job_new"; }

    @PostMapping("/jobs")
    public String createJob(@RequestParam @NotBlank String title,
                            @RequestParam @NotBlank String description,
                            @RequestParam @NotBlank String questionPrompt,
                            RedirectAttributes ra) {
        String me = SecUtil.currentUsername();
        Job job = new Job(title, description, me, questionPrompt);
        jobRepository.save(job);
        ra.addFlashAttribute("msg", "สร้างงานเรียบร้อย");
        return "redirect:/teacher/jobs";
    }

    @GetMapping("/jobs/{id}/applications")
    public String viewApplications(@PathVariable Long id, Model model, RedirectAttributes ra) {
        Optional<Job> jobOpt = jobRepository.findById(id);
        if (jobOpt.isEmpty() || !jobOpt.get().getCreatorUsername().equals(SecUtil.currentUsername())) {
            ra.addFlashAttribute("err", "ไม่มีสิทธิ์เข้าถึงงานนี้");
            return "redirect:/teacher/jobs";
        }
        model.addAttribute("job", jobOpt.get());
        model.addAttribute("apps", applicationRepository.findByJobIdOrderByAppliedAtDesc(id));
        return "teacher_applications";
    }

    @PostMapping("/applications/{appId}/approve")
    public String approve(@PathVariable Long appId, RedirectAttributes ra) {
        return updateStatus(appId, ApplicationStatus.APPROVED, ra);
    }

    @PostMapping("/applications/{appId}/reject")
    public String reject(@PathVariable Long appId, RedirectAttributes ra) {
        return updateStatus(appId, ApplicationStatus.REJECTED, ra);
    }

    private String updateStatus(Long appId, ApplicationStatus status, RedirectAttributes ra) {
        var appOpt = applicationRepository.findById(appId);
        if (appOpt.isEmpty()) {
            ra.addFlashAttribute("err", "ไม่พบใบสมัคร");
            return "redirect:/teacher/jobs";
        }
        var app = appOpt.get();
        var job = app.getJob();
        if (!job.getCreatorUsername().equals(SecUtil.currentUsername())) {
            ra.addFlashAttribute("err", "ไม่มีสิทธิ์ปรับสถานะงานนี้");
            return "redirect:/teacher/jobs";
        }
        app.setStatus(status);
        applicationRepository.save(app);
        ra.addFlashAttribute("msg", "อัปเดตสถานะเรียบร้อย");
        return "redirect:/teacher/jobs/" + job.getId() + "/applications";
    }
}
JAVA

# สำหรับนักศึกษา/รายละเอียดงาน + สมัคร
cat > src/main/java/com/example/campusjobs/controller/JobsController.java <<'JAVA'
package com.example.campusjobs.controller;

import com.example.campusjobs.model.Application;
import com.example.campusjobs.repo.ApplicationRepository;
import com.example.campusjobs.repo.JobRepository;
import com.example.campusjobs.util.SecUtil;
import jakarta.validation.constraints.NotBlank;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/jobs")
public class JobsController {

    private final JobRepository jobRepository;
    private final ApplicationRepository applicationRepository;

    public JobsController(JobRepository jobRepository, ApplicationRepository applicationRepository) {
        this.jobRepository = jobRepository;
        this.applicationRepository = applicationRepository;
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        var job = jobRepository.findById(id).orElse(null);
        model.addAttribute("job", job);
        return "job_detail";
    }

    @PostMapping("/{id}/apply")
    public String apply(@PathVariable Long id,
                        @RequestParam @NotBlank String fullName,
                        @RequestParam @NotBlank String studentId,
                        @RequestParam @NotBlank String email,
                        @RequestParam @NotBlank String phone,
                        @RequestParam @NotBlank String answerText,
                        RedirectAttributes ra) {

        var job = jobRepository.findById(id).orElse(null);
        if (job == null) {
            ra.addFlashAttribute("err", "ไม่พบบันทึกงาน");
            return "redirect:/";
        }
        String me = SecUtil.currentUsername();
        if (applicationRepository.existsByJobIdAndApplicantUsername(id, me)) {
            ra.addFlashAttribute("err", "คุณสมัครงานนี้แล้ว");
            return "redirect:/jobs/" + id;
        }
        var app = new Application(job, me, fullName, studentId, email, phone, answerText);
        applicationRepository.save(app);
        ra.addFlashAttribute("msg", "สมัครเรียบร้อย");
        return "redirect:/jobs/" + id;
    }
}
JAVA

echo "==> Templates"

mkdir -p src/main/resources/templates

# หน้า index: ฟีดงาน + ลิงก์ไปดูรายละเอียด
cat > src/main/resources/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8" />
  <title>Campus Jobs – ฟีดงาน (Public)</title>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <style>
    body { font-family: system-ui, sans-serif; margin:0; background:#f8fafc;}
    header { background:#0f172a; color:#fff; padding:16px 24px; display:flex; justify-content:space-between; align-items:center;}
    a.btn { display:inline-block; padding:10px 14px; border-radius:10px; text-decoration:none; }
    .btn-primary { background:#2563eb; color:#fff; }
    .btn-outline { border:1px solid #475569; color:#e2e8f0; }
    .wrap { max-width:960px; margin:32px auto; padding:0 16px; }
    .card { background:#fff; border:1px solid #e5e7eb; border-radius:14px; padding:24px; box-shadow:0 8px 24px rgba(2,6,23,.04); margin-bottom:14px;}
    h1 { margin:0 0 12px 0; font-size:28px;}
    p { color:#334155; }
    .row { display:flex; gap:12px; flex-wrap:wrap; margin-top:14px; }
    .empty { padding:20px; color:#64748b; }
  </style>
</head>
<body>
  <header>
    <div>��� Campus Jobs</div>
    <nav class="row">
      <a class="btn btn-outline" href="/login">เข้าสู่ระบบ</a>
      <a class="btn btn-outline" href="/teacher/jobs">พื้นที่อาจารย์</a>
    </nav>
  </header>

  <div class="wrap">
    <h1>ฟีดงานทั้งหมด</h1>

    <div th:if="${jobs != null and !jobs.isEmpty()}">
      <div th:each="job : ${jobs}" class="card">
        <h3 th:text="${job.title}">ชื่องาน</h3>
        <p th:text="${job.description}">รายละเอียดงาน</p>
        <div class="row">
          <a class="btn btn-primary" th:href="@{|/jobs/${job.id}|}">ดูรายละเอียด / สมัคร</a>
        </div>
      </div>
    </div>

    <div th:if="${jobs == null or jobs.isEmpty()}" class="card empty">
      ตอนนี้ยังไม่มีงานประกาศ หากคุณเป็นอาจารย์ กรุณาเข้าสู่ระบบเพื่อเพิ่มงาน
    </div>
  </div>
</body>
</html>
HTML

# ฟอร์มสร้างงาน (อาจารย์)
cat > src/main/resources/templates/teacher_job_new.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>สร้างงานใหม่</title></head>
<body>
  <h2>สร้างงานใหม่</h2>
  <form method="post" action="/teacher/jobs" th:object="${_csrf}">
    <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
    <div>
      <label>ชื่อเรื่อง</label><br/>
      <input type="text" name="title" required style="width:420px"/>
    </div>
    <div>
      <label>รายละเอียด</label><br/>
      <textarea name="description" required style="width:420px;height:120px"></textarea>
    </div>
    <div>
      <label>คำถามให้นักศึกษาตอบ</label><br/>
      <textarea name="questionPrompt" required style="width:420px;height:80px"></textarea>
    </div>
    <button type="submit">บันทึก</button>
  </form>
  <p><a href="/teacher/jobs">ย้อนกลับ</a></p>
</body></html>
HTML

# รายการงานของฉัน (อาจารย์)
cat > src/main/resources/templates/teacher_jobs.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>งานของฉัน</title></head>
<body>
  <h2>งานของฉัน</h2>
  <p th:if="${#httpServletRequest.getParameter('msg') != null}" th:text="${#httpServletRequest.getParameter('msg')}"></p>
  <p th:if="${#httpServletRequest.getParameter('err') != null}" th:text="${#httpServletRequest.getParameter('err')}"></p>

  <p><a href="/teacher/jobs/new">+ สร้างงานใหม่</a></p>

  <table border="1" cellpadding="6" cellspacing="0">
    <thead><tr><th>ชื่อเรื่อง</th><th>คำถาม</th><th>จัดการ</th></tr></thead>
    <tbody>
    <tr th:each="j : ${jobs}">
      <td th:text="${j.title}">title</td>
      <td th:text="${j.questionPrompt}">question</td>
      <td>
        <a th:href="@{|/teacher/jobs/${j.id}/applications|}">ดูผู้สมัคร</a>
      </td>
    </tr>
    </tbody>
  </table>

  <p><a href="/">กลับหน้าแรก</a></p>
</body></html>
HTML

# รายการใบสมัครของงานนั้น ๆ + ปุ่มผ่าน/ไม่ผ่าน
cat > src/main/resources/templates/teacher_applications.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>ผู้สมัครงาน</title></head>
<body>
  <h2>ผู้สมัคร: <span th:text="${job.title}">Job</span></h2>
  <p th:text="${job.description}">desc</p>
  <p><b>คำถาม:</b> <span th:text="${job.questionPrompt}">question</span></p>

  <table border="1" cellpadding="6" cellspacing="0">
    <thead>
      <tr>
        <th>ชื่อ - นามสกุล</th><th>รหัสนักศึกษา</th><th>อีเมล</th><th>โทร</th>
        <th>คำตอบ</th><th>สถานะ</th><th>จัดการ</th>
      </tr>
    </thead>
    <tbody>
      <tr th:each="a : ${apps}">
        <td th:text="${a.fullName}">name</td>
        <td th:text="${a.studentId}">sid</td>
        <td th:text="${a.email}">email</td>
        <td th:text="${a.phone}">phone</td>
        <td th:text="${a.answerText}">answer</td>
        <td th:text="${a.status}">PENDING</td>
        <td>
          <form method="post" th:action="@{|/teacher/applications/${a.id}/approve|}" th:object="${_csrf}" style="display:inline">
            <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
            <button type="submit">ผ่าน</button>
          </form>
          <form method="post" th:action="@{|/teacher/applications/${a.id}/reject|}" th:object="${_csrf}" style="display:inline">
            <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
            <button type="submit">ไม่ผ่าน</button>
          </form>
        </td>
      </tr>
    </tbody>
  </table>

  <h3>รายชื่อที่ผ่าน</h3>
  <ul>
    <li th:each="a : ${apps}" th:if="${a.status.name() == 'APPROVED'}"
        th:text="${a.fullName + ' (' + a.studentId + ')'}">pass</li>
  </ul>

  <p><a th:href="@{|/teacher/jobs|}">ย้อนกลับ</a></p>
</body></html>
HTML

# รายละเอียดงาน + ฟอร์มสมัคร (นักศึกษา)
cat > src/main/resources/templates/job_detail.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>รายละเอียดงาน</title></head>
<body>
  <h2 th:text="${job != null ? job.title : 'ไม่พบบันทึกงาน'}">title</h2>
  <div th:if="${job != null}">
    <p th:text="${job.description}">desc</p>
    <h3>สมัครเข้าร่วมงาน</h3>
    <p><b>คำถามจากอาจารย์:</b> <span th:text="${job.questionPrompt}">question</span></p>

    <form method="post" th:action="@{|/jobs/${job.id}/apply|}" th:object="${_csrf}">
      <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
      <div><label>ชื่อ-นามสกุล</label><br/><input type="text" name="fullName" required style="width:420px"/></div>
      <div><label>รหัสนักศึกษา</label><br/><input type="text" name="studentId" required style="width:420px"/></div>
      <div><label>อีเมล</label><br/><input type="email" name="email" required style="width:420px"/></div>
      <div><label>โทรศัพท์</label><br/><input type="text" name="phone" required style="width:420px"/></div>
      <div><label>คำตอบ</label><br/><textarea name="answerText" required style="width:420px;height:120px"></textarea></div>
      <button type="submit">ส่งใบสมัคร</button>
    </form>
  </div>
  <p><a href="/">กลับหน้าแรก</a></p>
</body></html>
HTML

echo "==> Seeder: เติมงานตัวอย่างถ้ายังไม่มี"
mkdir -p src/main/java/com/example/campusjobs/config
cat > src/main/java/com/example/campusjobs/config/DataSeeder.java <<'JAVA'
package com.example.campusjobs.config;

import com.example.campusjobs.model.Job;
import com.example.campusjobs.repo.JobRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DataSeeder {
    @Bean
    CommandLineRunner seedJobs(JobRepository repo) {
        return args -> {
            if (repo.count() == 0) {
                repo.save(new Job("Staff งานปฐมนิเทศ", "ช่วยต้อนรับน้องใหม่ ณ หอประชุม", "teacher1@uni.edu", "เหตุผลที่อยากเป็น staff คืออะไร?"));
                repo.save(new Job("จิตอาสา Big Cleaning Day", "ร่วมทำความสะอาดอาคารเรียน", "teacher2@uni.edu", "คุณสะดวกวันไหนบ้าง?"));
            }
        };
    }
}
JAVA

echo "==> ลบ controller ชั่วคราวที่ไม่ใช้แล้ว (ถ้ายังเหลือ)"
rm -f src/main/java/com/example/campusjobs/controller/teacher.java 2>/dev/null || true
rm -f src/main/java/com/example/campusjobs/HomeController.java 2>/dev/null || true

echo "==> เคลียร์ target ให้ build ใหม่"
rm -rf target || true

echo "✅ Upgrade complete. Next: docker compose up --build"
