package com.api.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.mockito.ArgumentCaptor;
import com.api.entity.Job;
import com.api.repository.JobRepository;

class CompletedWorkTest {
    @Test
    void returnsOnlyRequestedTechniciansCompletedJobsInNewestFirstPages() {
        var jobs = mock(JobRepository.class);
        var directory = mock(PublicTechnicianService.class);
        var service = new TechnicianServiceManager(null, null, jobs, null, directory, null);
        var date = LocalDateTime.of(2026, 9, 29, 10, 0);
        var job = Job.builder().id(8L).category("Electrical").completedAt(date)
                .customerUserId(12L).customerName("Sok Dara").description("Private issue").build();
        when(jobs.findByTechnicianIdAndStatus(eq(7L), eq("COMPLETED"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(job)));
        var result = service.completedWork(7L, 1);
        assertEquals(1, result.size());
        assertEquals("Electrical", result.get(0).category());
        assertEquals(date, result.get(0).completedAt());
        var page = ArgumentCaptor.forClass(Pageable.class);
        verify(jobs).findByTechnicianIdAndStatus(eq(7L), eq("COMPLETED"), page.capture());
        assertEquals(1, page.getValue().getPageNumber());
        assertEquals(20, page.getValue().getPageSize());
        assertTrue(page.getValue().getSort().getOrderFor("completedAt").isDescending());
        assertTrue(page.getValue().getSort().getOrderFor("id").isDescending());
        verify(directory).get(7L);
        assertEquals(12L, result.get(0).customerUserId());
        assertEquals("Sok Dara", result.get(0).customerName());
        assertEquals(5, result.get(0).getClass().getRecordComponents().length);
    }

    @Test
    void hiddenTechnicianCannotExposeHistory() {
        var jobs = mock(JobRepository.class);
        var directory = mock(PublicTechnicianService.class);
        var service = new TechnicianServiceManager(null, null, jobs, null, directory, null);
        when(directory.get(7L)).thenThrow(new NoSuchElementException());
        assertThrows(NoSuchElementException.class, () -> service.completedWork(7L, 0));
        verifyNoInteractions(jobs);
    }

    @Test
    void rejectsNegativePage() {
        var jobs = mock(JobRepository.class);
        var service = new TechnicianServiceManager(null, null, jobs, null,
                mock(PublicTechnicianService.class), null);
        assertThrows(IllegalArgumentException.class, () -> service.completedWork(7L, -1));
        verifyNoInteractions(jobs);
    }
}
