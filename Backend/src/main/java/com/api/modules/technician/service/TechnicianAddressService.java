package com.api.modules.technician.service;


import com.api.modules.technician.entity.Technician;
import com.api.modules.technician.entity.TechnicianAddresses;
import java.util.List;

public interface TechnicianAddressService {

    TechnicianAddresses createAddress(TechnicianAddresses address);

    TechnicianAddresses getAddressById(Long id);

    List<TechnicianAddresses> getAddressesByTechnicianId(Long technicianId);

    TechnicianAddresses updateAddress(Long id, TechnicianAddresses addressDetails);

    void deleteAddress(Long id);
}