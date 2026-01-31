package com.example.assetinsight.ui.auth;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.assetinsight.MainActivity;
import com.example.assetinsight.R;
import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.local.entity.UserProfile;
import com.example.assetinsight.data.repository.AuthRepository;
import com.example.assetinsight.databinding.ActivityProfileSwitchBinding;
import com.example.assetinsight.service.SyncWorker;
import com.example.assetinsight.util.DatabaseKeyManager;

import java.util.ArrayList;
import java.util.List;

public class ProfileSwitchActivity extends AppCompatActivity {

    private ActivityProfileSwitchBinding binding;
    private AuthRepository authRepository;
    private ProfileAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);

        binding = ActivityProfileSwitchBinding.inflate(getLayoutInflater());
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

        setupUI();
        loadProfiles();
    }

    private void setupUI() {
        binding.toolbar.setNavigationOnClickListener(v -> finish());

        adapter = new ProfileAdapter(new ArrayList<>(), this::onProfileSelected);
        binding.recyclerProfiles.setLayoutManager(new LinearLayoutManager(this));
        binding.recyclerProfiles.setAdapter(adapter);

        binding.btnAddAccount.setOnClickListener(v -> {
            startActivity(new Intent(this, LoginActivity.class));
        });
    }

    private void loadProfiles() {
        binding.progressBar.setVisibility(View.VISIBLE);

        authRepository.getProfiles(new AuthRepository.DataCallback<List<UserProfile>>() {
            @Override
            public void onSuccess(List<UserProfile> profiles) {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    adapter.setProfiles(profiles);

                    if (profiles.isEmpty()) {
                        binding.tvEmptyMessage.setVisibility(View.VISIBLE);
                    } else {
                        binding.tvEmptyMessage.setVisibility(View.GONE);
                    }
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    Toast.makeText(ProfileSwitchActivity.this, message, Toast.LENGTH_SHORT).show();
                });
            }
        });
    }

    private void onProfileSelected(UserProfile profile) {
        if (profile.isActive()) {
            // Already active
            finish();
            return;
        }

        new AlertDialog.Builder(this)
                .setTitle("프로필 전환")
                .setMessage(profile.getName() + " 계정으로 전환하시겠습니까?\n\n기존 로컬 데이터는 유지되지 않습니다.")
                .setPositiveButton("전환", (dialog, which) -> switchToProfile(profile))
                .setNegativeButton("취소", null)
                .show();
    }

    private void switchToProfile(UserProfile profile) {
        binding.progressBar.setVisibility(View.VISIBLE);

        authRepository.switchProfile(profile.getId(), new AuthRepository.SimpleCallback() {
            @Override
            public void onSuccess() {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    Toast.makeText(ProfileSwitchActivity.this,
                            profile.getName() + " 계정으로 전환되었습니다", Toast.LENGTH_SHORT).show();

                    // 동기화 시작
                    SyncWorker.enqueueOneTime(ProfileSwitchActivity.this);

                    // Navigate to main
                    Intent intent = new Intent(ProfileSwitchActivity.this, MainActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                });
            }

            @Override
            public void onError(String message) {
                runOnUiThread(() -> {
                    binding.progressBar.setVisibility(View.GONE);
                    Toast.makeText(ProfileSwitchActivity.this, message, Toast.LENGTH_SHORT).show();
                });
            }
        });
    }

    // Profile Adapter
    private static class ProfileAdapter extends RecyclerView.Adapter<ProfileAdapter.ViewHolder> {
        private List<UserProfile> profiles;
        private final OnProfileClickListener listener;

        interface OnProfileClickListener {
            void onProfileClick(UserProfile profile);
        }

        ProfileAdapter(List<UserProfile> profiles, OnProfileClickListener listener) {
            this.profiles = profiles;
            this.listener = listener;
        }

        void setProfiles(List<UserProfile> profiles) {
            this.profiles = profiles;
            notifyDataSetChanged();
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.item_profile, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            UserProfile profile = profiles.get(position);
            holder.bind(profile, listener);
        }

        @Override
        public int getItemCount() {
            return profiles.size();
        }

        static class ViewHolder extends RecyclerView.ViewHolder {
            private final TextView tvName;
            private final TextView tvEmail;
            private final TextView tvProvider;
            private final ImageView ivActive;

            ViewHolder(@NonNull View itemView) {
                super(itemView);
                tvName = itemView.findViewById(R.id.tvName);
                tvEmail = itemView.findViewById(R.id.tvEmail);
                tvProvider = itemView.findViewById(R.id.tvProvider);
                ivActive = itemView.findViewById(R.id.ivActive);
            }

            void bind(UserProfile profile, OnProfileClickListener listener) {
                tvName.setText(profile.getName());
                tvEmail.setText(profile.getEmail());

                String providerText;
                switch (profile.getProvider()) {
                    case "GOOGLE":
                        providerText = "Google";
                        break;
                    case "KAKAO":
                        providerText = "Kakao";
                        break;
                    case "NAVER":
                        providerText = "Naver";
                        break;
                    default:
                        providerText = "이메일";
                }
                tvProvider.setText(providerText);

                ivActive.setVisibility(profile.isActive() ? View.VISIBLE : View.GONE);

                itemView.setOnClickListener(v -> listener.onProfileClick(profile));
            }
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        binding = null;
    }
}
