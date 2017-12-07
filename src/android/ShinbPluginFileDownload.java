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
import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.text.DecimalFormat;

/**
 * This class echoes a string called from JavaScript.
 */
public class ShinbPluginFileDownload extends CordovaPlugin {

    private static final DecimalFormat FORMAT = new DecimalFormat("0.0000");

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
        } else if (action.equals("sbCancelAll")) {
            this.sbCancelAll("", callbackContext);
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
            if (fileDirectory.startsWith("file://")) {
                fileDirectory = fileDirectory.substring(7);
            }
            this.download(url, fileDirectory);
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
            new Thread(new Runnable() {
                @Override
                public void run() {
                    JSONObject messsage = new JSONObject();

                    try {
                        double progress = getProgress(url);
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
            }).start();

        }
    }

    /**
     * 取消单个下载
     *
     * @param url
     * @param callbackContext
     */
    private void sbCancel(String url, CallbackContext callbackContext) {
        if (TextUtils.isEmpty(url)) {
            callbackContext.error("url is null.");
        } else {
            callbackContext.success(url);
        }

        DownloadManager.getInstance().pause(md5(url));
    }

    /**
     * 取消所有下载
     *
     * @param url
     * @param callbackContext
     */
    private void sbCancelAll(String url, CallbackContext callbackContext) {
        callbackContext.success(url);
        DownloadManager.getInstance().pauseAll();
    }

    /**
     * 下载文件
     *
     * @param url
     * @param directory
     */
    private void download(final String url, String directory) {
        String tag = md5(url);

        if (DownloadManager.getInstance().isRunning(tag)) {
            return;
        }

        File directoryFile = new File(directory);
        if (!directoryFile.exists()) {
            directoryFile.mkdir();
        }

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
                ShinbPluginFileDownload.this.saveProgress(url, Float.parseFloat(finished + "") / total);

                Log.i("onProgress", Float.parseFloat(finished + "") / total + "");
            }

            @Override
            public void onCompleted() {
                ShinbPluginFileDownload.this.saveProgress(url, 1f);
                Log.d("onCompleted", true + "");
            }

            @Override
            public void onDownloadPaused() {

            }

            @Override
            public void onDownloadCanceled() {

            }

            @Override
            public void onFailed(DownloadException e) {
                Log.e("onFailed", e.getErrorMessage());
            }
        });
    }

    /**
     * 保存进度
     *
     * @param url
     * @param progress
     */
    private void saveProgress(String url, float progress) {
        try {
            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putFloat(md5(url), progress);
            editor.commit();
        } catch (Exception e) {

        }
    }

    /**
     * 读取进度
     *
     * @param url
     * @return
     */
    private float getProgress(String url) {
        try {
            SharedPreferences sharedPreferences = webView.getContext().getApplicationContext().getSharedPreferences("ShinbFileDownloader", Context.MODE_PRIVATE); //私有数据

            return sharedPreferences.getFloat(md5(url), 0f);
        } catch (Exception e) {

        }
        return 0f;
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
    public void onDestroy() {
        super.onDestroy();
        DownloadManager.getInstance().pauseAll();
    }
}
