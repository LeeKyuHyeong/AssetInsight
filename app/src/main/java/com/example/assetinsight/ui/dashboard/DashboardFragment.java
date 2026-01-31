package com.example.assetinsight.ui.dashboard;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import com.example.assetinsight.R;
import com.example.assetinsight.data.local.AppDatabase;
import com.example.assetinsight.data.local.AssetSnapshot;
import com.example.assetinsight.data.local.Category;
import com.example.assetinsight.data.repository.AssetRepository;
import com.example.assetinsight.databinding.FragmentDashboardBinding;
import com.example.assetinsight.ui.assetlist.AssetListActivity;
import com.example.assetinsight.ui.auth.LoginActivity;
import com.example.assetinsight.ui.auth.ProfileSwitchActivity;
import com.example.assetinsight.ui.backup.BackupRestoreActivity;
import com.example.assetinsight.ui.category.CategoryDetailActivity;
import com.example.assetinsight.ui.settings.SettingsActivity;
import com.example.assetinsight.util.DatabaseKeyManager;
import com.example.assetinsight.ui.category.CategoryManageActivity;
import com.example.assetinsight.data.remote.ApiClient;
import com.example.assetinsight.data.remote.TokenManager;
import com.example.assetinsight.data.repository.SyncRepository;
import com.example.assetinsight.service.SyncWorker;

import android.widget.Toast;

import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.formatter.PercentFormatter;
import com.github.mikephil.charting.utils.ColorTemplate;

import android.graphics.Color;
import android.widget.PopupMenu;

import java.text.NumberFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicLong;

public class DashboardFragment extends Fragment {

    private FragmentDashboardBinding binding;
    private AssetRepository repository;
    private CategoryAdapter categoryAdapter;

    private final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
    private final SimpleDateFormat displayDateFormat = new SimpleDateFormat("yyyy년 M월 d일", Locale.KOREA);
    private final NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(Locale.KOREA);
    private final NumberFormat percentFormat = NumberFormat.getInstance(Locale.KOREA);

    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    // 카테고리 ID -> 이름 매핑
    private final Map<String, String> categoryNames = new HashMap<>();

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        percentFormat.setMaximumFractionDigits(1);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        binding = FragmentDashboardBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        // TODO: DB 암호화 키 관리 - 현재는 임시 키 사용
        repository = new AssetRepository(requireContext(), DatabaseKeyManager.getKey());

