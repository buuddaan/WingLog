package com.winglog.gateway;

import com.winglog.gateway.filter.JwtAuthFilter;
import com.winglog.shared.util.JwtUtil;
import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class JwtAuthFilterTest {

    private JwtUtil jwtUtil;
    private FilterChain filterChain;
    private JwtAuthFilter filter;

    @BeforeEach
    void setUp() {
        // Skapar nya mocks och nytt filter inför varje test för isolering /EF
        jwtUtil = mock(JwtUtil.class);
        filterChain = mock(FilterChain.class);
        filter = new JwtAuthFilter(jwtUtil);
    }

    // TEST Publika endpoints släpps igenom utan JWT-kontroll
    @Test
    void publicEndpoint_skipsJwtValidation_andPassesThrough() throws Exception {
        // Simulera request mot en publik endpoint /EF
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/gateway/auth/login");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, filterChain);
        // JwtUtil ska inte ens röras för publika endpoints /EF
         verifyNoInteractions(jwtUtil);
        // Och requesten ska skickas vidare i kedjan
        verify(filterChain, times(1)).doFilter(request, response);
    }

    // TEST Giltig JWT släpps igenom och attributen sätts på requesten
    @Test
    void validJwt_setsUserAttributes_andPassesThrough() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/gateway/users/me");
        request.addHeader("Authorization", "Bearer giltig.token.här");
        MockHttpServletResponse response = new MockHttpServletResponse();

        // JwtUtil att betrakta token som giltig och returnera användardata
        when(jwtUtil.validateToken("giltig.token.här")).thenReturn(true);
        when(jwtUtil.readEmail("giltig.token.här")).thenReturn("ef@winglog.se");
        when(jwtUtil.readUserId("giltig.token.här"))
                .thenReturn("11111111-2222-3333-4444-555555555555");

        filter.doFilter(request, response, filterChain);

        // Attributen som RoutingController läser från ska finnas på requesten /EF
        assertEquals("ef@winglog.se", request.getAttribute("X-User-Email"));
        assertEquals("11111111-2222-3333-4444-555555555555",
                request.getAttribute("X-User-Id"));
        verify(filterChain, times(1)).doFilter(request, response);
        assertEquals(200, response.getStatus());
    }

    // TEST Ogiltig JWT ger 401 och kedjan stoppas
    @Test
    void invalidJwt_returns401_andStopsChain() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/gateway/users/me");
        request.addHeader("Authorization", "Bearer trasig.token");
        MockHttpServletResponse response = new MockHttpServletResponse();

        when(jwtUtil.validateToken("trasig.token")).thenReturn(false);

        filter.doFilter(request, response, filterChain);
        // 401 ska sättas och felmeddelandet ska skrivas till bodyn /EF
        assertEquals(401, response.getStatus());
        assertEquals("Ogiltig eller utgången token", response.getContentAsString());
        // Kritiskt: kedjan får INTE fortsätta efter 401 /EF
        verify(filterChain, never()).doFilter(any(), any());
        assertNull(request.getAttribute("X-User-Email"));
        assertNull(request.getAttribute("X-User-Id"));
    }

    //TEST Saknad Authorization-header släpps igenom utan attribut
    @Test
    void missingAuthHeader_passesThrough_withoutAttributes() throws Exception {
        // Ingen Authorization-header alls /EF
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/gateway/users/me");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, filterChain);
        // JwtUtil ska inte anropas, kedjan ska gå vidare, inga attribut ska finnas
        verifyNoInteractions(jwtUtil);
        verify(filterChain, times(1)).doFilter(request, response);
        assertNull(request.getAttribute("X-User-Email"));
        assertNull(request.getAttribute("X-User-Id"));
        assertEquals(200, response.getStatus());
    }

    // TEST Authorization-header utan "Bearer "-prefix ignoreras tyst
    @Test
    void authHeaderWithoutBearerPrefix_isIgnored() throws Exception {
        // Header finns men saknar "Bearer "-prefix /EF
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setRequestURI("/gateway/users/me");
        request.addHeader("Authorization", "Basic abc123");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, filterChain);

        // Ingen JWT-validering ska ske, requesten släpps igenom oförändrad
        verifyNoInteractions(jwtUtil);
        verify(filterChain, times(1)).doFilter(request, response);
        assertNull(request.getAttribute("X-User-Email"));
        assertNull(request.getAttribute("X-User-Id"));
    }
}