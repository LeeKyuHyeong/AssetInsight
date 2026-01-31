package com.example.assetinsight.data.remote;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

import timber.log.Timber;

/**
 * JWT 토큰 관리자
 * EncryptedSharedPreferences를 사용하여 토큰을 안전하게 저장
 */
public class TokenManager {

    private static final String PREFS_NAME = "asset_insight_tokens";
    private static final String KEY_ACCESS_TOKEN = "access_token";
    private static final String KEY_REFRESH_TOKEN = "refresh_token";
    private static final String KEY_USER_ID = "user_id";
    private static final String KEY_EMAIL = "email";
    private static final String KEY_NAME = "name";
    private static final String KEY_TOKEN_EXPIRY = "token_expiry";

    private final SharedPreferences prefs;

    public TokenManager(Context context) {
        SharedPreferences tempPrefs;
        try {
            MasterKey masterKey = new MasterKey.Builder(context)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build();

            tempPrefs = EncryptedSharedPreferences.create(
                    context,
                    PREFS_NAME,
                    masterKey,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            );
        } catch (Exception e) {
            Timber.e(e, "Failed to create encrypted prefs, using regular prefs");
            tempPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        }
        this.prefs = tempPrefs;
    }

    public void saveTokens(String userId, String email, String name,
                           String accessToken, String refreshToken, long expiresIn) {
        long expiryTime = System.currentTimeMillis() + expiresIn;
        prefs.edit()
                .putString(KEY_USER_ID, userId)
                .putString(KEY_EMAIL, email)
                .putString(KEY_NAME, name)
                .putString(KEY_ACCESS_TOKEN, accessToken)
                .putString(KEY_REFRESH_TOKEN, refreshToken)
                .putLong(KEY_TOKEN_EXPIRY, expiryTime)
                .apply();
    }

    public String getAccessToken() {
        return prefs.getString(KEY_ACCESS_TOKEN, null);
    }

    public String getRefreshToken() {
        return prefs.getString(KEY_REFRESH_TOKEN, null);
    }

    public String getUserId() {
        return prefs.getString(KEY_USER_ID, null);
    }

    public String getEmail() {
        return prefs.getString(KEY_EMAIL, null);
    }

    public String getName() {
        return prefs.getString(KEY_NAME, null);
    }

    public boolean isTokenExpired() {
        long expiryTime = prefs.getLong(KEY_TOKEN_EXPIRY, 0);
        // 만료 5분 전부터 만료된 것으로 처리
        return System.currentTimeMillis() > (expiryTime - 5 * 60 * 1000);
    }

    public boolean isLoggedIn() {
        return getAccessToken() != null && getUserId() != null;
    }

    public void clearTokens() {
        prefs.edit()
                .remove(KEY_ACCESS_TOKEN)
                .remove(KEY_REFRESH_TOKEN)
                .remove(KEY_USER_ID)
                .remove(KEY_EMAIL)
                .remove(KEY_NAME)
                .remove(KEY_TOKEN_EXPIRY)
                .apply();
    }

    public void updateAccessToken(String accessToken, long expiresIn) {
        long expiryTime = System.currentTimeMillis() + expiresIn;
        prefs.edit()
                .putString(KEY_ACCESS_TOKEN, accessToken)
                .putLong(KEY_TOKEN_EXPIRY, expiryTime)
                .apply();
    }
}
