package com.example.assetinsight.data.remote.dto;

import com.google.gson.annotations.SerializedName;

public class AuthDto {

    // ========== Request DTOs ==========

    public static class SignUpRequest {
        @SerializedName("email")
        public String email;

        @SerializedName("password")
        public String password;

        @SerializedName("name")
        public String name;

        public SignUpRequest(String email, String password, String name) {
            this.email = email;
            this.password = password;
            this.name = name;
        }
    }

    public static class LoginRequest {
        @SerializedName("email")
        public String email;

        @SerializedName("password")
        public String password;

        @SerializedName("deviceInfo")
        public String deviceInfo;

        public LoginRequest(String email, String password, String deviceInfo) {
            this.email = email;
            this.password = password;
            this.deviceInfo = deviceInfo;
        }
    }

    public static class OAuthLoginRequest {
        @SerializedName("token")
        public String token;

        @SerializedName("deviceInfo")
        public String deviceInfo;

        public OAuthLoginRequest(String token, String deviceInfo) {
            this.token = token;
            this.deviceInfo = deviceInfo;
        }
    }

    public static class RefreshTokenRequest {
        @SerializedName("refreshToken")
        public String refreshToken;

        public RefreshTokenRequest(String refreshToken) {
            this.refreshToken = refreshToken;
        }
    }

    // ========== Response DTOs ==========

    public static class AuthResponse {
        @SerializedName("userId")
        public String userId;

        @SerializedName("email")
        public String email;

        @SerializedName("name")
        public String name;

        @SerializedName("accessToken")
        public String accessToken;

        @SerializedName("refreshToken")
        public String refreshToken;

        @SerializedName("expiresIn")
        public long expiresIn;
    }
}
