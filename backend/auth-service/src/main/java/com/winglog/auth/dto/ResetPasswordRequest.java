package com.winglog.auth.dto;

public class ResetPasswordRequest {

    private String token;
    private String newPassword;

    public ResetPasswordRequest(){

    }

    public ResetPasswordRequest(String token, String newPassword){
        this.token = token;
        this.newPassword = newPassword;
    }

    public String getToken() {
        return token;
    }

    public String getNewPassword() {
        return newPassword;
    }
}
