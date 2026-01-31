package com.example.assetinsight.data.remote.api;

import com.example.assetinsight.data.remote.dto.ApiResponse;
import com.example.assetinsight.data.remote.dto.AuthDto;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.POST;

/**
 * 인증 API 인터페이스
 */
public interface AuthApi {

    @POST("auth/signup")
    Call<ApiResponse<AuthDto.AuthResponse>> signUp(@Body AuthDto.SignUpRequest request);

    @POST("auth/login")
    Call<ApiResponse<AuthDto.AuthResponse>> login(@Body AuthDto.LoginRequest request);

    @POST("auth/refresh")
    Call<ApiResponse<AuthDto.AuthResponse>> refreshToken(@Body AuthDto.RefreshTokenRequest request);

    @POST("auth/logout")
    Call<ApiResponse<Void>> logout();

    @POST("auth/oauth/google")
    Call<ApiResponse<AuthDto.AuthResponse>> googleLogin(@Body AuthDto.OAuthLoginRequest request);

    @POST("auth/oauth/kakao")
    Call<ApiResponse<AuthDto.AuthResponse>> kakaoLogin(@Body AuthDto.OAuthLoginRequest request);

    @POST("auth/oauth/naver")
    Call<ApiResponse<AuthDto.AuthResponse>> naverLogin(@Body AuthDto.OAuthLoginRequest request);
}
