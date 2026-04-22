package com.winglog.auth.config;

import com.winglog.auth.model.User;
import com.winglog.auth.repository.UserRepository;
import com.winglog.shared.util.JwtUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Optional;

@Component
public class GoogleAuthHandler implements AuthenticationSuccessHandler {
    private UserRepository userRepository;
    private JwtUtil jwtUtil;

    public GoogleAuthHandler (UserRepository userRepository, JwtUtil jwtUtil){
        this.userRepository = userRepository;
        this.jwtUtil = jwtUtil;
    }

    /**
     * Hanterar en lyckad Google Auth2-autentisering.
     * Skapar ny användare om inte användaren redan finns i databasen
     * En JWT-Token genereras och skickas till frontend
     * @param request anrop från klient
     * @param response som används för att skicka svar till frontend
     * @param authentication som innehåller använddarens information från Google kontot
     * @throws IOException om fel inträffar när svar skickas till frontend
     * @throws ServletException om fel med hantering av anrop
     */
    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
        OAuth2User oAuth2User = (OAuth2User) authentication.getPrincipal();
        String email = oAuth2User.getAttribute("email");
        String username = authentication.getName().replace(" ","");

        Optional<User> authUser = userRepository.findByEmail(email);
        if(authUser.isEmpty()){
           User user = new User();
           user.setEmail(email);
           user.setProvider("google");
           user.setUsername(username);

            authUser = Optional.of(userRepository.save(user));
        }

        String token = jwtUtil.generateToken(email, authUser.get().getId().toString());
        response.sendRedirect("http://localhost:8080?token=" + token);
    }
}
