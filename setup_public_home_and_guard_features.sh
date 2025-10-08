#!/usr/bin/env bash
set -euo pipefail

# --- Security: อนุญาตหน้า public, บังคับล็อกอินเมื่อเข้าฟีเจอร์ ---
mkdir -p src/main/java/com/example/campusjobs/config
cat > src/main/java/com/example/campusjobs/config/SecurityConfig.java <<'JAVA'
package com.example.campusjobs.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.NoOpPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // เดโมเท่านั้น: ใช้ NoOp เพื่อให้พาส "1234" ใช้ได้เลย
        return NoOpPasswordEncoder.getInstance();
    }

    // ผู้ใช้ตัวอย่าง 4 คน
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
                // ��� อนุญาตหน้า public ให้เข้าดูได้โดยไม่ต้องล็อกอิน
                .requestMatchers("/", "/login", "/public/**", "/css/**").permitAll()
                // ��� ฟีเจอร์ฝั่งอาจารย์/นักศึกษา ต้องล็อกอินตามบทบาท
                .requestMatchers("/teacher/**").hasRole("TEACHER")
                .requestMatchers("/student/**").hasRole("STUDENT")
                // ��� action สำคัญอื่น ๆ ให้ต้อง authenticated (กันกด apply/create แบบไม่ล็อกอิน)
                .requestMatchers("/jobs/**").authenticated()
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

# --- Controller: หน้า home (สาธารณะ) และ login ---
mkdir -p src/main/java/com/example/campusjobs/controller
cat > src/main/java/com/example/campusjobs/controller/AuthController.java <<'JAVA'
package com.example.campusjobs.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AuthController {
    @GetMapping("/login")
    public String login() {
        return "login";
    }
}
JAVA

cat > src/main/java/com/example/campusjobs/controller/HomeController.java <<'JAVA'
package com.example.campusjobs.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {
    // หน้า landing (public)
    @GetMapping("/")
    public String home() {
        return "index";
    }

    // dummy endpoint เพื่อทดสอบการป้องกันสิทธิ์ (จะทำจริงทีหลัง)
    @GetMapping("/teacher")
    public String teacher() { return "teacher"; }

    @GetMapping("/student")
    public String student() { return "student"; }
}
JAVA

# --- Templates: index (public), login (custom), teacher/student (ทดสอบสิทธิ์) ---
mkdir -p src/main/resources/templates

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
    .card { background:#fff; border:1px solid #e5e7eb; border-radius:14px; padding:24px; box-shadow:0 8px 24px rgba(2,6,23,.04);}
    h1 { margin:0 0 12px 0; font-size:28px;}
    p { color:#334155; }
    .row { display:flex; gap:12px; flex-wrap:wrap; margin-top:14px; }
    code { background:#f1f5f9; padding:2px 6px; border-radius:6px; }
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
    <div class="card">
      <h1>หน้าหลัก (สาธารณะ)</h1>
      <p>ดูข้อมูลเบื้องต้นได้โดยไม่ต้องล็อกอิน แต่ถ้าจะใช้ฟีเจอร์ให้ล็อกอินก่อน</p>
      <div class="row">
        <a class="btn btn-primary" href="/teacher">ไปหน้าอาจารย์ (ต้องล็อกอินเป็นอาจารย์)</a>
        <a class="btn btn-primary" href="/student">ไปหน้านักศึกษา (ต้องล็อกอินเป็นนักศึกษา)</a>
      </div>
      <p style="margin-top:14px">ตัวอย่างบัญชีทดสอบ: อาจารย์ <code>teacher1@uni.edu / 1234</code> | นักศึกษา <code>student1@uni.edu / 1234</code></p>
      <p>คำสั่งรัน: <code>docker compose up --build</code></p>
    </div>
  </div>
</body>
</html>
HTML

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

cat > src/main/resources/templates/teacher.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>Teacher Area</title></head>
<body>
  <h2>พื้นที่อาจารย์ (ต้อง ROLE_TEACHER)</h2>
  <p>หน้านี้ถูกป้องกันด้วย Security — ถ้าเห็นได้แสดงว่าล็อกอินเป็นอาจารย์แล้ว</p>
  <form method="post" action="/logout"><button type="submit">Logout</button></form>
</body></html>
HTML

cat > src/main/resources/templates/student.html <<'HTML'
<!DOCTYPE html>
<html lang="th"><head><meta charset="UTF-8"><title>Student Area</title></head>
<body>
  <h2>พื้นที่นักศึกษา (ต้อง ROLE_STUDENT)</h2>
  <p>หน้านี้ถูกป้องกันด้วย Security — ถ้าเห็นได้แสดงว่าล็อกอินเป็นนักศึกษาแล้ว</p>
  <form method="post" action="/logout"><button type="submit">Logout</button></form>
</body></html>
HTML

echo "✅ ตั้งค่าเสร็จ: Security (public home + protected features) และหน้า index/login/teacher/student พร้อมแล้ว"
