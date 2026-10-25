package com.api.config;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import io.swagger.v3.oas.models.tags.Tag;

@Configuration
public class SwaggerConfig {

        @Bean
        public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

                http
                                .cors(Customizer.withDefaults())
                                .csrf(csrf -> csrf.disable())
                                .authorizeHttpRequests(auth -> auth
                                                // Swagger
                                                .requestMatchers(
                                                                "/swagger-ui/**",
                                                                "/swagger-ui.html",
                                                                "/v3/api-docs/**")
                                                .permitAll()

                                                .requestMatchers(
                                                                "/api/**",
                                                                "/",
                                                                "/error",
                                                                "/login",
                                                                "/login.html",
                                                                "/dashboard",
                                                                "/dashboard.html")
                                                .permitAll()

                                                // Other requests require authentication
                                                .anyRequest().authenticated());

                return http.build();
        }

        @Bean
        public OpenAPI customOpenAPI() {
                return new OpenAPI()
                                .info(new Info()
                                                .title("CamFix API Documentation")
                                                .version("1.0.0")
                                                .description("CamFix Platform REST API and CRUD operations")
                                                .contact(new Contact()
                                                                .name("CamFix Team")
                                                                .url("https://camonline.store")))
                                .servers(List.of(
                                                new Server().url("https://api.camonline.store").description("Production Server (Cloudflare)"),
                                                new Server().url("http://localhost:8081").description("Local Development Server")))
                                .tags(List.of(
                                                // Primary CRUD Action Tags
                                                new Tag().name("Create").description("Create & insert new records (POST)"),
                                                new Tag().name("Read").description("Retrieve & query records (GET)"),
                                                new Tag().name("Update").description("Update & modify existing records (PUT / PATCH)"),
                                                new Tag().name("Delete").description("Remove & delete records (DELETE)"),
                                                // Feature & Resource CRUD Tags
                                                new Tag().name("Technician CRUD").description("Technician registration, profile management, and CRUD operations"),
                                                new Tag().name("Booking CRUD").description("Customer bookings, service scheduling, and order CRUD operations"),
                                                new Tag().name("User CRUD").description("User accounts, customer profiles, and address CRUD operations"),
                                                new Tag().name("Category CRUD").description("Service categories and pricing catalog CRUD operations"),
                                                new Tag().name("Review CRUD").description("Technician ratings and customer review CRUD operations"),
                                                new Tag().name("Authentication").description("Login, register, phone OTP, and JWT authentication"),
                                                new Tag().name("Notification").description("In-app notifications and customer alerts"),
                                                new Tag().name("Chat & Call").description("In-app messaging and call signaling"),
                                                new Tag().name("App Version").description("Mobile app versioning and APK download")));
        }

        /**
         * Dev CORS: allow the Flutter web build / Vite to call the API from
         * another localhost port. Native mobile builds don't use CORS.
         */
        @Bean
        public CorsConfigurationSource corsConfigurationSource() {
                CorsConfiguration cfg = new CorsConfiguration();
                cfg.setAllowedOriginPatterns(List.of(
                                "http://localhost:*",
                                "http://127.0.0.1:*",
                                "https://camonline.store",
                                "https://*.camonline.store",
                                "http://camonline.store",
                                "http://*.camonline.store",
                                "https://*.github.io"));
                cfg.setAllowedMethods(List.of(
                                "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
                cfg.setAllowedHeaders(List.of("*"));
                cfg.setAllowCredentials(true);

                UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
                source.registerCorsConfiguration("/api/**", cfg);
                return source;
        }
}