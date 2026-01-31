package com.example.assetinsight.data.remote.dto;

import com.google.gson.annotations.SerializedName;

public class ApiResponse<T> {

    @SerializedName("success")
    public boolean success;

    @SerializedName("message")
    public String message;

    @SerializedName("data")
    public T data;

    @SerializedName("errorCode")
    public String errorCode;

    public boolean isSuccess() {
        return success;
    }

    public String getMessage() {
        return message != null ? message : "";
    }

    public T getData() {
        return data;
    }

    public String getErrorCode() {
        return errorCode;
    }
}
