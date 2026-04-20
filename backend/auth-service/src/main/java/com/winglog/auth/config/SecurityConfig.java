package com.winglog.auth.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    /**
     * skapar och definerar en PasswordEncoder för att kunna kryptera lösenord
     * @return en BCryptPasswordEncoder för kryptering av lösenord.
     */
    @Bean
    public PasswordEncoder encoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * Konfigurerar säkerhetsregler för http anrop.
     * /auth/login och /auth/register är tillgängligt för alla
     * övriga endpoints kräver att användaren har en giltig JWT-Token.
     * csrf skyddt inaktiveras, JWT-Token används för autentisering
     * @param http tillhörandes appen
     * @return SecurityFilterChain innehållandes säkerhetsregler
     * @throws Exception om konfiguration misslyckas
     */
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception{
        http.authorizeHttpRequests((authorize) -> authorize
                .requestMatchers("/auth/register", "/auth/login")
                .permitAll()
                .anyRequest()
                .authenticated())
                .csrf(csrf -> csrf.disable());

                return http.build();
    }
}
