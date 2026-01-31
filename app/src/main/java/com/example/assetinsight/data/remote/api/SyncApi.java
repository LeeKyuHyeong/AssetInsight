package com.example.assetinsight.data.remote.api;

import com.example.assetinsight.data.remote.dto.ApiResponse;
import com.example.assetinsight.data.remote.dto.SyncDto;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.POST;

/**
 * 동기화 API 인터페이스
 */
public interface SyncApi {

    @POST("sync/pull")
    Call<ApiResponse<SyncDto.SyncResponse>> pull(@Body SyncDto.PullRequest request);

    @POST("sync/push")
    Call<ApiResponse<SyncDto.SyncResponse>> push(@Body SyncDto.PushRequest request);
}
