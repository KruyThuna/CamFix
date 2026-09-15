package com.api.Service;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.Entity.Category;
import com.api.Entity.ServicePrice;
import com.api.Repo.CategoryRepository;
import com.api.Repo.ServicePriceRepository;
import com.api.dto.Booking.ServicePriceResponse;

/** The "starting from" catalog shown to a customer before they book - see
 *  {@code ServicePrice} for why this is never the final repair cost. */
@Service
@Transactional
public class ServicePriceService {

    private final ServicePriceRepository servicePriceRepository;
    private final CategoryRepository categoryRepository;

    public ServicePriceService(ServicePriceRepository servicePriceRepository,
            CategoryRepository categoryRepository) {
        this.servicePriceRepository = servicePriceRepository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public List<ServicePriceResponse> list() {
        return servicePriceRepository.findAll().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ServicePriceResponse getByCategory(Long categoryId) {
        return toDto(servicePriceRepository.findByCategoryId(categoryId)
                .orElseThrow(() -> new NoSuchElementException(
                        "No starting price configured for category " + categoryId)));
    }

    /** Best-effort lookup by category name (the customer app books by category
     *  name, e.g. "Air Conditioner") - returns null rather than throwing so a
     *  booking can still be created if pricing isn't configured yet. */
    @Transactional(readOnly = true)
    public Double startingPriceForCategoryName(String categoryName) {
        return categoryRepository.findByCategoryName(categoryName)
                .flatMap(c -> servicePriceRepository.findByCategoryId(c.getCategoryId()))
                .map(ServicePrice::getStartingPrice)
                .orElse(null);
    }

    public ServicePriceResponse upsert(Long categoryId, Double startingPrice, String description) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new NoSuchElementException("Category not found: " + categoryId));
        ServicePrice price = servicePriceRepository.findByCategoryId(categoryId)
                .orElseGet(() -> {
                    ServicePrice p = new ServicePrice();
                    p.setCategoryId(categoryId);
                    return p;
                });
        if (startingPrice != null) {
            if (startingPrice < 0) {
                throw new IllegalArgumentException("startingPrice must be >= 0");
            }
            price.setStartingPrice(startingPrice);
        }
        if (description != null) {
            price.setDescription(description);
        }
        ServicePrice saved = servicePriceRepository.save(price);
        return toDto(saved, category.getCategoryName());
    }

    private ServicePriceResponse toDto(ServicePrice p) {
        String name = categoryRepository.findById(p.getCategoryId())
                .map(Category::getCategoryName)
                .orElse(null);
        return toDto(p, name);
    }

    private ServicePriceResponse toDto(ServicePrice p, String categoryName) {
        ServicePriceResponse r = new ServicePriceResponse();
        r.setCategoryId(p.getCategoryId());
        r.setCategoryName(categoryName);
        r.setStartingPrice(p.getStartingPrice());
        r.setDescription(p.getDescription());
        return r;
    }
}
