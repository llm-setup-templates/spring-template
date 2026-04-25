package {{BASE_PACKAGE}}.core.api.support;

import {{BASE_PACKAGE}}.support.error.CoreException;
import {{BASE_PACKAGE}}.support.error.ErrorType;
import {{BASE_PACKAGE}}.support.response.ApiResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiControllerAdvice {
    private static final Logger log = LoggerFactory.getLogger(ApiControllerAdvice.class);

    @ExceptionHandler(CoreException.class)
    public ResponseEntity<ApiResponse<Void>> handleCoreException(CoreException e) {
        ErrorType errorType = e.getErrorType();
        return ResponseEntity.status(errorType.getStatus())
            .body(ApiResponse.error(errorType, e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception e) {
        log.error("Unexpected error", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error(ErrorType.INTERNAL, "Internal server error"));
    }
}
