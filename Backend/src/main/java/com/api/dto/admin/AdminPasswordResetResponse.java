package com.api.dto.admin;

/** Payload for {@code POST /api/admin/technicians/{id}/reset-password}. The
 *  plaintext temporary password is only ever returned here, to the admin who
 *  triggered the reset - it isn't stored anywhere and there's no email/SMS
 *  delivery wired up in this project, so the admin relays it to the
 *  technician directly. */
public class AdminPasswordResetResponse {

    private String temporaryPassword;

    public String getTemporaryPassword() {
        return temporaryPassword;
    }

    public void setTemporaryPassword(String temporaryPassword) {
        this.temporaryPassword = temporaryPassword;
    }
}
