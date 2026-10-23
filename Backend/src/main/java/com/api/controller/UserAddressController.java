package com.api.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.UserAddressService;
import com.api.dto.request.UserAddressRequest;
import com.api.dto.response.UserAddressResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@Tag(name = "User CRUD", description = "Customer address book CRUD operations")
@RestController
@RequestMapping("/api/v1/addresses")
public class UserAddressController {

    private final UserAddressService userAddressService;

    public UserAddressController(UserAddressService userAddressService) {
        this.userAddressService = userAddressService;
    }

    @Operation(summary = "Create user address", description = "Create and save a new user address", tags = {"Create", "User CRUD"})
    @PostMapping
    public ResponseEntity<UserAddressResponse> createAddress(@RequestBody UserAddressRequest request) {
        UserAddressResponse address = userAddressService.createAddress(request);
        return new ResponseEntity<>(address, HttpStatus.CREATED);
    }

    @Operation(summary = "Get address by ID", description = "Read/retrieve a single address by ID", tags = {"Read", "User CRUD"})
    @GetMapping("/{id}")
    public ResponseEntity<UserAddressResponse> getAddressById(@PathVariable Long id) {
        return ResponseEntity.ok(userAddressService.getAddressById(id));
    }

    @Operation(summary = "Get addresses by user ID", description = "Read/list all addresses for a user", tags = {"Read", "User CRUD"})
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<UserAddressResponse>> getAddressesByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(userAddressService.getAddressesByUserId(userId));
    }

    @Operation(summary = "Update address", description = "Update an existing user address by ID", tags = {"Update", "User CRUD"})
    @PutMapping("/{id}")
    public ResponseEntity<UserAddressResponse> updateAddress(@PathVariable Long id,
            @RequestBody UserAddressRequest request) {
        return ResponseEntity.ok(userAddressService.updateAddress(id, request));
    }

    @Operation(summary = "Delete address", description = "Delete an address by ID", tags = {"Delete", "User CRUD"})
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAddress(@PathVariable Long id) {
        userAddressService.deleteAddress(id);
        return ResponseEntity.noContent().build();
    }
}