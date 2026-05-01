package com.example.template.support.error;

public enum ErrorCode {
    // Generic
    NOT_FOUND,
    INTERNAL_ERROR,
    VALIDATION_FAILED,
    // DDD/order-specific (R1 C-02 / CX-4)
    INVARIANT_VIOLATION,
    INVALID_STATUS_TRANSITION,
    CONCURRENT_UPDATE
}
