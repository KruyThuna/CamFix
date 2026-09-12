package com.api.Service.implement;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.UserAddress;
import com.api.Repo.UserAddressRepository;
import com.api.Service.UserAddressService;
import com.api.dto.Request.UserAddressRequest;
import com.api.dto.Response.UserAddressResponse;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserAddressServiceImpl implements UserAddressService {

    private final UserAddressRepository userAddressRepository;

    @Override
    @Transactional
    public UserAddressResponse createAddress(UserAddressRequest request) {
        UserAddress address = mapToEntity(new UserAddress(), request);
        UserAddress savedAddress = userAddressRepository.save(address);
        return mapToResponse(savedAddress);
    }

    @Override
    @Transactional(readOnly = true)
    public UserAddressResponse getAddressById(Long id) {
        UserAddress address = userAddressRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + id));
        return mapToResponse(address);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserAddressResponse> getAddressesByUserId(Long userId) {
        return userAddressRepository.findByUserId(userId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public UserAddressResponse updateAddress(Long id, UserAddressRequest request) {
        UserAddress existingAddress = userAddressRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + id));

        UserAddress updatedAddress = mapToEntity(existingAddress, request);
        UserAddress savedAddress = userAddressRepository.save(updatedAddress);
        return mapToResponse(savedAddress);
    }

    @Override
    @Transactional
    public void deleteAddress(Long id) {
        UserAddress address = userAddressRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + id));
        userAddressRepository.delete(address);
    }

    private UserAddress mapToEntity(UserAddress address, UserAddressRequest request) {
        address.setAddress_Name(request.getAddress_Name());
        address.setAddress_Line(request.getAddress_Line());
        address.setCity(request.getCity());
        address.setProvince(request.getProvince());
        address.setUserId(request.getUserId());
        address.setIsDefault(request.getIsDefault());
        address.setLatitude(request.getLatitude());
        address.setLongitude(request.getLongitude());
        return address;
    }

    private UserAddressResponse mapToResponse(UserAddress address) {
        return UserAddressResponse.builder()
                .id(address.getId())
                .address_Name(address.getAddress_Name())
                .city(address.getCity())
                .province(address.getProvince())
                .userId(address.getUserId())
                .isDefault(address.getIsDefault())
                .latitude(address.getLatitude())
                .longitude(address.getLongitude())
                .build();
    }
}