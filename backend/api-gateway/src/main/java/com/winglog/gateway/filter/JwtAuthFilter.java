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

        // Hämta Authorization-headern /EF
        String authHeader = request.getHeader("Authorization");

        // Saknas headern eller börjar den inte med "Bearer " --> dkicka felkod 401
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Saknad eller felaktig Authorization-header");
            return;
        }

        //Plocka ut själva token-strängen /EF
        String token = authHeader.substring(7);

        // Validera token
        if (!jwtUtil.validateToken(token)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("Ogiltig eller utgången token");
            return;
        }

        // Token giltig, plocka ut email och lägg som attribut för downstream-services /EF
        String email = jwtUtil.readEmail(token);
        request.setAttribute("X-User-Email", email);

        String userId = jwtUtil.readUserId(token); // Läser ut userId-claimet ur den validerade JWT-token /EF
        request.setAttribute("X-User-Id", userId); // Fäster userId på requesten så downstream-services kan identifiera användaren utan att parsa JWT själva (stateless) /EF

        // Släpp igenom till controller
        filterChain.doFilter(request, response);
    }
}