package com.api.service;

import com.api.entity.TechnicianAddresses;
import java.util.List;

public interface TechnicianAddressService {

    TechnicianAddresses createAddress(TechnicianAddresses address);

    TechnicianAddresses getAddressById(Long id);

    List<TechnicianAddresses> getAddressesByTechnicianId(Long technicianId);

    TechnicianAddresses updateAddress(Long id, TechnicianAddresses addressDetails);

    void deleteAddress(Long id);
}