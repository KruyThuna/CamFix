package com.api.service;

import java.util.List;

import com.api.dto.request.UserAddressRequest;
import com.api.dto.response.UserAddressResponse;

public interface UserAddressService {

    UserAddressResponse createAddress(UserAddressRequest request);

    UserAddressResponse getAddressById(Long id);

    List<UserAddressResponse> getAddressesByUserId(Long userId);

    UserAddressResponse updateAddress(Long id, UserAddressRequest request);

    void deleteAddress(Long id);
}