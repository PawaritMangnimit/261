#!/usr/bin/env bash
set -euo pipefail

echo "==> Ensure dependencies (thymeleaf + validation) and UTF-8 compiler"
if ! grep -q 'spring-boot-starter-thymeleaf' pom.xml; then
  perl -0777 -pe 's|</dependencies>|  <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-thymeleaf</artifactId>\n    </dependency>\n  </dependencies>|' -i pom.xml
  echo "  + added thymeleaf"
fi
if ! grep -q 'spring-boot-starter-validation' pom.xml; then
  perl -0777 -pe 's|</dependencies>|  <dependency>\n      <groupId>org.springframework.boot</groupId>\n      <artifactId>spring-boot-starter-validation</artifactId>\n    </dependency>\n  </dependencies>|' -i pom.xml
  echo "  + added validation"
fi
# UTF-8 + compiler plugin
if ! grep -q "<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>" pom.xml; then
  if grep -q "<properties>" pom.xml; then
    perl -0777 -pe 's|<properties>|<properties>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>|' -i pom.xml
  else
    perl -0777 -pe 's|</parent>|</parent>\n\n  <properties>\n    <java.version>17</java.version>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>\n  </properties>|' -i pom.xml
  fi
  echo "  + ensured UTF-8 properties"
fi
if ! grep -q "<artifactId>maven-compiler-plugin</artifactId>" pom.xml; then
  perl -0777 -pe 's|</plugins>|  <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-compiler-plugin</artifactId>\n        <version>3.11.0</version>\n        <configuration>\n          <source>17</source>\n          <target>17</target>\n          <encoding>UTF-8</encoding>\n        </configuration>\n      </plugin>\n    </plugins>|' -i pom.xml
  echo "  + added compiler plugin"
fi

echo "==> Write application.properties (DB, JPA)"
mkdir -p src/main/resources
cat > src/main/resources/application.properties <<'PROPS'
spring.application.name=campusjobs

spring.datasource.url=jdbc:postgresql://db:5432/campusjobs
spring.datasource.username=campus
spring.datasource.password=campus123

spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Thymeleaf defaults are fine; templates in src/main/resources/templates
PROPS

echo "==> Write SecurityConfig (ASCII only)"
mkdir -p src/main/java/com/example/campusjobs/config
cat > src/main/java/com/example/campusjobs/config/SecurityConfig.java <<'JAVA'
package com.example.campusjobs.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // Demo only. In production use BCrypt.
        return NoOpPasswordEncoder.getInstance();
    }

    @Bean
    public UserDetailsService users() {
        UserDetails teacher1 = User.withUsername("teacher1@uni.edu").password("1234").roles("TEACHER").build();
        UserDetails teacher2 = User.withUsername("teacher2@uni.edu").password("1234").roles("TEACHER").build();
        UserDetails student1 = User.withUsername("student1@uni.edu").password("1234").roles("STUDENT").build();
        UserDetails student2 = User.withUsername("student2@uni.edu").password("1234").roles("STUDENT").build();
        return new InMemoryUserDetailsManager(teacher1, teacher2, student1, student2);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                // public pages
                .requestMatchers("/", "/login", "/public/**", "/css/**").permitAll()
                // feature protection
                .requestMatchers("/teacher/**").hasRole("TEACHER")
                .requestMatchers("/student/**").hasRole("STUDENT")
                .requestMatchers("/jobs/*/apply").hasRole("STUDENT")
                .requestMatchers("/jobs/**").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login").permitAll()
                .defaultSuccessUrl("/", true)
            )
            .logout(logout -> logout.logoutSuccessUrl("/").permitAll())
            .csrf(Customizer.withDefaults());

        return http.build();
    }
}
JAVA

echo "==> Models"
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
    List<Application> findByApplicantUsernameOrderByAppliedAtDesc(String applicantUsername);
    boolean existsByJobIdAndApplicantUsername(Long jobId, String applicantUsername);
}
JAVA

echo "==> Utils"
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

