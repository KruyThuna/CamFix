package com.api.Service.implement;

import com.api.Entity.TechnicianAddresses;
import com.api.Repo.TechnicianAddressRepository;
import com.api.Service.TechnicianAddressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TechnicianAddressServiceImpl implements TechnicianAddressService {

    @Autowired
    private TechnicianAddressRepository repository;

    @Override
    @Transactional
    public TechnicianAddresses createAddress(TechnicianAddresses address) {
        // If set as default, clear existing default for this technician
        if (Boolean.TRUE.equals(address.getIsDefault())) {
            repository.findByTechnicianIdAndIsDefaultTrue(address.getTechnicianId())
                    .ifPresent(existingDefault -> {
                        existingDefault.setIsDefault(false);
                        repository.save(existingDefault);
                    });
        }
        return repository.save(address);
    }

    @Override
    public TechnicianAddresses getAddressById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Address not found with ID: " + id));
    }

    @Override
    public List<TechnicianAddresses> getAddressesByTechnicianId(Long technicianId) {
        return repository.findByTechnicianId(technicianId);
    }

    @Override
    @Transactional
    public TechnicianAddresses updateAddress(Long id, TechnicianAddresses addressDetails) {
        TechnicianAddresses existingAddress = getAddressById(id);

        existingAddress.setBusinessName(addressDetails.getBusinessName());
        existingAddress.setAddressLine(addressDetails.getAddressLine());
        existingAddress.setCity(addressDetails.getCity());
        existingAddress.setProvince(addressDetails.getProvince());
        existingAddress.setLatitude(addressDetails.getLatitude());
        existingAddress.setLongitude(addressDetails.getLongitude());

        if (Boolean.TRUE.equals(addressDetails.getIsDefault())) {
            repository.findByTechnicianIdAndIsDefaultTrue(existingAddress.getTechnicianId())
                    .ifPresent(currDefault -> {
                        if (!currDefault.getAddressId().equals(id)) {
                            currDefault.setIsDefault(false);
                            repository.save(currDefault);
                        }
                    });
            existingAddress.setIsDefault(true);
        }

        return repository.save(existingAddress);
    }

    @Override
    @Transactional
    public void deleteAddress(Long id) {
        TechnicianAddresses address = getAddressById(id);
        repository.delete(address);
    }
}