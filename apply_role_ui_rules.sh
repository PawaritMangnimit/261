#!/usr/bin/env bash
set -euo pipefail

echo "==> Ensure thymeleaf-extras-springsecurity6 is present"
if ! grep -q 'thymeleaf-extras-springsecurity6' pom.xml; then
  perl -0777 -pe 's|</dependencies>|  <dependency>\n      <groupId>org.thymeleaf.extras</groupId>\n      <artifactId>thymeleaf-extras-springsecurity6</artifactId>\n    </dependency>\n  </dependencies>|' -i pom.xml
  echo "   + added thymeleaf-extras-springsecurity6"
fi

echo "==> Update JobsController to expose alreadyApplied flag"
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

        String me = SecUtil.currentUsername();
        boolean alreadyApplied = (me != null) && applicationRepository.existsByJobIdAndApplicantUsername(id, me);
        model.addAttribute("alreadyApplied", alreadyApplied);

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

echo "==> Overwrite teacher controllers (remove CSV endpoint)"
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

echo "==> Update index.html navbar by role (hide teacher/student links accordingly)"
cat > src/main/resources/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>Campus Jobs</title></head>
<body>
  <div>
    <span sec:authorize="isAuthenticated()">
      เข้าสู่ระบบโดย: <b sec:authentication="name">user</b> |
      <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
        <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
        <button type="submit">ออกจากระบบ</button>
      </form>
    </span>
    <span sec:authorize="isAnonymous()">
      <a href="/login">เข้าสู่ระบบ</a>
    </span>
    <span sec:authorize="hasRole('TEACHER')"> | <a href="/teacher/jobs">พื้นที่อาจารย์</a></span>
    <span sec:authorize="hasRole('STUDENT')"> | <a href="/student/applications">ใบสมัครของฉัน</a></span>
  </div>

  <h2>ฟีดงานทั้งหมด</h2>
  <div th:if="${jobs != null and !jobs.isEmpty()}">
    <div th:each="job : ${jobs}" style="border:1px solid #ddd;padding:10px;margin:8px 0;">
      <h3 th:text="${job.title}">ชื่องาน</h3>
      <p th:text="${job.description}">รายละเอียดงาน</p>
      <a th:href="@{|/jobs/${job.id}|}">ดูรายละเอียด</a>
    </div>
  </div>
  <div th:if="${jobs == null or jobs.isEmpty()}">
    <p>ตอนนี้ยังไม่มีงานประกาศ</p>
  </div>
</body></html>
HTML

echo "==> Update job_detail.html (teacher cannot apply; student apply once)"
cat > src/main/resources/templates/job_detail.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>รายละเอียดงาน</title></head>
<body>
  <div>
    <span sec:authorize="isAuthenticated()">
      เข้าสู่ระบบโดย: <b sec:authentication="name">user</b> |
      <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
        <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
        <button type="submit">ออกจากระบบ</button>
      </form>
    </span>
    <span sec:authorize="isAnonymous()">
      <a href="/login">เข้าสู่ระบบ</a>
    </span>
    <span sec:authorize="hasRole('TEACHER')"> | <a href="/teacher/jobs">พื้นที่อาจารย์</a></span>
    <span sec:authorize="hasRole('STUDENT')"> | <a href="/student/applications">ใบสมัครของฉัน</a></span>
    | <a href="/">หน้าแรก</a>
  </div>

  <div th:if="${job != null}">
    <h2 th:text="${job.title}">title</h2>
    <p th:text="${job.description}">desc</p>
    <h3>สมัครเข้าร่วมงาน</h3>
    <p><b>คำถามจากอาจารย์:</b> <span th:text="${job.questionPrompt}">question</span></p>

    <!-- นักศึกษาเห็นฟอร์มเฉพาะเมื่อยังไม่เคยสมัคร -->
    <div sec:authorize="hasRole('STUDENT')">
      <div th:if="${alreadyApplied}">
        <p><b>คุณส่งใบสมัครแล้ว</b></p>
      </div>
      <form th:if="${!alreadyApplied}" method="post" th:action="@{|/jobs/${job.id}/apply|}" th:object="${_csrf}">
        <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
        <div><label>ชื่อ-นามสกุล</label><br/><input type="text" name="fullName" required style="width:420px"/></div>
        <div><label>รหัสนักศึกษา</label><br/><input type="text" name="studentId" required style="width:420px"/></div>
        <div><label>อีเมล</label><br/><input type="email" name="email" required style="width:420px"/></div>
        <div><label>โทรศัพท์</label><br/><input type="text" name="phone" required style="width:420px"/></div>
        <div><label>คำตอบ</label><br/><textarea name="answerText" required style="width:420px;height:120px"></textarea></div>
        <button type="submit">ส่งใบสมัคร</button>
      </form>
    </div>

    <!-- อาจารย์ไม่สามารถสมัคร -->
    <div sec:authorize="hasRole('TEACHER')">
      <p><i>บัญชีอาจารย์ไม่สามารถสมัครงานได้</i></p>
    </div>

    <!-- ผู้ใช้ไม่ล็อกอิน -->
    <div sec:authorize="isAnonymous()">
      <p>กรุณาเข้าสู่ระบบเพื่อสมัคร</p>
    </div>
  </div>
  <div th:if="${job == null}">
    <p>ไม่พบบันทึกงาน</p>
  </div>
