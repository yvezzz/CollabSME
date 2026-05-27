package com.collabsme.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;

import jakarta.mail.internet.MimeMessage;

@Configuration
public class MailConfig {

    private static final Logger log = LoggerFactory.getLogger(MailConfig.class);

    @Bean
    @ConditionalOnMissingBean(JavaMailSender.class)
    public JavaMailSender consoleMailSender() {
        return new JavaMailSender() {
            @Override
            public void send(SimpleMailMessage message) throws MailException {
                log.info("[EMAIL CONSOLE] === Email envoyé ===");
                log.info("[EMAIL CONSOLE] To:       {}", String.join(", ", message.getTo()));
                log.info("[EMAIL CONSOLE] Cc:       {}", message.getCc() != null ? String.join(", ", message.getCc()) : "");
                log.info("[EMAIL CONSOLE] Bcc:      {}", message.getBcc() != null ? String.join(", ", message.getBcc()) : "");
                log.info("[EMAIL CONSOLE] From:     {}", message.getFrom());
                log.info("[EMAIL CONSOLE] Subject:  {}", message.getSubject());
                log.info("[EMAIL CONSOLE] Body:     {}", message.getText());
                log.info("[EMAIL CONSOLE] ===========================");
            }

            @Override
            public void send(SimpleMailMessage... messages) throws MailException {
                for (SimpleMailMessage m : messages) send(m);
            }

            @Override
            public MimeMessage createMimeMessage() {
                return null;
            }

            @Override
            public MimeMessage createMimeMessage(java.io.InputStream contentStream) throws MailException {
                return null;
            }

            @Override
            public void send(MimeMessage message) throws MailException {
                log.info("[EMAIL CONSOLE] MIME email envoyé (sujet non affichable sans parsing)");
            }

            @Override
            public void send(MimeMessage... messages) throws MailException {
                for (MimeMessage m : messages) send(m);
            }

            @Override
            public void send(MimeMessagePreparator preparator) throws MailException {
                log.info("[EMAIL CONSOLE] MIME email avec preparator envoyé");
            }

            @Override
            public void send(MimeMessagePreparator... preparators) throws MailException {
                for (MimeMessagePreparator p : preparators) send(p);
            }
        };
    }
}
