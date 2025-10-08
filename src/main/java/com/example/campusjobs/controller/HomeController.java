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
