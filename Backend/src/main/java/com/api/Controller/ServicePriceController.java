package com.api.Controller;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.api.Service.ServicePriceService;
import com.api.dto.Booking.ServicePriceResponse;

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
        Double price = toDouble(body == null ? null : body.get("startingPrice"));
        String description = body == null ? null : (String) body.get("description");
        Map<String, Double> fees = new java.util.HashMap<>();
        if (body != null) {
            for (String key : List.of("benchFee", "travelFee")) {
                if (body.containsKey(key)) {
                    fees.put(key, toDouble(body.get(key)));
                }
            }
        }
        return servicePriceService.upsert(categoryId, price, description, fees);
    }

    private static Double toDouble(Object raw) {
        return raw == null || raw.toString().isBlank() ? null : Double.valueOf(raw.toString());
    }
}
