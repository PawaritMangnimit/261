package com.example.campusjobs.controller;

import com.example.campusjobs.repo.ApplicationRepository;
import com.example.campusjobs.util.SecUtil;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/student")
public class StudentController {
    private final ApplicationRepository applicationRepository;

    public StudentController(ApplicationRepository applicationRepository) {
        this.applicationRepository = applicationRepository;
    }

    @GetMapping("/applications")
    public String myApplications(Model model) {
        String me = SecUtil.currentUsername();
        model.addAttribute("apps", applicationRepository.findByApplicantUsernameOrderByAppliedAtDesc(me));
        return "student_apps";
    }
}
