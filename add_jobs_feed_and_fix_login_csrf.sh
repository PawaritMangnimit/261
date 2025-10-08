#!/usr/bin/env bash
set -euo pipefail

echo "==> 1) สร้าง Entity: Job"
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

    @Column(nullable=false)
    private Instant createdAt = Instant.now();

    public Job() {}
    public Job(String title, String description) {
        this.title = title;
        this.description = description;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public Instant getCreatedAt() { return createdAt; }

    public void setId(Long id) { this.id = id; }
    public void setTitle(String title) { this.title = title; }
    public void setDescription(String description) { this.description = description; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
JAVA

echo "==> 2) สร้าง Repository: JobRepository"
mkdir -p src/main/java/com/example/campusjobs/repo
cat > src/main/java/com/example/campusjobs/repo/JobRepository.java <<'JAVA'
package com.example.campusjobs.repo;

import com.example.campusjobs.model.Job;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JobRepository extends JpaRepository<Job, Long> {
}
JAVA

echo "==> 3) อัปเดต HomeController ให้ดึงฟีดงานมาแสดง"
mkdir -p src/main/java/com/example/campusjobs/controller
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

    // หน้า landing (public) + ฟีดงานทั้งหมด
    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("jobs", jobRepository.findAll());
        return "index";
    }

    // placeholder เพื่อทดสอบ role guard (ยังไม่ทำหน้า feature จริง)
    @GetMapping("/teacher")
    public String teacher() { return "teacher"; }

    @GetMapping("/student")
    public String student() { return "student"; }
}
JAVA

echo "==> 4) แก้ login.html ให้ส่ง CSRF token"
mkdir -p src/main/resources/templates
cat > src/main/resources/templates/login.html <<'HTML'
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>Sign in</title>
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <style>
    body { font-family: system-ui, sans-serif; background:#f3f4f6; margin:0; }
    .wrap { max-width:420px; margin:80px auto; background:#fff; padding:28px; border-radius:12px; box-shadow:0 6px 20px rgba(0,0,0,.06); }
    h1 { margin:0 0 16px 0; font-size:32px;}
    label { display:block; margin:12px 0 6px; }
    input { width:100%; padding:12px 14px; border:1px solid #d1d5db; border-radius:8px; outline:none; }
    button { width:100%; padding:12px 14px; margin-top:16px; border:0; border-radius:8px; background:#2563eb; color:#fff; font-size:16px; cursor:pointer;}
    .hint { margin-top:16px; color:#6b7280; font-size:14px; }
    code { background:#f3f4f6; padding:2px 6px; border-radius:6px; }
    .error { color:#b91c1c; margin-top:10px; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Please sign in</h1>
    <form method="post" action="/login" th:object="${_csrf}">
      <!-- CSRF สำคัญมาก -->
      <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
      <label>Username</label>
      <input type="text" name="username" required />
      <label>Password</label>
      <input type="password" name="password" required />
      <button type="submit">Sign in</button>
    </form>
    <div class="hint">
      อาจารย์: <code>teacher1@uni.edu</code> / <code>1234</code><br/>
      นักศึกษา: <code>student1@uni.edu</code> / <code>1234</code>
    </div>
    <div class="error">
      <script>
        if (new URLSearchParams(location.search).has('error')) {
          document.write('เข้าสู่ระบบไม่สำเร็จ ตรวจสอบชื่อผู้ใช้หรือรหัสผ่าน');
        }
      </script>
    </div>
  </div>
</body>
</html>
HTML

echo "==> 5) อัปเดต index.html ให้โชว์ฟีดงาน (ถ้ามี)"
cat > src/main/resources/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8" />
  <title>Campus Jobs – หน้าหลัก (Public)</title>
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
    code { background:#f1f5f9; padding:2px 6px; border-radius:6px; }
    .empty { padding:20px; color:#64748b; }
  </style>
</head>
<body>
  <header>
    <div>��� Campus Jobs</div>
    <nav class="row">
      <a class="btn btn-outline" href="/login">เข้าสู่ระบบ</a>
    </nav>
  </header>

  <div class="wrap">
    <h1>ฟีดงานทั้งหมด</h1>

    <!-- ถ้ามีงาน -->
    <div th:if="${jobs != null and !jobs.isEmpty()}">
      <div th:each="job : ${jobs}" class="card">
        <h3 th:text="${job.title}">ชื่องาน</h3>
        <p th:text="${job.description}">รายละเอียดงาน</p>
        <small th:text="${#temporals.format(job.createdAt, 'yyyy-MM-dd HH:mm')}">วันที่</small>
      </div>
    </div>

    <!-- ถ้ายังไม่มีงาน -->
    <div th:if="${jobs == null or jobs.isEmpty()}" class="card empty">
      ตอนนี้ยังไม่มีงานประกาศ หากคุณเป็นอาจารย์ กรุณาเข้าสู่ระบบเพื่อเพิ่มงาน
    </div>

    <div class="card">
      <h3>ลิงก์ทดสอบสิทธิ์</h3>
      <div class="row">
        <a class="btn btn-primary" href="/teacher">ไปหน้าอาจารย์ (ต้องล็อกอินเป็นอาจารย์)</a>
        <a class="btn btn-primary" href="/student">ไปหน้านักศึกษา (ต้องล็อกอินเป็นนักศึกษา)</a>
      </div>
    </div>
  </div>
</body>
</html>
HTML

echo "==> เสร็จแล้ว: เพิ่มฟีดงาน + แก้ CSRF login"
