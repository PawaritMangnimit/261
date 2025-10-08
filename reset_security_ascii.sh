#!/usr/bin/env bash
set -euo pipefail

CONFIG="src/main/java/com/example/campusjobs/config/SecurityConfig.java"
mkdir -p "$(dirname "$CONFIG")"

cat > "$CONFIG" <<'JAVA'
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
        // Demo only. Use BCrypt in real apps.
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
                .requestMatchers("/", "/login", "/public/**", "/css/**").permitAll()
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

# เพิ่มการตั้งค่า encoding ให้ pom.xml ถ้ายังไม่มี
if ! grep -q "<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>" pom.xml; then
  if grep -q "<properties>" pom.xml; then
    perl -0777 -pe 's|<properties>|<properties>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>|' -i pom.xml
  else
    perl -0777 -pe 's|</parent>|</parent>\n\n  <properties>\n    <java.version>17</java.version>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>\n  </properties>|' -i pom.xml
  fi
fi

# เติม maven-compiler-plugin ถ้ายังไม่มี
if ! grep -q "<artifactId>maven-compiler-plugin</artifactId>" pom.xml; then
  perl -0777 -pe 's|</plugins>|  <plugin>\n        <groupId>org.apache.maven.plugins</groupId>\n        <artifactId>maven-compiler-plugin</artifactId>\n        <version>3.11.0</version>\n        <configuration>\n          <source>17</source>\n          <target>17</target>\n          <encoding>UTF-8</encoding>\n        </configuration>\n      </plugin>\n    </plugins>|' -i pom.xml
fi

# ล้าง target เพื่อ build ใหม่สะอาด ๆ
rm -rf target || true

echo "✅ SecurityConfig.java reset (ASCII only) + ensured UTF-8 in pom.xml"
echo "ต่อด้วย: docker compose up --build"
