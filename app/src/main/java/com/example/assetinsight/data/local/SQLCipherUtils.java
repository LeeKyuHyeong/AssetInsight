package com.example.assetinsight.data.local;

import android.content.Context;

import net.sqlcipher.database.SQLiteDatabase;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

import timber.log.Timber;

/**
 * SQLCipher 유틸리티 클래스
 * - 암호화 키 변환 및 관리
 * - 데이터베이스 상태 확인
 */
public class SQLCipherUtils {

    public enum DbState {
        DOES_NOT_EXIST,
        UNENCRYPTED,
        ENCRYPTED
    }

    private SQLCipherUtils() {
        // Utility class
    }

    /**
     * 데이터베이스 파일의 암호화 상태 확인
     */
    public static DbState getDatabaseState(Context context, String databaseName) {
        File dbFile = context.getDatabasePath(databaseName);

        if (!dbFile.exists()) {
            return DbState.DOES_NOT_EXIST;
        }

        // SQLite3 파일 헤더 확인 (암호화되지 않은 파일은 "SQLite format 3\0"으로 시작)
        try (FileInputStream fis = new FileInputStream(dbFile)) {
            byte[] header = new byte[16];
            int read = fis.read(header);
            if (read < 16) {
                return DbState.UNENCRYPTED;
            }

            String headerStr = new String(header, StandardCharsets.US_ASCII);
            if (headerStr.startsWith("SQLite format 3")) {
                return DbState.UNENCRYPTED;
            } else {
                return DbState.ENCRYPTED;
            }
        } catch (IOException e) {
            Timber.e(e, "Failed to check database state");
            return DbState.UNENCRYPTED;
        }
    }

    /**
     * 암호화되지 않은 데이터베이스 삭제
     */
    public static boolean deleteDatabase(Context context, String databaseName) {
        File dbFile = context.getDatabasePath(databaseName);
        File dbJournal = new File(dbFile.getPath() + "-journal");
        File dbWal = new File(dbFile.getPath() + "-wal");
        File dbShm = new File(dbFile.getPath() + "-shm");

        boolean deleted = true;
        if (dbFile.exists()) {
            deleted = dbFile.delete();
            Timber.d("Deleted database file: %s", deleted);
        }
        if (dbJournal.exists()) {
            dbJournal.delete();
        }
        if (dbWal.exists()) {
            dbWal.delete();
        }
        if (dbShm.exists()) {
            dbShm.delete();
        }
        return deleted;
    }

    /**
     * char[] 암호를 byte[]로 변환
     * 변환 후 원본 char[]는 보안을 위해 초기화됨
     */
    public static byte[] getKey(char[] passphrase) {
        CharBuffer charBuffer = CharBuffer.wrap(passphrase);
        ByteBuffer byteBuffer = StandardCharsets.UTF_8.encode(charBuffer);

        byte[] key = Arrays.copyOfRange(byteBuffer.array(),
                byteBuffer.position(), byteBuffer.limit());

        // 보안을 위해 버퍼 초기화
        Arrays.fill(charBuffer.array(), '\u0000');
        Arrays.fill(byteBuffer.array(), (byte) 0);

        return key;
    }

    /**
     * 바이트 배열 보안 초기화
     */
    public static void clearKey(byte[] key) {
        if (key != null) {
            Arrays.fill(key, (byte) 0);
        }
    }

    /**
     * 문자 배열 보안 초기화
     */
    public static void clearPassphrase(char[] passphrase) {
        if (passphrase != null) {
            Arrays.fill(passphrase, '\u0000');
        }
    }
}
