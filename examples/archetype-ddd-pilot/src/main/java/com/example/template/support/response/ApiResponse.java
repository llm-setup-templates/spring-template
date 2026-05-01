package com.example.template.support.response;

import com.example.template.support.error.ErrorCode;
import com.example.template.support.error.ErrorType;

public record ApiResponse<T>(ResultType result, T data, ErrorBody error) {

    public enum ResultType { SUCCESS, ERROR }

    public record ErrorBody(ErrorCode code, String message) {}

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(ResultType.SUCCESS, data, null);
    }

    public static <T> ApiResponse<T> success() {
        return new ApiResponse<>(ResultType.SUCCESS, null, null);
    }

    public static <T> ApiResponse<T> error(ErrorType errorType) {
        return error(errorType, errorType.getDefaultMessage());
    }

    public static <T> ApiResponse<T> error(ErrorType errorType, String message) {
        return new ApiResponse<>(ResultType.ERROR, null,
            new ErrorBody(errorType.getCode(), message));
    }
}
