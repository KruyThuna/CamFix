package com.api.modules.user.service;

import java.util.List;

import com.api.modules.user.dto.UserAddressRequest;
import com.api.modules.user.dto.UserAddressResponse;

public interface UserAddressService {

    UserAddressResponse createAddress(UserAddressRequest request);

    UserAddressResponse getAddressById(Long id);

    List<UserAddressResponse> getAddressesByUserId(Long userId);

    UserAddressResponse updateAddress(Long id, UserAddressRequest request);

    void deleteAddress(Long id);
}