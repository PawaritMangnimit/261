#!/usr/bin/env bash
set -euo pipefail

# 1) Controller สำหรับ /login
mkdir -p src/main/java/com/example/campusjobs/controller
cat > src/main/java/com/example/campusjobs/controller/AuthController.java <<'JAVA'
package com.example.campusjobs.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AuthController {

    @GetMapping("/login")
    public String login() {
        return "login"; // templates/login.html
    }
}
JAVA

# 2) เทมเพลต login.html
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
    <form method="post" action="/login">
      <label>Username</label>
      <input type="text" name="username" required />
      <label>Password</label>
      <input type="password" name="password" required />
      <button type="submit">Sign in</button>
    </form>
    <div class="hint">
      ทดสอบได้ด้วย:<br/>
      อาจารย์: <code>teacher1@uni.edu</code> / <code>1234</code><br/>
      นักศึกษา: <code>student1@uni.edu</code> / <code>1234</code>
    </div>
    <div class="error">
      <!-- Spring Security จะใส่พารามิเตอร์ ?error เมื่อ login fail -->
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

echo "✅ สร้าง Controller และ templates/login.html เสร็จแล้ว"