# AuthController: /login
cat > src/main/java/com/example/campusjobs/controller/AuthController.java <<'JAVA'
package com.example.campusjobs.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AuthController {
    @GetMapping("/login")
    public String login() { return "login"; }
}
JAVA

# HomeController: index feed (public)
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

# JobsController: job detail + apply (student)
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

# TeacherJobController: create/list apps/approve/reject/export
cat > src/main/java/com/example/campusjobs/controller/TeacherJobController.java <<'JAVA'
package com.example.campusjobs.controller;

import com.example.campusjobs.model.*;
import com.example.campusjobs.repo.ApplicationRepository;
import com.example.campusjobs.repo.JobRepository;
import com.example.campusjobs.util.SecUtil;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

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

    @GetMapping("/jobs/{id}/approved.csv")
    public ResponseEntity<byte[]> exportApproved(@PathVariable Long id, RedirectAttributes ra) {
        var jobOpt = jobRepository.findById(id);
        if (jobOpt.isEmpty() || !jobOpt.get().getCreatorUsername().equals(SecUtil.currentUsername())) {
            byte[] body = "Forbidden".getBytes(StandardCharsets.UTF_8);
            return ResponseEntity.status(403).body(body);
        }
        List<Application> approved = applicationRepository.findByJobIdAndStatus(id, ApplicationStatus.APPROVED);
        String csv = buildCsv(approved);
        byte[] data = csv.getBytes(StandardCharsets.UTF_8);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=approved_job_"+id+".csv")
                .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
                .body(data);
    }

    private String buildCsv(List<Application> list) {
        String header = "Full Name,Student ID,Email,Phone,Answer,AppliedAt\n";
        String rows = list.stream().map(a ->
            quote(a.getFullName()) + "," +
            quote(a.getStudentId()) + "," +
            quote(a.getEmail()) + "," +
            quote(a.getPhone()) + "," +
            quote(a.getAnswerText()) + "," +
            quote(a.getAppliedAt().toString())
        ).collect(Collectors.joining("\n"));
        return header + rows + (rows.isEmpty() ? "" : "\n");
    }
    private String quote(String s) {
        if (s == null) return "";
        String x = s.replace("\"","\"\"");
        return "\"" + x + "\"";
    }
}
JAVA

# StudentController: my applications
cat > src/main/java/com/example/campusjobs/controller/StudentController.java <<'JAVA'
package com.example.campusjobs.controller;

import com.example.campusjobs.repo.ApplicationRepository;
import com.example.campusjobs.util.SecUtil;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/student")
public class StudentController {
    private final ApplicationRepository applicationRepository;

    public StudentController(ApplicationRepository applicationRepository) {
        this.applicationRepository = applicationRepository;
    }

    @GetMapping("/applications")
    public String myApplications(Model model) {
        String me = SecUtil.currentUsername();
        model.addAttribute("apps", applicationRepository.findByApplicantUsernameOrderByAppliedAtDesc(me));
        return "student_apps";
    }
}
JAVA

echo "==> Data seeder (seed jobs if empty)"
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

echo "==> Templates (Thymeleaf)"
mkdir -p src/main/resources/templates

# login.html
cat > src/main/resources/templates/login.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>เข้าสู่ระบบ</title></head>
<body>
  <h2>เข้าสู่ระบบ</h2>
  <form method="post" action="/login" th:object="${_csrf}">
    <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
    <div><label>Username</label><br/><input type="text" name="username" required></div>
    <div><label>Password</label><br/><input type="password" name="password" required></div>
    <button type="submit">Sign in</button>
  </form>
  <p>ตัวอย่าง: อาจารย์ teacher1@uni.edu / 1234 | นักศึกษา student1@uni.edu / 1234</p>
</body></html>
HTML

