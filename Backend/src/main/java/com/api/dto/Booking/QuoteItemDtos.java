package com.api.dto.Booking;

import java.util.List;

/** Line-item shapes for quotes. */
public final class QuoteItemDtos {

    private QuoteItemDtos() {
    }

    /** Sent by the technician with a quote. */
    public record QuoteItemInput(String title, Double price, String note, Boolean recommended) {
    }

    /** Returned inside {@link ServiceQuoteResponse#getItems()}. */
    public record QuoteItemResponse(Long id, String title, Double price, String note,
            boolean recommended, Boolean approved) {
    }

    /** Customer's accept body: which items they approve (null = all). */
    public record AcceptQuoteRequest(List<Long> approvedItemIds) {
    }
}
