package com.api.Controller;

import java.io.IOException;

import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PageController {

    @GetMapping({ "/", "/login", "/login.html" })
    public ResponseEntity<Resource> loginPage() throws IOException {
        return htmlResource("templates/login.html");
    }

    @GetMapping({ "/dashboard", "/dashboard.html" })
    public ResponseEntity<Resource> dashboardPage() throws IOException {
        return htmlResource("templates/dashboard.html");
    }

    private ResponseEntity<Resource> htmlResource(String path) throws IOException {
        Resource resource = new ClassPathResource(path);
        if (!resource.exists()) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_HTML)
                .body(resource);
    }
}
