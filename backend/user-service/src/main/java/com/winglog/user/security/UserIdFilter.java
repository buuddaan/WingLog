package com.winglog.user.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class UserIdFilter extends OncePerRequestFilter {
    public static final String USER_ID_HEADER = "X-User-Id";
    public static final String USER_ID_ATTRIBUTE = "userId";
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String userIdHeader = request.getHeader(USER_ID_HEADER);
        if (userIdHeader != null && !userIdHeader.isBlank()) {
            request.setAttribute(USER_ID_ATTRIBUTE, userIdHeader);
        }

        filterChain.doFilter(request, response);
    }
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().startsWith("/internal/");
    }
}
