package com.api.Service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.Base64;
import java.util.Optional;
import javax.imageio.ImageIO;

import com.api.Controller.AdminController;
import com.api.Entity.Category;
import com.api.Entity.Technician;
import com.api.Repo.CategoryRepository;
import com.api.Repo.TechnicianRepository;
import com.api.Repo.UserRepository;
import com.api.Security.JwtService;
import com.api.dto.Technician.TechnicianRegisterRequest;
import com.api.exception.ForbiddenException;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

class TechnicianIdentityTest {
    private static byte[] image() throws Exception {
        var out = new ByteArrayOutputStream();
        ImageIO.write(new BufferedImage(20, 20, BufferedImage.TYPE_INT_RGB), "png", out);
        return out.toByteArray();
    }

    @Test
    void validatesImagesAndRejectsMissingInvalidAndOversizedDocuments() throws Exception {
        byte[] png = image();
        assertArrayEquals(png, IdentityCardImage.decode(Base64.getEncoder().encodeToString(png)));
        assertThrows(IllegalArgumentException.class, () -> IdentityCardImage.decode(null));
        assertThrows(IllegalArgumentException.class, () -> IdentityCardImage.decode("%%%"));
        assertThrows(IllegalArgumentException.class, () -> IdentityCardImage.decode("dGV4dA=="));
        assertThrows(IllegalArgumentException.class, () -> IdentityCardImage.decode("A".repeat(7_000_000)));
        assertThrows(IllegalArgumentException.class, () -> IdentityCardImage.decode(
                Base64.getEncoder().encodeToString(new byte[] {(byte)255, (byte)216, (byte)255})));
    }

    @Test
    void requiresOtpAndBothPhotosAndKeepsApprovalPending() throws Exception {
        var users = mock(UserRepository.class);
        var technicians = mock(TechnicianRepository.class);
        var categories = mock(CategoryRepository.class);
        var jwt = mock(JwtService.class);
        var otp = mock(OtpService.class);
        var passwords = mock(PasswordEncoder.class);
        var service = new TechnicianSelfService(users, technicians, categories,
                null, null, null, jwt, otp, passwords, null, null, null);
        when(users.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(categories.findByCategoryName("Plumbing")).thenReturn(Optional.of(new Category()));
        when(passwords.encode(any())).thenReturn("hashed");
        var req = new TechnicianRegisterRequest();
        req.setFirstName("Test"); req.setLastName("Technician");
        req.setEmail("test@example.com"); req.setPhoneNumber("012345678");
        req.setPassword("secret123"); req.setCategory("Plumbing"); req.setServiceArea("Phnom Penh");
        assertThrows(IllegalArgumentException.class, () -> service.register(req));
        verify(users, never()).save(any());
        req.setOtpCode("12bad");
        assertThrows(IllegalArgumentException.class, () -> service.register(req));
        req.setOtpCode("123456");
        assertThrows(IllegalArgumentException.class, () -> service.register(req));
        req.setIdCardBase64(Base64.getEncoder().encodeToString(image()));
        assertThrows(IllegalArgumentException.class, () -> service.register(req));
        verify(users, never()).save(any());
        req.setFacePhotoBase64("dGV4dA==");
        assertThrows(IllegalArgumentException.class, () -> service.register(req));
        verify(users, never()).save(any());
        req.setFacePhotoBase64(Base64.getEncoder().encodeToString(image()));
        assertThrows(com.api.exception.InvalidCredentialsException.class, () -> service.register(req));
        verify(users, never()).save(any());
        verify(technicians, never()).save(any());
        when(otp.verify("012345678", "123456")).thenReturn(true);
        service.register(req);
        var saved = org.mockito.ArgumentCaptor.forClass(Technician.class);
        verify(technicians).save(saved.capture());
        assertEquals("PENDING", saved.getValue().getApprovalStatus());
        assertFalse(saved.getValue().isVerified());
        assertArrayEquals(image(), saved.getValue().getIdCard());
        assertArrayEquals(image(), saved.getValue().getFacePhoto());
        verify(otp, times(2)).verify("012345678", "123456");
    }

    @Test
    void idCardEndpointRequiresAdminAndDisablesCaching() throws Exception {
        var service = mock(AdminService.class);
        var controller = new AdminController(service);
        doThrow(new ForbiddenException("Admin required")).when(service).requireAdmin(null);
        assertThrows(ForbiddenException.class, () -> controller.getIdCard(null, 1L));
        verify(service, never()).getTechnicianIdCard(any());
        when(service.getTechnicianIdCard(1L)).thenReturn(image());
        var response = controller.getIdCard("Bearer admin", 1L);
        assertEquals("no-store", response.getHeaders().getFirst("Cache-Control"));
        assertEquals("image/png", response.getHeaders().getFirst("Content-Type"));
        assertArrayEquals(image(), response.getBody());
        assertEquals(404, controller.getIdCard("Bearer admin", 2L).getStatusCode().value());
    }

    @Test
    void facePhotoEndpointRequiresAdminAndDisablesCaching() throws Exception {
        var service = mock(AdminService.class);
        var controller = new AdminController(service);
        doThrow(new ForbiddenException("Admin required")).when(service).requireAdmin(null);
        assertThrows(ForbiddenException.class, () -> controller.getFacePhoto(null, 1L));
        verify(service, never()).getTechnicianFacePhoto(any());
        when(service.getTechnicianFacePhoto(1L)).thenReturn(image());
        var response = controller.getFacePhoto("Bearer admin", 1L);
        assertEquals("no-store", response.getHeaders().getFirst("Cache-Control"));
        assertEquals("image/png", response.getHeaders().getFirst("Content-Type"));
        assertArrayEquals(image(), response.getBody());
        assertEquals(404, controller.getFacePhoto("Bearer admin", 2L).getStatusCode().value());
    }

    @Test
    void entitySerializationDoesNotExposeIdCard() throws Exception {
        var tech = new Technician();
        tech.setIdCard(image());
        tech.setFacePhoto(image());
        String json = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(tech);
        assertFalse(json.contains("idCard"));
        assertFalse(json.contains("facePhoto"));
    }
}
