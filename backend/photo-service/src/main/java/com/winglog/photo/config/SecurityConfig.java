package com.winglog.photo.config;

import com.winglog.photo.security.UserIdFilter;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.context.annotation.Bean;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
public class SecurityConfig {
    private final UserIdFilter userIdFilter;

    public SecurityConfig(UserIdFilter userIdFilter) {
        this.userIdFilter = userIdFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
                .addFilterBefore(userIdFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
