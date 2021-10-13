package io.agora.example.fpaDemo;

import android.os.Environment;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.TimeUnit;

import androidx.annotation.NonNull;
import io.agora.fpaService.FpaService;
import io.agora.fpaService.FpaServiceObserver;
import io.agora.fpaService.LogUtil;
import okhttp3.Callback;
import okhttp3.Interceptor;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;
import okio.Buffer;
import okio.BufferedSink;
import okio.ByteString;
import okio.Okio;
import okio.Source;

import static io.agora.fpaService.Constants.BASE_HOST;
import static java.net.Proxy.Type.HTTP;

public class OkhttpUtil implements FpaServiceObserver {
    private static OkhttpUtil okhttpUtil;
    private OkHttpClient okHttpClientOrigin = null;
    private OkHttpClient okHttpClientProxy = null;
    private FpaService fpaOkhttpPlugIn;

    @Override
    public void onEvent(int event, int errorCode) {
        LogUtil.i("pluginEvent event:"+event+" errorCode:"+errorCode);
    }

    @Override
    public void onTokenWillExpireEvent(String token) {
        LogUtil.i("tokenWillExpireEvent token:"+token);
    }


    public class TestInterceptor implements Interceptor {
        @Override
        public Response intercept(Chain chain) throws IOException {
            Request request = chain.request();

            long t1 = System.nanoTime();
            LogUtil.i(String.format("logging Sending request %s on %s%n%s",
                    request.url(), chain.connection(), request.headers()));

            Response response = chain.proceed(request);

            long t2 = System.nanoTime();
            LogUtil.i(String.format("logging Received response for %s in %.1fms%n%s",
                    response.request().url(), (t2 - t1) / 1e6d, response.headers()));

            return response;
        }
    }


    public static OkhttpUtil get(FpaService fpaOkhttpPlugIn) {
        if (okhttpUtil == null) {
            okhttpUtil = new OkhttpUtil(fpaOkhttpPlugIn);
        }
        return okhttpUtil;
    }


    private OkhttpUtil(FpaService fpaOkhttpPlugIn) {
        this.fpaOkhttpPlugIn = fpaOkhttpPlugIn;
        okHttpClientOrigin = new OkHttpClient.Builder()
                .readTimeout(300,TimeUnit.SECONDS)
                .writeTimeout(300,TimeUnit.SECONDS)
                .build();
    }

    WebSocket mWebSocket = null;
    public void webSocketTest(final String websocketUrl) {
        if (okHttpClientProxy == null) {
            okHttpClientProxy  = okHttpClientOrigin.newBuilder()
                    .proxy(new Proxy(HTTP,new InetSocketAddress(BASE_HOST,fpaOkhttpPlugIn.getHttpProxyPort())))
                    .build();
        }
        Request request = new Request.Builder()
                .url(websocketUrl)
                .addHeader("Origin","http://www.qq.com")
                .build();
        okHttpClientProxy.newWebSocket(request, new WebSocketListener() {
            @Override
            public void onOpen(WebSocket webSocket, Response response) {
                mWebSocket = webSocket;
                System.out.println("client onOpen");
                System.out.println("client request header:" + response.request().headers());
                System.out.println("client response header:" + response.headers());
                System.out.println("client response:" + response);
                //开启消息定时发送
                startTask();
            }
            @Override
            public void onMessage(WebSocket webSocket, String text) {
                System.out.println("client onMessage");
                System.out.println("message:" + text);
            }
            @Override
            public void onClosing(WebSocket webSocket, int code, String reason) {
                System.out.println("client onClosing");
                System.out.println("code:" + code + " reason:" + reason);
            }
            @Override
            public void onClosed(WebSocket webSocket, int code, String reason) {
                System.out.println("client onClosed");
                System.out.println("code:" + code + " reason:" + reason);
            }
            @Override
            public void onFailure(WebSocket webSocket, Throwable t, Response response) {
                //出现异常会进入此回调
                System.out.println("client onFailure");
                System.out.println("throwable:" + t);
                System.out.println("response:" + response);
            }
        });
    }

    static int msgCount = 0;
    private  void startTask(){
        Timer mTimer= new Timer();
        TimerTask timerTask = new TimerTask() {
            @Override
            public void run() {
                if(mWebSocket == null) return;
                msgCount++;
                boolean isSuccessed = mWebSocket.send("msg" + msgCount + "-" + System.currentTimeMillis());
            }
        };
        mTimer.schedule(timerTask, 0, 1000);
    }

    static int downloadCount = 0;
    public void download(final String url, final int mode, final String saveDir, boolean isStaging,final OnDownloadListener listener) {
        downloadCount++;
        LogUtil.i("download:"+ downloadCount);
        if (okHttpClientProxy == null) {
            okHttpClientProxy  = okHttpClientOrigin.newBuilder()
                    .proxy(new Proxy(HTTP,new InetSocketAddress(BASE_HOST,fpaOkhttpPlugIn.getHttpProxyPort())))
                    .build();
        }
        Request request = new Request.Builder()
                .url(url) // "https://www.qq.com/"
                //.addHeader("Connection","close")
                .build();

        // use fpa mode
        okHttpClientProxy.newCall(request).enqueue(new HttpCallback(listener, downloadCount,saveDir));

    }

    public void stop() {
        fpaOkhttpPlugIn.destroy();
    }

