package com.api.Controller;

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

import com.api.Service.UserAddressService;
import com.api.dto.Request.UserAddressRequest;
import com.api.dto.Response.UserAddressResponse;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/addresses")
@RequiredArgsConstructor
public class UserAddressController {

    private final UserAddressService userAddressService;

    @PostMapping
    public ResponseEntity<UserAddressResponse> createAddress(@RequestBody UserAddressRequest request) {
        UserAddressResponse address = userAddressService.createAddress(request);
        return new ResponseEntity<>(address, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserAddressResponse> getAddressById(@PathVariable Long id) {
        return ResponseEntity.ok(userAddressService.getAddressById(id));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<UserAddressResponse>> getAddressesByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(userAddressService.getAddressesByUserId(userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserAddressResponse> updateAddress(@PathVariable Long id,
            @RequestBody UserAddressRequest request) {
        return ResponseEntity.ok(userAddressService.updateAddress(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAddress(@PathVariable Long id) {
        userAddressService.deleteAddress(id);
        return ResponseEntity.noContent().build();
    }
}