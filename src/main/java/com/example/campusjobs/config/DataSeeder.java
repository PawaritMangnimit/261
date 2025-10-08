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
