package com.winglog.auth.dto;

public class ForgotPasswordRequest {

    private String email;

    public  ForgotPasswordRequest(){

    }

    public ForgotPasswordRequest(String email){
        this.email = email;
    }

    public String getEmail() {
        return email;
    }
}