    public class HttpCallback implements Callback {
        private OnDownloadListener listener;
        private int flag;
        private String saveDir;
        private long now;
        public HttpCallback(OnDownloadListener listener, int flag,String saveDir) {
            now = System.currentTimeMillis();
            this.listener = listener;
            this.flag = flag;
            this.saveDir = saveDir;
        }
        @Override
        public void onFailure(okhttp3.Call call, IOException e) {
            listener.onDownloadFailed();
            e.printStackTrace();
        }

        @Override
        public void onResponse(okhttp3.Call call, Response response) throws IOException {
            LogUtil.i("onResponse: " + response.body().contentLength()+ "code:"+response.code());
            if (!response.isSuccessful()){
                listener.onDownloadFailed();
                //return;
            }

            InputStream is = null;
            byte[] buf = new byte[2048];
            int len = 0;
            FileOutputStream fos = null;
            String savePath = isExistDir(this.saveDir);
            try {
                is = response.body().byteStream();
                long total = response.body().contentLength();
                File file = new File(this.saveDir);
                fos = new FileOutputStream(file);
                long sum = 0;
                int prevProgress = 0;
                while ((len = is.read(buf)) != -1) {
                    fos.write(buf, 0, len);
                    sum += len;
                    int progress = (int) (sum * 1.0f / total * 100);
                    if ((progress - prevProgress) >=1){
                        listener.onDownloading(progress);
                        //LogUtil.i(this.flag+" onDownloading: "+progress +"%");
                        prevProgress = progress;
                    }
                }
                fos.flush();
                long end = System.currentTimeMillis();
                double totalTime = (end-now)/1000.0;
                listener.onDownloadSuccess(totalTime);
                LogUtil.i(" tolal:"+sum +" total time:"+totalTime);
            } catch (Exception e) {
                e.printStackTrace();
                listener.onDownloadFailed();
            } finally {
                try {
                    if (is != null)
                        is.close();
                } catch (IOException e) {
                }
                try {
                    if (fos != null)
                        fos.close();
                } catch (IOException e) {
                }
            }
            response.close();
        }
    }

    static int uploadCount = 0;
    public void upload(final String url, final int mode, final String filePath, boolean isStaging, final OnUploadListener listener) {
        long now = System.currentTimeMillis();

        if (okHttpClientProxy == null) {
            okHttpClientProxy  = okHttpClientOrigin.newBuilder()
                    .proxy(new Proxy(HTTP,new InetSocketAddress(BASE_HOST,fpaOkhttpPlugIn.getHttpProxyPort())))
                    .build();
        }

        File uploadeFile = new File(filePath);
        RequestBody requestBody = new MultipartBody.Builder()
                .setType(MultipartBody.FORM)
                .addFormDataPart("file", uploadeFile.getName(),
                        createCustomRequestBody(MediaType.parse("multipart/form-data"), new File(filePath),listener))
                .build();

        Response response = null;
        Request request = new Request.Builder()
                //.header("Authorization", "Client-ID " + UUID.randomUUID())
                .url(url)
                .post(requestBody)
                .build();
        // use fpa mode
        try {
            response = okHttpClientProxy.newCall(request).execute();
        } catch (IOException e) {
            e.printStackTrace();
            listener.onUploadFailed();
        }
        if (response == null || !response.isSuccessful()) {
            LogUtil.i("try to upload file failed:"+response);
            listener.onUploadFailed();
            return;
        }
        long end = System.currentTimeMillis();
        double totalTime = (end-now)/1000.0;
        listener.onUploadSuccess(totalTime);
        LogUtil.i("try to upload file execute over code:"+response.code());
        return;
    }


    public static RequestBody createCustomRequestBody(final MediaType contentType, final File file, final OnUploadListener listener) {
        return new RequestBody() {
            @Override public MediaType contentType() {
                return contentType;
            }

            @Override public long contentLength() {
                return file.length();
            }

            @Override public void writeTo(BufferedSink sink) throws IOException {

                Source source;
                try {
                    source = Okio.source(file);
                    //sink.writeAll(source);
                    Buffer buf = new Buffer();
                    Long remaining = contentLength();
                    long sum = 0;
                    int prevProgress = 0;
                    for (long readCount; (readCount = source.read(buf, 65535)) != -1; ) {
                        sink.write(buf, readCount);
                        sum += readCount;
                        int progress = (int) (sum * 1.0f / remaining * 100);
                        // 下载中
                        if ((progress - prevProgress) >=1){
                            listener.onUploading(progress);
                            //LogUtil.i(" onUploading: "+progress +"%");
                            prevProgress = progress;
                        }
                    }

                    LogUtil.i("upload file success sum:"+sum);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        };
    }



    /**
     * @param saveDir
     * @return
     * @throws IOException
     * 判断下载目录是否存在
     */
    private String isExistDir(String saveDir) throws IOException {
        // 下载位置
        File downloadFile = new File(Environment.getExternalStorageDirectory(), saveDir);
        if (!downloadFile.mkdirs()) {
            downloadFile.createNewFile();
        }
        String savePath = downloadFile.getAbsolutePath();
        return savePath;
    }

    /**
     * @param url
     * @return
     */
    @NonNull
    public static String getNameFromUrl(String url) {
        return url.substring(url.lastIndexOf("/") + 1);
    }

    public interface OnDownloadListener {
        /**
         * @param totalTime
         */
        void onDownloadSuccess(double totalTime);

        /**
         * @param progress
         */
        void onDownloading(int progress);

        /**
         */
        void onDownloadFailed();
    }

    public interface OnUploadListener {
        /**
         * @param totalTime
         */
        void onUploadSuccess(double totalTime);

        /**
         * @param progress
         */
        void onUploading(int progress);

        /**
         */
        void onUploadFailed();
    }
}