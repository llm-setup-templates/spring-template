package com.example.template.support.error;

import org.springframework.http.HttpStatus;

public enum ErrorType {
    // Generic
    NOT_FOUND(HttpStatus.NOT_FOUND, ErrorCode.NOT_FOUND, "Resource not found"),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_ERROR, "Internal server error"),
    VALIDATION_FAILED(HttpStatus.BAD_REQUEST, ErrorCode.VALIDATION_FAILED, "Validation failed"),
    // DDD/order-specific (R1 C-02 / CX-4: HttpStatus mapping)
    INVARIANT_VIOLATION(HttpStatus.BAD_REQUEST, ErrorCode.INVARIANT_VIOLATION, "Domain invariant violated"),
    INVALID_STATUS_TRANSITION(HttpStatus.BAD_REQUEST, ErrorCode.INVALID_STATUS_TRANSITION, "Invalid status transition"),
    CONCURRENT_UPDATE(HttpStatus.CONFLICT, ErrorCode.CONCURRENT_UPDATE, "Concurrent update detected");

    private final HttpStatus status;
    private final ErrorCode code;
    private final String defaultMessage;

    ErrorType(HttpStatus status, ErrorCode code, String defaultMessage) {
        this.status = status;
        this.code = code;
        this.defaultMessage = defaultMessage;
    }

    public HttpStatus getStatus() { return status; }
    public ErrorCode getCode() { return code; }
    public String getDefaultMessage() { return defaultMessage; }
}
