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
