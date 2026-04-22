package com.winglog.shared.util;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;

@Component

public class JwtUtil {
    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.expiration}")
    private long expiration;

    /**
     * Genererar en JWT-Token som används för autentisering av användare.
     *
     * @param email som är kopplad till användaren
     * @return en unik JWT-Token som är giltig i 24 timmar från att den genereras.
     */
    public String generateToken(String email, String userId) {
        return Jwts.builder()
                .subject(email)
                .claim("userId", userId) // userId bakas in i JWT så varje service kan ID användaren utan att fråga databasen (stateless) /EF
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
                .compact();
    }

    /**
     * Hämtar ut användarens emailadress från en JWT-Token
     *
     * @param token som är kopplad till användare
     * @return emailadress
     */
    public String readEmail(String token) {
        return Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor((secretKey.getBytes())))
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }
    // Hämtar ut användarens userId (UUID) från JWT-token. Används i JwtAuthFilter i api-gateway för att sätta X-User-Id header så alla services kan identifiera anv direkt /EF
    public String readUserId(String token) {
        return Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor(secretKey.getBytes()))
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("userId", String.class); // Läser ut userId-claimet som lades till i generateToken() metoden /EF
    }

    /**
     * Validerar om en JWT-Token är giltig
     *
     * @param token kopplad till användare
     * @return true om JWT-Token är giltig. false om token är ogiltig
     */
    public boolean validateToken(String token) {
        try {
            readEmail(token);
            return true;

        } catch (JwtException exception) {
            return false;
        }
    }
}
