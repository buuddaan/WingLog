package com.winglog.auth.service;


import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public void sendPassword(String email, String resetLink){
        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(email);
        message.setSubject("Återställning av lösenord för WingLog");
        message.setText("för att återställa lösenordet klicka på länken.\n" + resetLink);
        mailSender.send(message);

    }


}
