package com.winglog.gateway.filter;

import com.winglog.shared.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    // Endpoints som inte kräver JWT /EF
    private static final List<String> PUBLIC_ENDPOINTS = List.of(
            "/gateway/auth/login",
            "/gateway/auth/register",
            "/gateway/health"
    );

    public JwtAuthFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();

        // Släpp igenom publika endpoints utan JWT-kontroll /EF
        if (PUBLIC_ENDPOINTS.contains(path)) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);

            if (!jwtUtil.validateToken(token)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("Ogiltig eller utgången token");
                return;
            }

            request.setAttribute("X-User-Email", jwtUtil.readEmail(token));
            request.setAttribute("X-User-Id", jwtUtil.readUserId(token));
        }

        filterChain.doFilter(request, response);
    }
}