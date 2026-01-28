package com.example.assetinsight.util;

import android.content.Context;
import android.os.Build;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

import java.util.concurrent.Executor;

/**
 * 보안 관련 유틸리티 클래스
 * - 생체 인증 (BiometricPrompt)
 * - 화면 보안 (FLAG_SECURE)
 */
public class SecurityHelper {

    private final Context context;

    public SecurityHelper(Context context) {
        this.context = context.getApplicationContext();
    }

    /**
     * 생체 인증 또는 기기 잠금 인증 가능 여부 확인
     * @return BiometricStatus 상태값
     */
    public BiometricStatus checkBiometricAvailability() {
        BiometricManager biometricManager = BiometricManager.from(context);

        // 생체 인증 + 기기 잠금(PIN/패턴/비밀번호) 모두 허용
        int result = biometricManager.canAuthenticate(
                BiometricManager.Authenticators.BIOMETRIC_WEAK |
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
        );

        switch (result) {
            case BiometricManager.BIOMETRIC_SUCCESS:
                return BiometricStatus.AVAILABLE;
            case BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE:
                // 생체 인증 하드웨어 없어도 기기 잠금으로 인증 가능
                return BiometricStatus.AVAILABLE;
            case BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE:
                return BiometricStatus.HARDWARE_UNAVAILABLE;
            case BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED:
                return BiometricStatus.NOT_ENROLLED;
            case BiometricManager.BIOMETRIC_ERROR_SECURITY_UPDATE_REQUIRED:
                return BiometricStatus.SECURITY_UPDATE_REQUIRED;
            default:
                return BiometricStatus.UNKNOWN;
        }
    }

    /**
     * 생체 인증 또는 기기 잠금 인증 실행
     * @param activity FragmentActivity
     * @param title 프롬프트 제목
     * @param subtitle 프롬프트 부제목
     * @param negativeButtonText 취소 버튼 텍스트 (DEVICE_CREDENTIAL 사용 시 무시됨)
     * @param callback 인증 결과 콜백
     */
    public void authenticate(
            @NonNull FragmentActivity activity,
            @NonNull String title,
            @NonNull String subtitle,
            @NonNull String negativeButtonText,
            @NonNull AuthenticationCallback callback
    ) {
        Executor executor = ContextCompat.getMainExecutor(activity);

        BiometricPrompt biometricPrompt = new BiometricPrompt(activity, executor,
                new BiometricPrompt.AuthenticationCallback() {
                    @Override
                    public void onAuthenticationError(int errorCode, @NonNull CharSequence errString) {
                        super.onAuthenticationError(errorCode, errString);
                        callback.onError(errorCode, errString.toString());
                    }

                    @Override
                    public void onAuthenticationSucceeded(@NonNull BiometricPrompt.AuthenticationResult result) {
                        super.onAuthenticationSucceeded(result);
                        callback.onSuccess();
                    }

                    @Override
                    public void onAuthenticationFailed() {
                        super.onAuthenticationFailed();
                        callback.onFailed();
                    }
                });

        // 생체 인증 + PIN/패턴/비밀번호 모두 허용
        // DEVICE_CREDENTIAL 사용 시 setNegativeButtonText() 사용 불가
        BiometricPrompt.PromptInfo promptInfo = new BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setAllowedAuthenticators(
                        BiometricManager.Authenticators.BIOMETRIC_WEAK |
                        BiometricManager.Authenticators.DEVICE_CREDENTIAL
                )
                .build();

        biometricPrompt.authenticate(promptInfo);
    }

    /**
     * 화면 보안 활성화 (최근 앱 목록에서 내용 숨김)
     * FLAG_SECURE: 스크린샷 방지 및 최근 앱에서 빈 화면 표시
     */
    public static void enableScreenSecurity(FragmentActivity activity) {
        activity.getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
        );
    }

    /**
     * 화면 보안 비활성화
     */
    public static void disableScreenSecurity(FragmentActivity activity) {
        activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_SECURE);
    }

    /**
     * 생체 인증 가능 상태
     */
    public enum BiometricStatus {
        AVAILABLE,              // 사용 가능
        NO_HARDWARE,           // 생체 인증 하드웨어 없음
        HARDWARE_UNAVAILABLE,  // 하드웨어 일시적 사용 불가
        NOT_ENROLLED,          // 등록된 생체 정보 없음
        SECURITY_UPDATE_REQUIRED, // 보안 업데이트 필요
        UNKNOWN                // 알 수 없음
    }

    /**
     * 인증 결과 콜백 인터페이스
     */
    public interface AuthenticationCallback {
        void onSuccess();
        void onFailed();
        void onError(int errorCode, String errorMessage);
    }
}
