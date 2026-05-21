package com.winglog.gateway.filter;

import com.winglog.shared.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    // Endpoints som inte kräver JWT /EF
    private static final List<String> PUBLIC_ENDPOINTS = List.of(
            "/gateway/auth/login",
            "/gateway/auth/register",
            "/gateway/auth/forgot-password",
            "/gateway/auth/reset-password",
            "/gateway/auth/exchange",
            "/gateway/health"
    );

    private static final List<String> PUBLIC_PREFIXES = List.of(
            "/gateway/oauth2/",
            "/gateway/login/oauth2/"
    );

    public JwtAuthFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // Rensa eventuella förinställda identitetsattribut innan validering
        // Skyddar mot att kod tidigare i kedjan satt attributen och därmed spoofar identitet /EF
        request.removeAttribute("X-User-Email");
        request.removeAttribute("X-User-Id");

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();

        // Släpp igenom publika endpoints utan JWT-kontroll /EF
        if (PUBLIC_ENDPOINTS.contains(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        // Släpp igenom OAuth2-flödet utan JWT (användaren har ingen token ännu)
        if (PUBLIC_PREFIXES.stream().anyMatch(path::startsWith)) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Inte behörig");
            return;
        }

        String token = authHeader.substring(7);

        if (!jwtUtil.validateToken(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Inte behörig");
            return;
        }

        String email = jwtUtil.readEmail(token);
        String userId = jwtUtil.readUserId(token);

        request.setAttribute("X-User-Email", email);
        request.setAttribute("X-User-Id", userId);

        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                email, null, Collections.emptyList()
        );
        SecurityContextHolder.getContext().setAuthentication(auth);

        filterChain.doFilter(request, response);
    }
}