package {{BASE_PACKAGE}}.support.response;

import {{BASE_PACKAGE}}.support.error.ErrorType;
import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private final ResultType result;
    private final T data;
    private final String message;
    private final String code;

    private ApiResponse(ResultType result, T data, String message, String code) {
        this.result = result;
        this.data = data;
        this.message = message;
        this.code = code;
    }

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(ResultType.SUCCESS, data, null, null);
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(ResultType.SUCCESS, data, message, null);
    }

    public static ApiResponse<Void> error(ErrorType errorType) {
        return new ApiResponse<>(ResultType.ERROR, null, errorType.getMessage(),
            errorType.getCode().name());
    }

    public static ApiResponse<Void> error(ErrorType errorType, String message) {
        return new ApiResponse<>(ResultType.ERROR, null, message,
            errorType.getCode().name());
    }

    public ResultType getResult() { return result; }
    public T getData() { return data; }
    public String getMessage() { return message; }
    public String getCode() { return code; }
}
