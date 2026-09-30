package com.api.service;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.api.entity.Category;
import com.api.entity.ServicePrice;
import com.api.repository.CategoryRepository;
import com.api.repository.ServicePriceRepository;
import com.api.dto.booking.ServicePriceResponse;

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

    /** The Self Drop bench fee for a category, or null when not offered. */
    @Transactional(readOnly = true)
    public Double benchFeeForCategoryName(String categoryName) {
        return categoryRepository.findByCategoryName(categoryName)
                .flatMap(c -> servicePriceRepository.findByCategoryId(c.getCategoryId()))
                .map(ServicePrice::getBenchFee)
                .orElse(null);
    }

    /**
     * Admin upsert. {@code fees} carries only the fee keys the caller actually
     * sent - a key present with a null value clears that fee, an absent key
     * leaves it unchanged.
     */
    public ServicePriceResponse upsert(Long categoryId, Double startingPrice, String description,
            java.util.Map<String, Double> fees) {
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
        if (fees != null) {
            if (fees.containsKey("benchFee")) {
                price.setBenchFee(nonNegative(fees.get("benchFee"), "benchFee"));
            }
            if (fees.containsKey("travelFee")) {
                price.setTravelFee(nonNegative(fees.get("travelFee"), "travelFee"));
            }
        }
        if (price.getStartingPrice() == null) {
            throw new IllegalArgumentException("startingPrice is required");
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
        r.setBenchFee(p.getBenchFee());
        r.setTravelFee(p.getTravelFee());
        return r;
    }

    private static Double nonNegative(Double v, String field) {
        if (v != null && v < 0) {
            throw new IllegalArgumentException(field + " must be >= 0");
        }
        return v;
    }
}
