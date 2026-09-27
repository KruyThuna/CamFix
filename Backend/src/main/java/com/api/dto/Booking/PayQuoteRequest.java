package com.api.dto.Booking;

/** Body for {@code POST /api/bookings/{id}/quotes/{quoteId}/pay}. */
public class PayQuoteRequest {

    /** APPLE_PAY | CARD | PAYPAL */
    private String paymentMethod;

    /** Last 4 digits only, when {@link #paymentMethod} is CARD - the app
     *  never sends a full card number here. */
    private String cardLast4;

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getCardLast4() {
        return cardLast4;
    }

    public void setCardLast4(String cardLast4) {
        this.cardLast4 = cardLast4;
    }
}
