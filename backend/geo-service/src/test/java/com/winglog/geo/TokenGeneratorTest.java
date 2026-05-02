// Skapar egen token för att testa flöde utan att omdirigeras av auth?? /EF
package com.winglog.geo;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;

import java.util.Date;

public class TokenGeneratorTest {

    @Test
    void printToken() {
        String secret = "JwtEnHemligNyckelSomArValdigtLang244466666";
        String token = Jwts.builder()
                .subject("test@winglog.com")
                .claim("userId", "00000000-0000-0000-0000-000000000099")
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + 86400000))
                .signWith(Keys.hmacShaKeyFor(secret.getBytes()))
                .compact();

        System.out.println("TOKEN: " + token);
    }
}