package com.api.controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.service.ServicePriceService;
import com.api.dto.booking.ServicePriceResponse;

/** Public catalog of "starting from" prices - shown before a customer books,
 *  never the final repair cost (see {@code ServiceQuote} for that). */
@RestController
@RequestMapping("/api/service-prices")
public class ServicePriceController {

    private final ServicePriceService servicePriceService;

    public ServicePriceController(ServicePriceService servicePriceService) {
        this.servicePriceService = servicePriceService;
    }

    @GetMapping
    public List<ServicePriceResponse> list() {
        return servicePriceService.list();
    }

    @GetMapping("/category/{categoryId}")
    public ServicePriceResponse getByCategory(@PathVariable Long categoryId) {
        return servicePriceService.getByCategory(categoryId);
    }

    /** Upsert - simple admin-console convenience, matching the equally
     *  unauthenticated {@code CategoryController} create/update endpoints. */
    @PutMapping("/category/{categoryId}")
    public ServicePriceResponse upsert(@PathVariable Long categoryId, @RequestBody Map<String, Object> body) {
        Object priceRaw = body == null ? null : body.get("startingPrice");
        Double price = priceRaw == null ? null : Double.valueOf(priceRaw.toString());
        String description = body == null ? null : (String) body.get("description");
        return servicePriceService.upsert(categoryId, price, description);
    }
}
