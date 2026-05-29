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

import java.time.LocalDate;

@Component
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    public DataSeeder() {}

    @Override
    public void run(String... args) {
        log.info("DataSeeder disabled: no test data injected.");
    }
}
