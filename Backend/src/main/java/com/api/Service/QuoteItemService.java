package com.api.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.api.Entity.QuoteItem;
import com.api.Entity.ServiceQuote;
import com.api.Repo.QuoteItemRepository;
import com.api.dto.Booking.QuoteItemDtos.QuoteItemInput;
import com.api.dto.Booking.QuoteItemDtos.QuoteItemResponse;
import com.api.dto.Booking.ServiceQuoteResponse;

/**
 * Named line items on a quote: saved with the technician's quote, approved
 * or declined one by one by the customer, and folded into the quote total so
 * payment only ever covers the fees + approved items.
 */
@Service
public class QuoteItemService {

    private static final int MAX_ITEMS = 20;

    private final QuoteItemRepository repository;

    public QuoteItemService(QuoteItemRepository repository) {
        this.repository = repository;
    }

    /** Validates and stores the items for a freshly saved quote; returns their sum. */
    public double saveItems(Long quoteId, List<QuoteItemInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            return 0;
        }
        if (inputs.size() > MAX_ITEMS) {
            throw new IllegalArgumentException("A quote can have at most " + MAX_ITEMS + " items");
        }
        double sum = 0;
        for (QuoteItemInput in : inputs) {
            String title = in.title() == null ? "" : in.title().trim();
            if (title.isEmpty()) {
                throw new IllegalArgumentException("Every quote item needs a title");
            }
            if (title.length() > 120) {
                throw new IllegalArgumentException("Quote item titles must be 120 characters or fewer");
            }
            double price = in.price() == null ? -1 : in.price();
            if (price < 0) {
                throw new IllegalArgumentException("Quote item prices must be zero or more");
            }
            String note = in.note() == null || in.note().isBlank() ? null : in.note().trim();
            if (note != null && note.length() > 300) {
                note = note.substring(0, 300);
            }
            QuoteItem item = new QuoteItem();
            item.setQuoteId(quoteId);
            item.setTitle(title);
            item.setPrice(round2(price));
            item.setNote(note);
            item.setRecommended(Boolean.TRUE.equals(in.recommended()));
            repository.save(item);
            sum += round2(price);
        }
        return round2(sum);
    }

    /**
     * Records the customer's choice and returns the quote's new total:
     * fixed fees + only the approved items. {@code approvedIds == null}
     * approves every item (e.g. an older app version).
     */
    public double applyDecision(ServiceQuote quote, List<Long> approvedIds) {
        List<QuoteItem> items = repository.findByQuoteIdOrderByIdAsc(quote.getId());
        double fees = nz(quote.getInspectionFee()) + nz(quote.getLaborCost())
                + nz(quote.getPartsCost()) + nz(quote.getTravelFee());
        if (items.isEmpty()) {
            return round2(fees);
        }
        Set<Long> ok = approvedIds == null
                ? items.stream().map(QuoteItem::getId).collect(Collectors.toSet())
                : new HashSet<>(approvedIds);
        double approvedSum = 0;
        for (QuoteItem item : items) {
            boolean yes = ok.contains(item.getId());
            item.setApproved(yes);
            if (yes) {
                approvedSum += nz(item.getPrice());
            }
        }
        repository.saveAll(items);
        return round2(fees + approvedSum);
    }

    /** Quote DTO with its items attached. */
    public ServiceQuoteResponse toDto(ServiceQuote q) {
        ServiceQuoteResponse r = BookingService.toQuoteDto(q);
        r.setItems(repository.findByQuoteIdOrderByIdAsc(q.getId()).stream()
                .map(i -> new QuoteItemResponse(i.getId(), i.getTitle(), i.getPrice(),
                        i.getNote(), i.isRecommended(), i.getApproved()))
                .collect(Collectors.toList()));
        return r;
    }

    private static double nz(Double d) {
        return d == null ? 0 : d;
    }

    private static double round2(double v) {
        return Math.round(v * 100.0) / 100.0;
    }
}