# index.html (feed)
cat > src/main/resources/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>Campus Jobs</title></head>
<body>
  <h2>ฟีดงานทั้งหมด</h2>
  <p><a href="/login">เข้าสู่ระบบ</a> | <a href="/teacher/jobs">พื้นที่อาจารย์</a> | <a href="/student/applications">ใบสมัครของฉัน</a></p>

  <div th:if="${jobs != null and !jobs.isEmpty()}">
    <div th:each="job : ${jobs}" style="border:1px solid #ddd;padding:10px;margin:8px 0;">
      <h3 th:text="${job.title}">ชื่องาน</h3>
      <p th:text="${job.description}">รายละเอียดงาน</p>
      <a th:href="@{|/jobs/${job.id}|}">ดูรายละเอียด / สมัคร</a>
    </div>
  </div>
  <div th:if="${jobs == null or jobs.isEmpty()}">
    <p>ตอนนี้ยังไม่มีงานประกาศ หากคุณเป็นอาจารย์ กรุณาเข้าสู่ระบบเพื่อเพิ่มงาน</p>
  </div>
</body></html>
HTML

# job_detail.html
cat > src/main/resources/templates/job_detail.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>รายละเอียดงาน</title></head>
<body>
  <div th:if="${job != null}">
    <h2 th:text="${job.title}">title</h2>
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
  <div th:if="${job == null}">
    <p>ไม่พบบันทึกงาน</p>
  </div>
  <p><a href="/">กลับหน้าแรก</a></p>
</body></html>
HTML

# teacher_jobs.html
cat > src/main/resources/templates/teacher_jobs.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>งานของฉัน</title></head>
<body>
  <h2>งานของฉัน (อาจารย์)</h2>
  <p><a href="/teacher/jobs/new">+ สร้างงานใหม่</a> | <a href="/">หน้าแรก</a></p>

  <table border="1" cellpadding="6" cellspacing="0">
    <thead><tr><th>ชื่อเรื่อง</th><th>คำถาม</th><th>จัดการ</th></tr></thead>
    <tbody>
    <tr th:each="j : ${jobs}">
      <td th:text="${j.title}">title</td>
      <td th:text="${j.questionPrompt}">question</td>
      <td>
        <a th:href="@{|/teacher/jobs/${j.id}/applications|}">ดูผู้สมัคร</a>
        &nbsp;|&nbsp;
        <a th:href="@{|/jobs/${j.id}|}">ดูหน้าแสดงงาน</a>
        &nbsp;|&nbsp;
        <a th:href="@{|/teacher/jobs/${j.id}/approved.csv|}">ดาวน์โหลดรายชื่อที่ผ่าน (CSV)</a>
      </td>
    </tr>
    </tbody>
  </table>
</body></html>
HTML

# teacher_job_new.html
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

# teacher_applications.html
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
        <th>ชื่อ - นามสกุล</th><th>รหัส นศ.</th><th>อีเมล</th><th>โทร</th>
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

  <p>
    <a th:href="@{|/teacher/jobs/${job.id}/approved.csv|}">ดาวน์โหลดรายชื่อที่ผ่าน (CSV)</a> |
    <a th:href="@{|/teacher/jobs|}">ย้อนกลับ</a>
  </p>
</body></html>
HTML

# student_apps.html
cat > src/main/resources/templates/student_apps.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>ใบสมัครของฉัน</title></head>
<body>
  <h2>ใบสมัครของฉัน (นักศึกษา)</h2>
  <p><a href="/">หน้าแรก</a></p>
  <table border="1" cellpadding="6" cellspacing="0">
    <thead><tr><th>ชื่องาน</th><th>ส่งเมื่อ</th><th>สถานะ</th><th>คำตอบ</th></tr></thead>
    <tbody>
      <tr th:each="a : ${apps}">
        <td th:text="${a.job.title}">job</td>
        <td th:text="${#temporals.format(a.appliedAt, 'yyyy-MM-dd HH:mm')}">date</td>
        <td th:text="${a.status}">status</td>
        <td th:text="${a.answerText}">answer</td>
      </tr>
    </tbody>
  </table>
</body></html>
HTML

echo "==> Cleanup stray/old files that may conflict"
rm -f src/main/java/com/example/campusjobs/HomeController.java 2>/dev/null || true

echo "==> Clean target for fresh build"
rm -rf target || true

echo "✅ Done. Next: docker compose up --build"
