package com.api.Controller;

import com.api.Service.UserManagementService;
import com.api.Service.UserManagementService.*;
import java.util.List;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/users")
public class UserManagementController {
    private final UserManagementService service;
    public UserManagementController(UserManagementService service) { this.service = service; }

    @GetMapping
    public List<UserView> list(@RequestHeader(value = "Authorization", required = false) String auth) {
        return service.list(auth);
    }

    @PostMapping("/admins")
    public ResponseEntity<UserView> create(@RequestHeader(value = "Authorization", required = false) String auth,
            @RequestBody CreateAdmin input) {
        return ResponseEntity.status(201).body(service.create(auth, input));
    }

    @PutMapping("/{id}")
    public UserView update(@RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id, @RequestBody EditUser input) {
        return service.update(auth, id, input);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@RequestHeader(value = "Authorization", required = false) String auth,
            @PathVariable Long id) {
        service.delete(auth, id);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<java.util.Map<String, String>> conflict() {
        return ResponseEntity.status(409).body(java.util.Map.of("message",
                "Cannot save or delete this account: duplicate details or linked records exist."));
    }
}
