package com.collabsme;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class CollabSmeApplication {
    public static void main(String[] args) {
        SpringApplication.run(CollabSmeApplication.class, args);
    }
}
