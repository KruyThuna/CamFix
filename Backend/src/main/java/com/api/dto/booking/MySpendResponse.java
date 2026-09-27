package com.api.dto.booking;

import java.util.ArrayList;
import java.util.List;

/** Payload for {@code GET /api/bookings/payments/mine} - the signed-in
 *  customer's real total across all their completed payments, plus each
 *  payment (newest first) so the app can break spending down per booking. */
public class MySpendResponse {

    private double totalSpend;

    private List<PaymentResponse> payments = new ArrayList<>();

    public double getTotalSpend() {
        return totalSpend;
    }

    public void setTotalSpend(double totalSpend) {
        this.totalSpend = totalSpend;
    }

    public List<PaymentResponse> getPayments() {
        return payments;
    }

    public void setPayments(List<PaymentResponse> payments) {
        this.payments = payments;
    }
}
