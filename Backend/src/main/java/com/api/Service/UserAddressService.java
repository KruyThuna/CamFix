package com.api.Service;

import java.util.List;

import com.api.dto.Request.UserAddressRequest;
import com.api.dto.Response.UserAddressResponse;

public interface UserAddressService {

    UserAddressResponse createAddress(UserAddressRequest request);

    UserAddressResponse getAddressById(Long id);

    List<UserAddressResponse> getAddressesByUserId(Long userId);

    UserAddressResponse updateAddress(Long id, UserAddressRequest request);

    void deleteAddress(Long id);
}