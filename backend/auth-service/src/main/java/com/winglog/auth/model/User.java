package com.winglog.auth.model;

import jakarta.persistence.*;

@Entity
@Table(name = "users")

public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;
    @Column(unique = true, nullable = false)
    private String email;
    @Column(unique = true, nullable = false) // måste vara unikt,får inte vara tomt
    private String username;
    private String password;
    private String provider;

    public User() {
    }

    public User(String id, String email, String username, String password, String provider) {
        this.id = id;
        this.email = email;
        this.username = username;
        this.password = password;
        this.provider = provider;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getId() {
        return id;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getEmail() {
        return email;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getUsername() {
        return username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    //Frågan är om vi ska ha denna ens eller om vi ska låta lösenordsjämförelse skötas direkt via Spring Security
    public String getPassword() {
        return password;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getProvider() {
        return provider;
    }


}
