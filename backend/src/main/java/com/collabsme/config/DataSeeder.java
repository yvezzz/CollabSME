package com.collabsme.config;

import com.collabsme.company.Company;
import com.collabsme.company.CompanyRepository;
import com.collabsme.project.model.*;
import com.collabsme.project.repository.ProjectRepository;
import com.collabsme.project.repository.TaskRepository;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;

@Component
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final UserRepository userRepository;
    private final CompanyRepository companyRepository;
    private final ProjectRepository projectRepository;
    private final TaskRepository taskRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(UserRepository userRepository, CompanyRepository companyRepository,
                      ProjectRepository projectRepository, TaskRepository taskRepository,
                      PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.companyRepository = companyRepository;
        this.projectRepository = projectRepository;
        this.taskRepository = taskRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            log.info("Database already seeded, skipping.");
            return;
        }

        log.info("Seeding database...");

        Company company = new Company();
        company.setName("Ma Société");
        company.setSubscriptionStatus(com.collabsme.company.SubscriptionStatus.FREE);
        company = companyRepository.save(company);

        User admin = new User();
        admin.setEmail("admin@collabsme.com");
        admin.setPassword(passwordEncoder.encode("admin123"));
        admin.setFirstName("Admin");
        admin.setLastName("Principal");
        admin.setPhoneNumber("+33 6 12 34 56 78");
        admin.setCompany(company);
        admin.setRole(Role.ADMIN);
        admin.setCompanyAdmin(true);
        admin = userRepository.save(admin);

        User demo = new User();
        demo.setEmail("demo@collabsme.com");
        demo.setPassword(passwordEncoder.encode("demo123"));
        demo.setFirstName("Démo");
        demo.setLastName("Utilisateur");
        demo.setCompany(company);
        demo.setRole(Role.MEMBER);
        demo.setCompanyAdmin(false);
        demo = userRepository.save(demo);

        Project project1 = new Project();
        project1.setCompany(company);
        project1.setKey("PROJ1");
        project1.setTitle("Site Web E-commerce");
        project1.setDescription("Refonte complète du site e-commerce avec nouvelle stack technique.");
        project1.setStatus(ProjectStatus.ACTIVE);
        project1.setPriority(Priority.HIGH);
        project1.setBudget(BigDecimal.valueOf(50000));
        project1.setCreatedBy(admin);
        project1.setStartDate(LocalDate.now().minusMonths(1));
        project1.setEndDate(LocalDate.now().plusMonths(3));
        project1 = projectRepository.save(project1);

        Project project2 = new Project();
        project2.setCompany(company);
        project2.setKey("PROJ2");
        project2.setTitle("Application Mobile");
        project2.setDescription("Développement application mobile iOS et Android.");
        project2.setStatus(ProjectStatus.DRAFT);
        project2.setPriority(Priority.MEDIUM);
        project2.setBudget(BigDecimal.valueOf(80000));
        project2.setCreatedBy(admin);
        project2.setStartDate(LocalDate.now().plusMonths(1));
        project2.setEndDate(LocalDate.now().plusMonths(6));
        project2 = projectRepository.save(project2);

        Task task1 = new Task();
        task1.setProject(project1);
        task1.setTitle("Définir le cahier des charges");
        task1.setDescription("Rédiger le cahier des charges complet avec toutes les fonctionnalités.");
        task1.setStatus(TaskStatus.DONE);
        task1.setPriority(Priority.HIGH);
        task1.setAssignedTo(admin);
        task1.setCreatedBy(admin);
        task1.setOrder(1);
        task1.setDueDate(LocalDate.now().minusDays(5));
        taskRepository.save(task1);

        Task task2 = new Task();
        task2.setProject(project1);
        task2.setTitle("Maquettes UI/UX");
        task2.setDescription("Créer les maquettes des principales pages (accueil, catalogue, panier).");
        task2.setStatus(TaskStatus.IN_PROGRESS);
        task2.setPriority(Priority.HIGH);
        task2.setAssignedTo(demo);
        task2.setCreatedBy(admin);
        task2.setOrder(2);
        task2.setDueDate(LocalDate.now().plusDays(10));
        taskRepository.save(task2);

        Task task3 = new Task();
        task3.setProject(project1);
        task3.setTitle("Mise en place base de données");
        task3.setDescription("Modéliser et créer le schéma de base de données.");
        task3.setStatus(TaskStatus.TODO);
        task3.setPriority(Priority.MEDIUM);
        task3.setAssignedTo(admin);
        task3.setCreatedBy(admin);
        task3.setOrder(3);
        task3.setDueDate(LocalDate.now().plusDays(14));
        taskRepository.save(task3);

        log.info("Database seeded successfully!");
        log.info("Admin credentials: admin@collabsme.com / admin123");
        log.info("Demo credentials: demo@collabsme.com / demo123");
    }
}
