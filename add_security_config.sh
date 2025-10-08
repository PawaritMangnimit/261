#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="src/main/java/com/example/campusjobs/config"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/SecurityConfig.java" <<'EOF'
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

    // ใช้ NoOpPasswordEncoder เพื่อให้รหัสผ่าน "1234" ใช้ได้เลย
    @Bean
    public PasswordEncoder passwordEncoder() {
        return NoOpPasswordEncoder.getInstance();
    }

    // ประกาศผู้ใช้ 4 คน (อาจารย์ 2 / นักศึกษา 2)
    @Bean
    public UserDetailsService users() {
        UserDetails teacher1 = User.withUsername("teacher1@uni.edu")
                .password("1234").roles("TEACHER").build();
        UserDetails teacher2 = User.withUsername("teacher2@uni.edu")
                .password("1234").roles("TEACHER").build();

        UserDetails student1 = User.withUsername("student1@uni.edu")
                .password("1234").roles("STUDENT").build();
        UserDetails student2 = User.withUsername("student2@uni.edu")
                .password("1234").roles("STUDENT").build();

        return new InMemoryUserDetailsManager(teacher1, teacher2, student1, student2);
    }

    // ตั้งค่าให้ทุกคน login ได้, redirect ไป "/" หลัง login สำเร็จ
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/css/**").permitAll()
                .requestMatchers("/teacher/**").hasRole("TEACHER")
                .requestMatchers("/student/**").hasRole("STUDENT")
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
EOF

echo "✅ SecurityConfig.java ถูกสร้างแล้วที่ $CONFIG_DIR/SecurityConfig.java"
