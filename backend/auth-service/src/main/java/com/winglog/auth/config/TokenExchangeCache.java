/**
 * BESKRIVNING AV KLASSEN:
 * In-memory cache för engångskoder i OAuth2 Authorization Code-flödet /EF
 *
 * Syfte: JWT ska inte synas i URL efter Google-inloggning. Istället sparas
 * JWT här med en slumpad UUID som nyckel. Frontend får UUID-koden i URL,
 * POSTar den till /auth/exchange, och får tillbaka JWT i response body.
 *
 * - store(jwt): sparar JWT, returnerar UUID-kod
 * - consume(code): hämtar JWT och raderar entry (engångsanvändning)
 * - Entries går ut efter 30 sekunder
 * - ConcurrentHashMap för trådsäkerhet vid samtidiga inloggningar
 */

package com.winglog.auth.config;

import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory cache för engångskoder i OAuth2 Authorization Code-flödet. /EF
 * Mappar UUID -> JWT med kort TTL. Koden bränns vid inlösen för
 * att förhindra återanvändning.
 */
@Component
public class TokenExchangeCache {

    // TTL: 30 sekunder räcker bra, Flutter löser in koden direkt vid mount /EF
    private static final long TTL_MILLIS = 30_000;

    private final Map<String, CacheEntry> store = new ConcurrentHashMap<>();

    /**
     * Sparar JWT i cachen och returnerar engångskoden som ska skickas till frontend.
     */
    public String store(String jwt) {
        String code = UUID.randomUUID().toString();
        store.put(code, new CacheEntry(jwt, Instant.now().toEpochMilli() + TTL_MILLIS));
        return code;
    }

    /**
     * Hämtar och raderar JWT för given kod. Returnerar null om koden
     * är ogiltig, redan inlöst eller utgången.
     */
    public String consume(String code) {
        if (code == null) return null;
        CacheEntry entry = store.remove(code); // remove = "bränn" /EF
        if (entry == null) return null;
        if (Instant.now().toEpochMilli() > entry.expiresAt) return null;
        return entry.jwt;
    }

    private static class CacheEntry {
        final String jwt;
        final long expiresAt;

        CacheEntry(String jwt, long expiresAt) {
            this.jwt = jwt;
            this.expiresAt = expiresAt;
        }
    }
}