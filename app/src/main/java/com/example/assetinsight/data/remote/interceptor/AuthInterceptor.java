package com.example.assetinsight.data.remote.interceptor;

import androidx.annotation.NonNull;

import com.example.assetinsight.data.remote.TokenManager;

import java.io.IOException;

import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;

/**
 * JWT 토큰을 요청 헤더에 자동 추가하는 인터셉터
 */
public class AuthInterceptor implements Interceptor {

    private final TokenManager tokenManager;

    public AuthInterceptor(TokenManager tokenManager) {
        this.tokenManager = tokenManager;
    }

    @NonNull
    @Override
    public Response intercept(@NonNull Chain chain) throws IOException {
        Request originalRequest = chain.request();

        // auth 경로는 토큰 추가하지 않음
        String path = originalRequest.url().encodedPath();
        if (path.contains("/auth/")) {
            return chain.proceed(originalRequest);
        }

        String accessToken = tokenManager.getAccessToken();
        if (accessToken == null || accessToken.isEmpty()) {
            return chain.proceed(originalRequest);
        }

        Request newRequest = originalRequest.newBuilder()
                .header("Authorization", "Bearer " + accessToken)
                .build();

        return chain.proceed(newRequest);
    }
}
