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
