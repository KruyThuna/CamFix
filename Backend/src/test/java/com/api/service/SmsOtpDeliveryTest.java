package com.api.service;

import com.api.config.SmsConfig;
import com.api.service.mail.EmailSender;
import com.api.service.sms.LogSmsSender;
import com.api.service.sms.SmsSender;
import com.api.exception.SmsDeliveryException;
import java.util.concurrent.atomic.AtomicReference;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SmsOtpDeliveryTest {
    private static String code(String message) {
        var match = Pattern.compile("\\b[0-9]{6}\\b").matcher(message);
        assertTrue(match.find());
        return match.group();
    }

    @Test
    void sendsToCambodianNumberWithoutReturningCodeAndAllowsOnlyOneUse() {
        var destination = new AtomicReference<String>();
        var sent = new AtomicReference<String>();
        SmsSender sms = (phone, message) -> { destination.set(phone); sent.set(code(message)); };
        var service = new OtpService(sms, mock(EmailSender.class), 300, 5, true);
        assertNull(service.issuePhone("012345678"));
        assertEquals("+85512345678", destination.get());
        assertTrue(service.verify("012345678", sent.get()));
        assertFalse(service.verify("012345678", sent.get()));
    }

    @Test
    void failedDeliveryDoesNotCreateUsableCodeEvenInDevMode() {
        var attempted = new AtomicReference<String>();
        SmsSender sms = (phone, message) -> {
            attempted.set(code(message));
            throw new IllegalStateException("provider error containing private data");
        };
        var service = new OtpService(sms, mock(EmailSender.class), 300, 5, true);
        var failure = assertThrows(SmsDeliveryException.class, () -> service.issuePhone("+85512345678"));
        assertFalse(failure.getMessage().contains("private data"));
        assertFalse(service.verify("+85512345678", attempted.get()));
    }

    @Test
    void missingProviderUsesDevelopmentFallbackAndReturnsUsableCode() {
        var sms = new SmsConfig().smsSender("", "", "", "");
        assertInstanceOf(LogSmsSender.class, sms);
        var service = new OtpService(sms, mock(EmailSender.class), 300, 5, true);
        var code = service.issuePhone("012345678");
        assertNotNull(code);
        assertTrue(code.matches("[0-9]{6}"));
        assertTrue(service.verify("012345678", code));
        assertFalse(service.verify("012345678", code));
    }

    @Test
    void developmentFallbackDoesNotReturnCodeWhenExposureIsDisabled() {
        var sms = new SmsConfig().smsSender("", "", "", "");
        var service = new OtpService(sms, mock(EmailSender.class), 300, 5, false);
        assertNull(service.issuePhone("012345678"));
    }

    @Test
    void invalidNumberDoesNotCallProvider() {
        var sms = mock(SmsSender.class);
        var service = new OtpService(sms, mock(EmailSender.class), 300, 5, false);
        assertThrows(IllegalArgumentException.class, () -> service.issuePhone("123"));
        verifyNoInteractions(sms);
    }
}
