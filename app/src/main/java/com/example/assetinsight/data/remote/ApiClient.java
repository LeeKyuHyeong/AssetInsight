package com.example.assetinsight.data.remote;

import android.content.Context;

import com.example.assetinsight.BuildConfig;
import com.example.assetinsight.data.remote.api.AuthApi;
import com.example.assetinsight.data.remote.api.SyncApi;
import com.example.assetinsight.data.remote.interceptor.AuthInterceptor;

import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Retrofit API 클라이언트
 */
public class ApiClient {

    private static volatile ApiClient INSTANCE;

    private final Retrofit retrofit;
    private final TokenManager tokenManager;

    private AuthApi authApi;
    private SyncApi syncApi;

    private ApiClient(Context context) {
        this.tokenManager = new TokenManager(context);

        OkHttpClient.Builder httpBuilder = new OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .addInterceptor(new AuthInterceptor(tokenManager));

        // Debug 빌드에서만 로깅
        if (BuildConfig.DEBUG) {
            HttpLoggingInterceptor loggingInterceptor = new HttpLoggingInterceptor();
            loggingInterceptor.setLevel(HttpLoggingInterceptor.Level.BODY);
            httpBuilder.addInterceptor(loggingInterceptor);
        }

        this.retrofit = new Retrofit.Builder()
                .baseUrl(BuildConfig.API_BASE_URL)
                .client(httpBuilder.build())
                .addConverterFactory(GsonConverterFactory.create())
                .build();
    }

    public static ApiClient getInstance(Context context) {
        if (INSTANCE == null) {
            synchronized (ApiClient.class) {
                if (INSTANCE == null) {
                    INSTANCE = new ApiClient(context.getApplicationContext());
                }
            }
        }
        return INSTANCE;
    }

    public AuthApi getAuthApi() {
        if (authApi == null) {
            authApi = retrofit.create(AuthApi.class);
        }
        return authApi;
    }

    public SyncApi getSyncApi() {
        if (syncApi == null) {
            syncApi = retrofit.create(SyncApi.class);
        }
        return syncApi;
    }

    public TokenManager getTokenManager() {
        return tokenManager;
    }

    public Retrofit getRetrofit() {
        return retrofit;
    }
}