        setupRecyclerView();
        setupCategoryManageButton();
        setupMenuButton();
        setupCharts();
        // 카테고리 이름 로드는 onResume에서 처리
    }

    private void setupCharts() {
        // 라인 차트 설정
        LineChart lineChart = binding.lineChart;
        lineChart.setDescription(null);
        lineChart.setDrawGridBackground(false);
        lineChart.setTouchEnabled(true);
        lineChart.setDragEnabled(true);
        lineChart.setScaleEnabled(false);
        lineChart.setPinchZoom(false);
        lineChart.getLegend().setEnabled(false);
        lineChart.getAxisRight().setEnabled(false);
        lineChart.getAxisLeft().setTextColor(ContextCompat.getColor(requireContext(),
                com.google.android.material.R.color.material_on_surface_emphasis_medium));
        lineChart.getXAxis().setPosition(XAxis.XAxisPosition.BOTTOM);
        lineChart.getXAxis().setTextColor(ContextCompat.getColor(requireContext(),
                com.google.android.material.R.color.material_on_surface_emphasis_medium));
        lineChart.getXAxis().setDrawGridLines(false);
        lineChart.setNoDataText(getString(R.string.dashboard_no_data));

        // 파이 차트 설정
        PieChart pieChart = binding.pieChart;
        pieChart.setDescription(null);
        pieChart.setUsePercentValues(true);
        pieChart.setDrawHoleEnabled(true);
        pieChart.setHoleRadius(50f);
        pieChart.setTransparentCircleRadius(55f);
        pieChart.setDrawEntryLabels(false);
        pieChart.getLegend().setEnabled(true);
        pieChart.getLegend().setTextColor(ContextCompat.getColor(requireContext(),
                com.google.android.material.R.color.material_on_surface_emphasis_medium));
        pieChart.setNoDataText(getString(R.string.dashboard_no_data));
    }

    private void setupMenuButton() {
        binding.btnMenu.setOnClickListener(v -> {
            PopupMenu popup = new PopupMenu(requireContext(), v);
            popup.getMenuInflater().inflate(R.menu.menu_dashboard, popup.getMenu());
            popup.setOnMenuItemClickListener(item -> {
                int itemId = item.getItemId();
                if (itemId == R.id.action_asset_list) {
                    Intent intent = new Intent(requireContext(), AssetListActivity.class);
                    startActivity(intent);
                    return true;
                } else if (itemId == R.id.action_backup) {
                    Intent intent = new Intent(requireContext(), BackupRestoreActivity.class);
                    startActivity(intent);
                    return true;
                } else if (itemId == R.id.action_sync) {
                    performSync();
                    return true;
                } else if (itemId == R.id.action_account) {
                    TokenManager tokenManager = ApiClient.getInstance(requireContext()).getTokenManager();
                    if (tokenManager.isLoggedIn()) {
                        Intent intent = new Intent(requireContext(), ProfileSwitchActivity.class);
                        startActivity(intent);
                    } else {
                        Intent intent = new Intent(requireContext(), LoginActivity.class);
                        startActivity(intent);
                    }
                    return true;
                } else if (itemId == R.id.action_settings) {
                    Intent intent = new Intent(requireContext(), SettingsActivity.class);
                    startActivity(intent);
                    return true;
                }
                return false;
            });
            popup.show();
        });
    }

    private void setupCategoryManageButton() {
        binding.btnCategoryManage.setOnClickListener(v -> {
            Intent intent = new Intent(requireContext(), CategoryManageActivity.class);
            startActivity(intent);
        });
    }

    private void loadCategoryNames(Runnable onComplete) {
        if (getContext() == null) {
            if (onComplete != null) onComplete.run();
            return;
        }
        executor.execute(() -> {
            if (getContext() == null) {
                if (onComplete != null) onComplete.run();
                return;
            }
            AppDatabase db = AppDatabase.getInstance(getContext(), DatabaseKeyManager.getKey());
            db.ensureDefaultCategories();
            List<Category> categories = db.categoryDao().getAllCategories();

            categoryNames.clear();
            for (Category category : categories) {
                categoryNames.put(category.getId(), category.getName());
            }
            if (onComplete != null) onComplete.run();
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        // 카테고리 이름 로드 후 대시보드 데이터 로드
        loadCategoryNames(this::loadDashboardData);
    }

    private void setupRecyclerView() {
        categoryAdapter = new CategoryAdapter();
        categoryAdapter.setOnCategoryClickListener(this::onCategoryClick);
        binding.rvCategories.setLayoutManager(new LinearLayoutManager(requireContext()));
        binding.rvCategories.setAdapter(categoryAdapter);
    }

    private void onCategoryClick(CategoryAssetItem item) {
        Intent intent = new Intent(requireContext(), CategoryDetailActivity.class);
        intent.putExtra(CategoryDetailActivity.EXTRA_CATEGORY_ID, item.getCategoryId());
        intent.putExtra(CategoryDetailActivity.EXTRA_CATEGORY_NAME, item.getCategoryName());
        startActivity(intent);
    }

    private void loadDashboardData() {
        String today = dateFormat.format(new Date());

        executor.execute(() -> {
            if (getContext() == null) return;

            // DB에서 직접 모든 스냅샷 가져오기
            AppDatabase db = AppDatabase.getInstance(getContext(), DatabaseKeyManager.getKey());
            List<AssetSnapshot> allSnapshots = db.assetSnapshotDao().getAllSnapshots();

            // 1. 전체 자산 총액 계산 (각 카테고리별 최신 데이터 합산)
            long totalAmount = calculateTotalAmount(allSnapshots, today);

            // 2. 인사이트 데이터 (1일, 1개월, 6개월, 1년 전)
            InsightData dayInsight = calculateInsightFromSnapshots(allSnapshots, today, -1, Calendar.DAY_OF_MONTH, totalAmount);
            InsightData monthInsight = calculateInsightFromSnapshots(allSnapshots, today, -1, Calendar.MONTH, totalAmount);
            InsightData sixMonthInsight = calculateInsightFromSnapshots(allSnapshots, today, -6, Calendar.MONTH, totalAmount);
            InsightData yearInsight = calculateInsightFromSnapshots(allSnapshots, today, -1, Calendar.YEAR, totalAmount);

            // 3. 카테고리별 자산
            List<CategoryAssetItem> categoryItems = loadCategoryAssetsFromSnapshots(allSnapshots, today, totalAmount);

            // 차트 데이터
            List<Entry> trendEntries = loadTrendDataFromSnapshots(allSnapshots);
            List<PieEntry> pieEntries = createPieEntries(categoryItems);

            // UI 업데이트
            if (getActivity() != null && isAdded()) {
                getActivity().runOnUiThread(() -> {
                    if (binding == null) return;
                    updateTotalAmount(totalAmount, today);
                    updateInsightCard(binding.tvDayChange, binding.tvDayPercent, dayInsight);
                    updateInsightCard(binding.tvMonthChange, binding.tvMonthPercent, monthInsight);
                    updateInsightCard(binding.tvSixMonthChange, binding.tvSixMonthPercent, sixMonthInsight);
                    updateInsightCard(binding.tvYearChange, binding.tvYearPercent, yearInsight);
                    updateCategoryList(categoryItems);
                    updateLineChart(trendEntries);
                    updatePieChart(pieEntries);
                });
            }
        });
    }

    private long calculateTotalAmount(List<AssetSnapshot> snapshots, String targetDate) {
        Map<String, AssetSnapshot> latestByCategory = new HashMap<>();

        for (AssetSnapshot snapshot : snapshots) {
            if (snapshot.getDate().compareTo(targetDate) <= 0) {
                String categoryId = snapshot.getCategoryId();
                AssetSnapshot existing = latestByCategory.get(categoryId);

                if (existing == null || snapshot.getDate().compareTo(existing.getDate()) > 0) {
                    latestByCategory.put(categoryId, snapshot);
                }
            }
        }

        long total = 0;
        for (AssetSnapshot snapshot : latestByCategory.values()) {
            total += snapshot.getAmount();
        }
        return total;
    }

    private InsightData calculateInsightFromSnapshots(List<AssetSnapshot> snapshots, String today, int amount, int field, long currentTotal) {
        Calendar cal = Calendar.getInstance();
        try {
            cal.setTime(dateFormat.parse(today));
        } catch (Exception e) {
            return InsightData.noData();
        }
        cal.add(field, amount);
        String pastDate = dateFormat.format(cal.getTime());

        long pastAmount = calculateTotalAmount(snapshots, pastDate);
        return new InsightData(currentTotal, pastAmount);
    }

    private List<CategoryAssetItem> loadCategoryAssetsFromSnapshots(List<AssetSnapshot> snapshots, String today, long totalAmount) {
        Map<String, AssetSnapshot> latestByCategory = new HashMap<>();

        for (AssetSnapshot snapshot : snapshots) {
            if (snapshot.getDate().compareTo(today) <= 0) {
                String categoryId = snapshot.getCategoryId();
                AssetSnapshot existing = latestByCategory.get(categoryId);

                if (existing == null || snapshot.getDate().compareTo(existing.getDate()) > 0) {
                    latestByCategory.put(categoryId, snapshot);
                }
            }
        }

        List<CategoryAssetItem> items = new ArrayList<>();
        for (AssetSnapshot snapshot : latestByCategory.values()) {
            String name = categoryNames.getOrDefault(snapshot.getCategoryId(), snapshot.getCategoryId());
            double percent = totalAmount > 0 ? ((double) snapshot.getAmount() / totalAmount) * 100 : 0;

            items.add(new CategoryAssetItem(
                    snapshot.getCategoryId(),
                    name,
                    snapshot.getAmount(),
                    snapshot.getDate(),
                    percent
            ));
        }

        // 금액 기준 내림차순 정렬
        items.sort((a, b) -> Long.compare(b.getAmount(), a.getAmount()));
        return items;
    }

    private List<Entry> loadTrendDataFromSnapshots(List<AssetSnapshot> snapshots) {
        List<Entry> entries = new ArrayList<>();

        Calendar cal = Calendar.getInstance();
        for (int i = 11; i >= 0; i--) {
            Calendar target = (Calendar) cal.clone();
            target.add(Calendar.MONTH, -i);
            target.set(Calendar.DAY_OF_MONTH, target.getActualMaximum(Calendar.DAY_OF_MONTH));
            String targetDate = dateFormat.format(target.getTime());

            long amount = calculateTotalAmount(snapshots, targetDate);
            entries.add(new Entry(11 - i, amount / 10000f)); // 만원 단위
        }

        return entries;
    }

    private List<Entry> loadTrendData() {
        List<Entry> entries = new ArrayList<>();

        // 최근 12개월간 월별 총 자산 추이
        Calendar cal = Calendar.getInstance();
        for (int i = 11; i >= 0; i--) {
            Calendar target = (Calendar) cal.clone();
            target.add(Calendar.MONTH, -i);
            target.set(Calendar.DAY_OF_MONTH, target.getActualMaximum(Calendar.DAY_OF_MONTH));
            String targetDate = dateFormat.format(target.getTime());

            AtomicLong amount = new AtomicLong(0);
            CountDownLatch latch = new CountDownLatch(1);

            repository.getTotalAmountAtDate(targetDate, amt -> {
                amount.set(amt);
                latch.countDown();
            });

            try {
                latch.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

            entries.add(new Entry(11 - i, amount.get() / 10000f)); // 만원 단위
        }

        return entries;
    }

    private List<PieEntry> createPieEntries(List<CategoryAssetItem> categoryItems) {
        List<PieEntry> entries = new ArrayList<>();

        for (CategoryAssetItem item : categoryItems) {
            if (item.getAmount() > 0) {
                entries.add(new PieEntry(item.getAmount(), item.getCategoryName()));
            }
        }

        return entries;
    }

    private void updateLineChart(List<Entry> entries) {
        if (entries.isEmpty() || binding == null) return;

        LineDataSet dataSet = new LineDataSet(entries, "");
        dataSet.setColor(ContextCompat.getColor(requireContext(), R.color.positive));
        dataSet.setLineWidth(2f);
        dataSet.setDrawCircles(true);
        dataSet.setCircleColor(ContextCompat.getColor(requireContext(), R.color.positive));
        dataSet.setCircleRadius(3f);
        dataSet.setDrawValues(false);
        dataSet.setMode(LineDataSet.Mode.CUBIC_BEZIER);
        dataSet.setDrawFilled(true);
        dataSet.setFillColor(ContextCompat.getColor(requireContext(), R.color.positive));
        dataSet.setFillAlpha(30);

        LineData lineData = new LineData(dataSet);
        binding.lineChart.setData(lineData);

        // X축 레이블 설정 (월)
        List<String> labels = new ArrayList<>();
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat monthFormat = new SimpleDateFormat("M월", Locale.KOREA);
        for (int i = 11; i >= 0; i--) {
            Calendar target = (Calendar) cal.clone();
            target.add(Calendar.MONTH, -i);
            labels.add(monthFormat.format(target.getTime()));
        }
        binding.lineChart.getXAxis().setValueFormatter(new IndexAxisValueFormatter(labels));
        binding.lineChart.getXAxis().setLabelCount(6);

        binding.lineChart.invalidate();
    }

    private void updatePieChart(List<PieEntry> entries) {
        if (binding == null) return;

        if (entries.isEmpty()) {
            binding.pieChart.setData(null);
            binding.pieChart.invalidate();
            return;
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setColors(ColorTemplate.MATERIAL_COLORS);
        dataSet.setSliceSpace(2f);
        dataSet.setValueTextSize(10f);
        dataSet.setValueTextColor(Color.WHITE);

        PieData pieData = new PieData(dataSet);
        pieData.setValueFormatter(new PercentFormatter(binding.pieChart));

        binding.pieChart.setData(pieData);
        binding.pieChart.invalidate();
    }

    private InsightData calculateInsight(String today, int amount, int field, long currentTotal) {
        Calendar cal = Calendar.getInstance();
        try {
            cal.setTime(dateFormat.parse(today));
        } catch (Exception e) {
            return InsightData.noData();
        }
        cal.add(field, amount);
        String pastDate = dateFormat.format(cal.getTime());

        AtomicLong pastAmount = new AtomicLong(0);
        CountDownLatch latch = new CountDownLatch(1);

        repository.getTotalAmountAtDate(pastDate, amt -> {
            pastAmount.set(amt);
            latch.countDown();
        });

        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        return new InsightData(currentTotal, pastAmount.get());
    }

    private List<CategoryAssetItem> loadCategoryAssets(String today, long totalAmount) {
        List<CategoryAssetItem> items = new ArrayList<>();
        CountDownLatch latch = new CountDownLatch(1);

        repository.getAllCategoryIds(categoryIds -> {
            if (categoryIds == null || categoryIds.isEmpty()) {
                latch.countDown();
                return;
            }

            CountDownLatch innerLatch = new CountDownLatch(categoryIds.size());

            for (String categoryId : categoryIds) {
                repository.getClosestSnapshot(categoryId, today, snapshot -> {
                    if (snapshot != null) {
                        String name = categoryNames.getOrDefault(categoryId, categoryId);
                        double percent = totalAmount > 0
                                ? ((double) snapshot.getAmount() / totalAmount) * 100
                                : 0;

                        synchronized (items) {
                            items.add(new CategoryAssetItem(
                                    categoryId,
                                    name,
                                    snapshot.getAmount(),
                                    snapshot.getDate(),
                                    percent
                            ));
                        }
                    }
                    innerLatch.countDown();
                });
            }

            try {
                innerLatch.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            latch.countDown();
        });

        try {
            latch.await();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // 금액 기준 내림차순 정렬
        items.sort((a, b) -> Long.compare(b.getAmount(), a.getAmount()));
        return items;
    }

    private void updateTotalAmount(long amount, String date) {
        if (binding == null) return;
        binding.tvTotalAmount.setText(currencyFormat.format(amount));
        try {
            Date d = dateFormat.parse(date);
            binding.tvAsOfDate.setText(getString(R.string.dashboard_as_of_date,
                    displayDateFormat.format(d)));
        } catch (Exception e) {
            binding.tvAsOfDate.setText(date);
        }
    }

    private void updateInsightCard(android.widget.TextView tvChange,
                                   android.widget.TextView tvPercent,
                                   InsightData insight) {
        if (getContext() == null) return;

        if (!insight.hasData()) {
            tvChange.setText(getString(R.string.dashboard_no_data));
            tvPercent.setText("-");
            tvChange.setTextColor(ContextCompat.getColor(getContext(),
                    com.google.android.material.R.color.material_on_surface_emphasis_medium));
            tvPercent.setTextColor(ContextCompat.getColor(getContext(),
                    com.google.android.material.R.color.material_on_surface_emphasis_medium));
            return;
        }

        String sign = insight.isPositive() ? "+" : "";
        tvChange.setText(sign + currencyFormat.format(insight.getChangeAmount()));
        tvPercent.setText(sign + percentFormat.format(insight.getChangePercent()) + "%");

        int color;
        if (insight.getChangeAmount() > 0) {
            color = ContextCompat.getColor(getContext(), R.color.positive);
        } else if (insight.getChangeAmount() < 0) {
            color = ContextCompat.getColor(getContext(), R.color.negative);
        } else {
            color = ContextCompat.getColor(getContext(),
                    com.google.android.material.R.color.material_on_surface_emphasis_medium);
        }

        tvChange.setTextColor(color);
        tvPercent.setTextColor(color);
    }

    private void updateCategoryList(List<CategoryAssetItem> items) {
        if (binding == null) return;
        if (items.isEmpty()) {
            binding.rvCategories.setVisibility(View.GONE);
            binding.tvEmpty.setVisibility(View.VISIBLE);
        } else {
            binding.rvCategories.setVisibility(View.VISIBLE);
            binding.tvEmpty.setVisibility(View.GONE);
            categoryAdapter.submitList(items);
        }
    }

    private void performSync() {
        TokenManager tokenManager = ApiClient.getInstance(requireContext()).getTokenManager();
        if (!tokenManager.isLoggedIn()) {
            Toast.makeText(requireContext(), R.string.offline_mode, Toast.LENGTH_SHORT).show();
            return;
        }

        Toast.makeText(requireContext(), R.string.sync_in_progress, Toast.LENGTH_SHORT).show();

        AppDatabase database = AppDatabase.getInstance(requireContext(), DatabaseKeyManager.getKey());
        SyncRepository syncRepository = new SyncRepository(requireContext(), database);

        syncRepository.sync(new SyncRepository.SyncCallback() {
            @Override
            public void onSuccess() {
                if (getActivity() != null && isAdded()) {
                    getActivity().runOnUiThread(() -> {
                        Toast.makeText(requireContext(), R.string.sync_success, Toast.LENGTH_SHORT).show();
                        loadDashboardData();
                    });
                }
            }

            @Override
            public void onError(String message) {
                if (getActivity() != null && isAdded()) {
                    getActivity().runOnUiThread(() -> {
                        Toast.makeText(requireContext(), R.string.sync_failed, Toast.LENGTH_SHORT).show();
                    });
                }
            }
        });
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
