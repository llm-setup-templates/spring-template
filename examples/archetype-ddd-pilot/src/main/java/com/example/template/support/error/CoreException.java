package com.example.template.support.error;

public class CoreException extends RuntimeException {

    private final ErrorType errorType;

    public CoreException(ErrorType errorType) {
        super(errorType.getDefaultMessage());
        this.errorType = errorType;
    }

    public CoreException(ErrorType errorType, String message) {
        super(message);
        this.errorType = errorType;
    }

    public ErrorType getErrorType() { return errorType; }
}
