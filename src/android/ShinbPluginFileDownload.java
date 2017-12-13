package cn.shinb.plugins.filedownload;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.util.Log;

import com.aspsine.multithreaddownload.CallBack;
import com.aspsine.multithreaddownload.DownloadConfiguration;
import com.aspsine.multithreaddownload.DownloadException;
import com.aspsine.multithreaddownload.DownloadManager;
import com.aspsine.multithreaddownload.DownloadRequest;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.DecimalFormat;
import java.util.HashMap;
import java.util.Map;

/**
 * This class echoes a string called from JavaScript.
 */
public class ShinbPluginFileDownload extends CordovaPlugin {

    private static final DecimalFormat FORMAT = new DecimalFormat("0.0000");

    /**
     * 用来存放下载进度，只有应用退出或者暂停时保存进度到数据库
     */
    private final Map<String, DownloadTask> progressMap = new HashMap<String, DownloadTask>();

    @Override
    protected void pluginInitialize() {
        super.pluginInitialize();
        initDownloader();
    }

    /**
     * 初始化下载
     */
    private void initDownloader() {
        DownloadConfiguration configuration = new DownloadConfiguration();
        configuration.setMaxThreadNum(10);
        configuration.setThreadNum(3);
        DownloadManager.getInstance().init(webView.getContext().getApplicationContext(), configuration);
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("coolMethod")) {
            String message = args.getString(0);
            this.coolMethod(message, callbackContext);
            return true;
        } else if (action.equals("sbDownload")) {
            String url = args.getString(0);
            String directory = args.getString(1);
            this.sbDownload(url, directory, callbackContext);
            return true;
        } else if (action.equals("sbDownloadInfo")) {
            String url = args.getString(0);
            this.sbDownloadInfo(url, callbackContext);
            return true;
        } else if (action.equals("sbCancel")) {
            String url = args.getString(0);
            this.sbCancel(url, callbackContext);
            return true;
        } else if (action.equals("sbCancelAndDel")) {
            String url = args.getString(0);
            String directory = args.getString(1);
            this.sbCancelAndDel(url, directory, callbackContext);
            return true;
        } else if (action.equals("sbCancelAll")) {
            this.sbCancelAll("", callbackContext);
            return true;
        } else if (action.equals("sbClearCache")) {
            String directory = args.getString(0);
            this.sbClearCache(directory, callbackContext);
            return true;
        } else if (action.equals("sbCacheSize")) {
            String directory = args.getString(0);
            this.sbCacheSize(directory, callbackContext);
            return true;
        }
        return false;
    }

    private void coolMethod(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }

    /**
     * 处理fileDirectory格式问题
     *
     * @param fileDirectory
     * @return
     */
    private String handleFileDirectory(String fileDirectory) {
        if (fileDirectory.startsWith("file://")) {
            fileDirectory = fileDirectory.substring(7);
        }
        return fileDirectory;
    }

    /**
     * 下载文件
     *
     * @param url
     * @param fileDirectory
     * @param callbackContext
     */
    private void sbDownload(String url, String fileDirectory, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(url) || TextUtils.isEmpty(fileDirectory)) {
            callbackContext.error("url or fileDirectory is null.");
        } else {
            callbackContext.success(url);
            this.download(url, handleFileDirectory(fileDirectory));
        }
    }

    /**
     * 下载文件信息
     *
     * @param url
     * @param callbackContext
     */
    private void sbDownloadInfo(final String url, final CallbackContext callbackContext) {
        if (TextUtils.isEmpty(url)) {
            callbackContext.error("url is null.");
        } else {
            JSONObject messsage = new JSONObject();

            try {
                DownloadTask task = getTempProgress(url);
                double progress = null == task ? 0 : task.getProgress();
                messsage.put("progress", FORMAT.format(progress));
                if (progress >= 1.f) {
                    messsage.put("isComplete", true);
                    messsage.put("isDownloading", false);
                } else {
                    messsage.put("isComplete", false);
                    messsage.put("isDownloading", DownloadManager.getInstance().isRunning(md5(url)));
                }

            } catch (Exception e) {

            }
            callbackContext.success(messsage);
        }
    }


    /**
     * 取消单个下载（但不删除任务）
     *
     * @param url
     * @param callbackContext
     */
    private void sbCancel(String url, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(url)) {
            callbackContext.error("url is null.");
        } else {
            String key = md5(url);
            this.pauseProgress(key, true);
            DownloadManager.getInstance().pause(key);
            callbackContext.success(url);
        }
    }

    /**
     * 取消下载任务并删除相关内容
     *
     * @param url
     * @param fileDirectory
     * @param callbackContext
     */
    private void sbCancelAndDel(String url, String fileDirectory, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(url) || TextUtils.isEmpty(fileDirectory)) {
            callbackContext.error("url or fileDirectory is null.");
        } else {
            String key = md5(url);
            this.pauseProgress(key, true);
            DownloadManager.getInstance().cancel(md5(url));
            this.deleteProgress(url);

            String directory = handleFileDirectory(fileDirectory);
            String fileName = getFileName(url);
            if (directory.endsWith("/")) {
                directory = directory + fileName;
            } else {
                directory = directory + "/" + fileName;
            }
            this.deleteFile(new File(directory));
            callbackContext.success(directory);
        }
    }

    /**
     * 取消所有下载
     *
     * @param url
     * @param callbackContext
     */
    private void sbCancelAll(String url, CallbackContext callbackContext) {
        this.pauseAllProgress(true);
        DownloadManager.getInstance().pauseAll();
        callbackContext.success(url);
    }

    /**
     * 删除缓存,先停止所以任务，再清除缓存
     *
     * @param fileDirectory
     * @param callbackContext
     */
    private void sbClearCache(String fileDirectory, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(fileDirectory)) {
            callbackContext.error("url or fileDirectory is null.");
        } else {
            DownloadManager.getInstance().cancelAll();
            this.clearProgress();
            this.deleteFiles(new File(handleFileDirectory(fileDirectory)));
            callbackContext.success(fileDirectory);
        }
    }

    /**
     * 获取缓存大小
     *
     * @param fileDirectory
     * @param callbackContext
     */
    private void sbCacheSize(String fileDirectory, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(fileDirectory)) {
            callbackContext.error("url or fileDirectory is null.");
        } else {
            String fileSize = getCacheFileSize(new File(handleFileDirectory(fileDirectory)));
            callbackContext.success(fileSize);
        }
    }

    /**
     * 下载文件
     *
     * @param url
     * @param directory
     */
    private void download(final String url, String directory) {
        final String tag = md5(url);

        if (DownloadManager.getInstance().isRunning(tag)) {
            return;
        }

        File directoryFile = new File(directory);
        if (!directoryFile.exists()) {
            directoryFile.mkdir();
        }

        this.pauseProgress(tag, false);
        final DownloadRequest request = new DownloadRequest.Builder()
                .setName(getFileName(url))
                .setUri(url)
                .setFolder(directoryFile)
                .build();

        DownloadManager.getInstance().download(request, tag, new CallBack() {
            @Override
            public void onStarted() {

            }

            @Override
            public void onConnecting() {

            }

            @Override
            public void onConnected(long total, boolean isRangeSupport) {

            }

            @Override
            public void onProgress(long finished, long total, int progress) {
                //Log.i("onProgress", Float.parseFloat(finished + "") / total + "");
                DownloadTask task = progressMap.get(tag);
                if (task != null && task.isPaused) {
                    return;
                }
                ShinbPluginFileDownload.this.putTempProgress(url, Float.parseFloat(finished + "") / total);
            }

            @Override
            public void onCompleted() {
                ShinbPluginFileDownload.this.putTempProgress(url, 1f);
                syncProgress();
                Log.d("onCompleted", true + "");
            }

            @Override
            public void onDownloadPaused() {
                syncProgress();
            }

            @Override
            public void onDownloadCanceled() {
                ShinbPluginFileDownload.this.deleteProgress(url);
            }

            @Override
            public void onFailed(DownloadException e) {
                try {
                    Log.e("onFailed", e.getErrorMessage());
                } catch (Exception ie) {
                }
            }
        });
    }

    /**
     * 删除文件
     *
     * @param file
     */
    private void deleteFile(File file) {
        if (null != file && file.exists() && file.isFile()) {
            file.delete();
        }
    }

    /**
     * 删除目录
     *
     * @param file
     */
    private void deleteFiles(File file) {
        try {
            if (null == file || file.exists()) {
                return;
            }

            if (!file.isDirectory()) {
                file.deleteOnExit();
                return;
            }

            File[] fileList = file.listFiles();
            for (File f : fileList) {
                if (f.isFile()) {
                    f.deleteOnExit();
                }

                if (f.isDirectory()) {
                    deleteFiles(f);
                }
            }
        } catch (Exception e) {

        }
    }

    /**
     * 获取文件大小
     *
     * @param file
     * @return
     */
    private String getCacheFileSize(File file) {
        long size = getFileSizes(file);
        return FormetFileSize(size);
    }

    /**
     * 获取指定文件夹大小
     *
     * @param f
     * @return
     * @throws Exception
     */
    private static long getFileSizes(File f) {
        long size = 0;
        try {
            File[] fileList = f.listFiles();
            for (File file : fileList) {
                if (file.isDirectory()) {
                    size = size + getFileSizes(file);
                } else {
                    size = size + getFileSize(file);
                }
            }
        } catch (Exception e) {

        }

        return size;
    }

    /**
     * 单个文件大小
     *
     * @param file
     * @return
     */
    private static long getFileSize(File file) {
        long size = 0;
        FileInputStream fis = null;
        try {
            if (file.exists()) {
                fis = new FileInputStream(file);
                size = fis.available();
            }
        } catch (Exception e) {

        } finally {
            if (null != fis) {
                try {
                    fis.close();
                } catch (IOException e) {
                }
            }
        }
        return size;
    }

    /**
     * 暂停进度
     *
     * @param key
     * @param isPaused
     */
    private void pauseProgress(String key, boolean isPaused) {
        DownloadTask task = progressMap.get(key);
        if (null != task) {
            task.isPaused = isPaused;
        }
    }

    /**
     * 暂停所有进度
     *
     * @param isPaused
     */
    private void pauseAllProgress(boolean isPaused) {
        if (progressMap == null || progressMap.isEmpty()) {
            return;
        }
        for (Map.Entry<String, DownloadTask> entry : progressMap.entrySet()) {
            DownloadTask value = entry.getValue();
            value.isPaused = isPaused;
        }
    }

    /**
     * 保存临时进度
     *
     * @param url
     * @param progress
     */
    private void putTempProgress(String url, float progress) {
        DownloadTask task = progressMap.get(url);
        if (null == task) {
            task = new DownloadTask(progress, false);
        }
        task.progress = progress;
        progressMap.put(md5(url), task);
    }

    /**
     * 读取临时进度
     *
     * @param url
     */
    private DownloadTask getTempProgress(String url) {
        String key = md5(url);
        if (progressMap.containsKey(key)) {
            return progressMap.get(key);
        }

        return new DownloadTask(getProgress(key), DownloadManager.getInstance().isRunning(key));
    }

    /**
     * 保存进度
     *
     * @param key
     * @param progress
     */
    private void saveProgress(final String key, final float progress) {
        try {
            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putFloat(key, progress);
            editor.commit();
        } catch (Exception e) {

        }
    }

    /**
     * 删除key的内容
     *
     * @param key
     */
    private void deleteProgress(String key) {
        try {
            String md5Key = md5(key);
            if (progressMap.containsKey(md5Key)) {
                progressMap.remove(md5Key);
            }
            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.remove(md5Key);
            editor.commit();
        } catch (Exception e) {

        }
    }

    /**
     * 清除数据库内容
     */
    private void clearProgress() {
        try {
            if (null != progressMap) {
                progressMap.clear();
            }

            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.clear();
            editor.commit();
        } catch (Exception e) {

        }
    }

    /**
     * 读取进度
     *
     * @param key
     * @return
     */
    private float getProgress(String key) {
        try {
            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据
            return sharedPreferences.getFloat(key, 0f);
        } catch (Exception e) {

        }
        return 0f;
    }

    /**
     * 同步progress
     */
    private void syncProgress() {
        if (progressMap == null || progressMap.isEmpty()) {
            return;
        }
        for (Map.Entry<String, DownloadTask> entry : progressMap.entrySet()) {
            String key = entry.getKey();
            DownloadTask value = entry.getValue();
            saveProgress(key, value.getProgress());
        }
    }

    /**
     * 获取文件名
     *
     * @param url
     * @return
     */
    private String getFileName(String url) {
        return url.substring(url.lastIndexOf("/") + 1);
    }


    /**
     * 转换文件大小
     *
     * @param fileS
     * @return
     */
    public static String FormetFileSize(long fileS) {
        DecimalFormat df = new DecimalFormat("#.00");
        String fileSizeString = "";
        String wrongSize = "0 B";
        if (fileS == 0) {
            return wrongSize;
        }
        if (fileS < 1024) {
            fileSizeString = df.format((double) fileS) + "B";
        } else if (fileS < 1048576) {
            fileSizeString = df.format((double) fileS / 1024) + "KB";
        } else if (fileS < 1073741824) {
            fileSizeString = df.format((double) fileS / 1048576) + "MB";
        } else {
            fileSizeString = df.format((double) fileS / 1073741824) + "GB";
        }
        return fileSizeString;
    }

    /**
     * md5值
     *
     * @param url
     * @return
     */
    private String md5(String url) {
        byte[] hash;

        try {
            hash = MessageDigest.getInstance("MD5").digest(url.getBytes("UTF-8"));
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            return null;
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            return null;
        }

        StringBuilder hex = new StringBuilder(hash.length * 2);
        for (byte b : hash) {
            if ((b & 0xFF) < 0x10)
                hex.append("0");
            hex.append(Integer.toHexString(b & 0xFF));
        }

        return hex.toString();
    }

    @Override
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
        syncProgress();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        DownloadManager.getInstance().pauseAll();
    }

    /**
     * 下载任务
     */
    private static class DownloadTask {
        private float progress;
        private boolean isPaused;

        public DownloadTask(float progress, boolean isPaused) {
            this.progress = progress;
            this.isPaused = isPaused;
        }

        public float getProgress() {
            return progress;
        }

        public void setProgress(float progress) {
            this.progress = progress;
        }

        public boolean isPaused() {
            return isPaused;
        }

        public void setPaused(boolean paused) {
            isPaused = paused;
        }
    }
}