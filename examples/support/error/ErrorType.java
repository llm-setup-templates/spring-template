package com.example.demo.support.error;

import org.springframework.http.HttpStatus;

public enum ErrorType {
    NOT_FOUND(HttpStatus.NOT_FOUND, ErrorCode.USER_NOT_FOUND, "Resource not found"),
    CONFLICT(HttpStatus.CONFLICT, ErrorCode.DUPLICATE_EMAIL, "Resource already exists"),
    BAD_REQUEST(HttpStatus.BAD_REQUEST, ErrorCode.INVALID_INPUT, "Invalid input"),
    INTERNAL(HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_SERVER_ERROR, "Internal server error"),
    EXTERNAL(HttpStatus.BAD_GATEWAY, ErrorCode.EXTERNAL_API_FAILURE, "External service failure");

    private final HttpStatus status;
    private final ErrorCode code;
    private final String message;

    ErrorType(HttpStatus status, ErrorCode code, String message) {
        this.status = status;
        this.code = code;
        this.message = message;
    }

    public HttpStatus getStatus() { return status; }
    public ErrorCode getCode() { return code; }
    public String getMessage() { return message; }
}