</body></html>
HTML

echo "==> Update teacher_jobs.html (no Public/CSV links)"
cat > src/main/resources/templates/teacher_jobs.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>งานของฉัน</title></head>
<body>
  <div>
    <span>เข้าสู่ระบบโดย: <b sec:authentication="name">user</b></span>
    |
    <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
      <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
      <button type="submit">ออกจากระบบ</button>
    </form>
    | <a href="/">หน้าแรก</a>
  </div>

  <h2>งานของฉัน (อาจารย์)</h2>
  <p><a href="/teacher/jobs/new">+ สร้างงานใหม่</a></p>

  <table border="1" cellpadding="6" cellspacing="0">
    <thead><tr><th>ชื่อเรื่อง</th><th>คำถาม</th><th>จัดการ</th></tr></thead>
    <tbody>
      <tr th:each="j : ${jobs}">
        <td th:text="${j.title}">title</td>
        <td th:text="${j.questionPrompt}">question</td>
        <td><a th:href="@{|/teacher/jobs/${j.id}/applications|}">ดูผู้สมัคร</a></td>
      </tr>
    </tbody>
  </table>
</body></html>
HTML

echo "==> Update teacher_applications.html (remove CSV)"
cat > src/main/resources/templates/teacher_applications.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>ผู้สมัครงาน</title></head>
<body>
  <div>
    <span>เข้าสู่ระบบโดย: <b sec:authentication="name">user</b></span>
    |
    <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
      <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
      <button type="submit">ออกจากระบบ</button>
    </form>
    | <a th:href="@{|/teacher/jobs|}">ย้อนกลับ</a>
  </div>

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
</body></html>
HTML

echo "==> Update student_apps.html navbar by role"
cat > src/main/resources/templates/student_apps.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>ใบสมัครของฉัน</title></head>
<body>
  <div>
    <span sec:authorize="isAuthenticated()">
      เข้าสู่ระบบโดย: <b sec:authentication="name">user</b> |
      <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
        <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
        <button type="submit">ออกจากระบบ</button>
      </form>
    </span>
    <span sec:authorize="isAnonymous()">
      <a href="/login">เข้าสู่ระบบ</a>
    </span>
    <span sec:authorize="hasRole('TEACHER')"> | <a href="/teacher/jobs">พื้นที่อาจารย์</a></span>
    <span sec:authorize="hasRole('STUDENT')"> | <a href="/student/applications">ใบสมัครของฉัน</a></span>
    | <a href="/">หน้าแรก</a>
  </div>

  <h2>ใบสมัครของฉัน (นักศึกษา)</h2>
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

echo "==> Remove any old CSV template/link files if present (no-op if missing)"
# none to remove, links were only in templates/controllers

echo "==> Clean target for fresh build"
rm -rf target || true

echo "✅ Role/UI rules applied. Next: docker compose up --build"
