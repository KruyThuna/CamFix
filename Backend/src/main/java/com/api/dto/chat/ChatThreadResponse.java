package com.api.dto.chat;

/** One row in the caller's chat inbox - one per booking that has an assigned
 *  technician (a thread exists whether or not anyone has said anything yet). */
public class ChatThreadResponse {

    private Long jobId;
    private String category;
    private String status;
    private String otherPartyName;
    private String lastMessage;
    private String lastMessageAt;
    private boolean lastMessageMine;

    public Long getJobId() {
        return jobId;
    }

    public void setJobId(Long jobId) {
        this.jobId = jobId;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getOtherPartyName() {
        return otherPartyName;
    }

    public void setOtherPartyName(String otherPartyName) {
        this.otherPartyName = otherPartyName;
    }

    public String getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(String lastMessage) {
        this.lastMessage = lastMessage;
    }

    public String getLastMessageAt() {
        return lastMessageAt;
    }

    public void setLastMessageAt(String lastMessageAt) {
        this.lastMessageAt = lastMessageAt;
    }

    public boolean isLastMessageMine() {
        return lastMessageMine;
    }

    public void setLastMessageMine(boolean lastMessageMine) {
        this.lastMessageMine = lastMessageMine;
    }
}
