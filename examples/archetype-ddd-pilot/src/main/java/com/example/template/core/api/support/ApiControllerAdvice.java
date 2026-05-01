package com.example.template.core.api.support;

import com.example.template.order.domain.InvalidStatusTransitionException;
import com.example.template.order.domain.InvariantViolationException;
import com.example.template.support.error.CoreException;
import com.example.template.support.error.ErrorType;
import com.example.template.support.response.ApiResponse;

import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiControllerAdvice {

    @ExceptionHandler(CoreException.class)
    public ResponseEntity<ApiResponse<Void>> handleCoreException(CoreException ex) {
        ErrorType type = ex.getErrorType();
        return ResponseEntity.status(type.getStatus())
            .body(ApiResponse.error(type, ex.getMessage()));
    }

    @ExceptionHandler(InvariantViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleInvariantViolation(InvariantViolationException ex) {
        return ResponseEntity.status(ErrorType.INVARIANT_VIOLATION.getStatus())
            .body(ApiResponse.error(ErrorType.INVARIANT_VIOLATION, ex.getMessage()));
    }

    @ExceptionHandler(InvalidStatusTransitionException.class)
    public ResponseEntity<ApiResponse<Void>> handleInvalidStatusTransition(InvalidStatusTransitionException ex) {
        return ResponseEntity.status(ErrorType.INVALID_STATUS_TRANSITION.getStatus())
            .body(ApiResponse.error(ErrorType.INVALID_STATUS_TRANSITION, ex.getMessage()));
    }

    // R4 R4-M3 / D6: Spring Data optimistic lock failure -- distinct from jakarta.persistence.OptimisticLockException
    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    public ResponseEntity<ApiResponse<Void>> handleConcurrentUpdate(ObjectOptimisticLockingFailureException ex) {
        return ResponseEntity.status(ErrorType.CONCURRENT_UPDATE.getStatus())
            .body(ApiResponse.error(ErrorType.CONCURRENT_UPDATE, "Order was updated by another transaction"));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getAllErrors().stream()
            .findFirst()
            .map(err -> err.getDefaultMessage())
            .orElse("Validation failed");
        return ResponseEntity.status(ErrorType.VALIDATION_FAILED.getStatus())
            .body(ApiResponse.error(ErrorType.VALIDATION_FAILED, message));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiResponse<Void>> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(ErrorType.VALIDATION_FAILED.getStatus())
            .body(ApiResponse.error(ErrorType.VALIDATION_FAILED, ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGeneric(Exception ex) {
        return ResponseEntity.status(ErrorType.INTERNAL_ERROR.getStatus())
            .body(ApiResponse.error(ErrorType.INTERNAL_ERROR, ex.getMessage()));
    }
}
