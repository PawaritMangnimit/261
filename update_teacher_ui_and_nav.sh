#!/usr/bin/env bash
set -euo pipefail

echo "==> 1) เพิ่มไลบรารี thymeleaf-extras-springsecurity6 (ถ้ายังไม่มี)"
if ! grep -q 'thymeleaf-extras-springsecurity6' pom.xml; then
  perl -0777 -pe 's|</dependencies>|  <dependency>\n      <groupId>org.thymeleaf.extras</groupId>\n      <artifactId>thymeleaf-extras-springsecurity6</artifactId>\n    </dependency>\n  </dependencies>|' -i pom.xml
  echo "   + added thymeleaf-extras-springsecurity6"
fi

echo "==> 2) อัปเดต index.html ให้โชว์ชื่อผู้ใช้และปุ่มออกจากระบบเมื่อ login แล้ว"
cat > src/main/resources/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="th" xmlns:sec="http://www.thymeleaf.org/extras/spring-security">
<head><meta charset="UTF-8"><title>Campus Jobs</title></head>
<body>
  <div>
    <span sec:authorize="isAuthenticated()">
      เข้าสู่ระบบโดย: <b sec:authentication="name">user</b>
      |
      <form method="post" action="/logout" th:object="${_csrf}" style="display:inline">
        <input type="hidden" th:name="*{parameterName}" th:value="*{token}" />
        <button type="submit">ออกจากระบบ</button>
      </form>
    </span>
    <span sec:authorize="isAnonymous()">
      <a href="/login">เข้าสู่ระบบ</a>
    </span>
    | <a href="/teacher/jobs">พื้นที่อาจารย์</a>
    | <a href="/student/applications">ใบสมัครของฉัน</a>
  </div>

  <h2>ฟีดงานทั้งหมด</h2>
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

echo "==> 3) อัปเดต teacher_jobs.html ลบลิงก์ 'ดูหน้าแสดงงาน' และ 'CSV' และโชว์ผู้ใช้ปัจจุบัน + ปุ่มออกจากระบบ"
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
        <td>
          <a th:href="@{|/teacher/jobs/${j.id}/applications|}">ดูผู้สมัคร</a>
        </td>
      </tr>
    </tbody>
  </table>
</body></html>
HTML

echo "==> เสร็จแล้ว ลอง build/run ใหม่"
