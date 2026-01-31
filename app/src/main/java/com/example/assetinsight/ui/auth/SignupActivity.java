package com.example.assetinsight.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Patterns;
import android.view.View;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.assetinsight.MainActivity;
import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.repository.AuthRepository;
import com.example.assetinsight.data.remote.dto.AuthDto;
import com.example.assetinsight.databinding.ActivitySignupBinding;
import com.example.assetinsight.service.SyncWorker;
import com.example.assetinsight.util.DatabaseKeyManager;

public class SignupActivity extends AppCompatActivity {

    private ActivitySignupBinding binding;
    private AuthRepository authRepository;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);

        binding = ActivitySignupBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        ViewCompat.setOnApplyWindowInsetsListener(binding.main, (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // Initialize repository
        AppDatabase database = AppDatabase.getInstance(this,
                DatabaseKeyManager.getKey());
        authRepository = new AuthRepository(this, database);

        setupClickListeners();
    }

    private void setupClickListeners() {
        binding.btnSignUp.setOnClickListener(v -> performSignUp());

        binding.tvLogin.setOnClickListener(v -> {
            finish();
        });

        binding.toolbar.setNavigationOnClickListener(v -> finish());
    }

    private void performSignUp() {
        String name = binding.etName.getText().toString().trim();
        String email = binding.etEmail.getText().toString().trim();
        String password = binding.etPassword.getText().toString();
        String confirmPassword = binding.etConfirmPassword.getText().toString();

        // Validation
        boolean isValid = true;

        if (TextUtils.isEmpty(name)) {
            binding.tilName.setError("이름을 입력하세요");
            isValid = false;
        } else if (name.length() < 2) {
            binding.tilName.setError("이름은 2자 이상이어야 합니다");
            isValid = false;
        } else {
            binding.tilName.setError(null);
        }

        if (TextUtils.isEmpty(email)) {
            binding.tilEmail.setError("이메일을 입력하세요");
            isValid = false;
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            binding.tilEmail.setError("올바른 이메일 형식이 아닙니다");
            isValid = false;
        } else {
            binding.tilEmail.setError(null);
        }

        if (TextUtils.isEmpty(password)) {
            binding.tilPassword.setError("비밀번호를 입력하세요");
            isValid = false;
        } else if (password.length() < 8) {
            binding.tilPassword.setError("비밀번호는 8자 이상이어야 합니다");
            isValid = false;
        } else {
            binding.tilPassword.setError(null);
        }

        if (TextUtils.isEmpty(confirmPassword)) {
            binding.tilConfirmPassword.setError("비밀번호 확인을 입력하세요");
            isValid = false;
        } else if (!password.equals(confirmPassword)) {
            binding.tilConfirmPassword.setError("비밀번호가 일치하지 않습니다");
            isValid = false;
        } else {
            binding.tilConfirmPassword.setError(null);
        }

        if (!isValid) {
            return;
        }

        showLoading(true);

        authRepository.signUp(email, password, name, new AuthRepository.AuthCallback() {
            @Override
            public void onSuccess(AuthDto.AuthResponse response) {
                runOnUiThread(() -> {
                    showLoading(false);
                    Toast.makeText(SignupActivity.this, "회원가입 성공", Toast.LENGTH_SHORT).show();

                    // 백그라운드 동기화 시작
                    SyncWorker.enqueueOneTime(SignupActivity.this);

                    // Navigate to main
                    Intent intent = new Intent(SignupActivity.this, MainActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    showLoading(false);
                    Toast.makeText(SignupActivity.this, message, Toast.LENGTH_SHORT).show();
                });
            }
        });
    }

    private void showLoading(boolean show) {
        binding.progressBar.setVisibility(show ? View.VISIBLE : View.GONE);
        binding.btnSignUp.setEnabled(!show);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        binding = null;
    }
}
