package io.agora.example.fpaDemo;

import androidx.appcompat.app.AppCompatActivity;
import io.agora.fpaService.Constants;
import io.agora.fpaService.FpaConfig;
import io.agora.fpaService.FpaService;
import io.agora.fpaService.LogUtil;

import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Spinner;
import android.widget.TextView;

import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;


public class MainActivity extends AppCompatActivity {

    private Spinner modeSpinner;

    private TextView tvInfo;
    int mode;
    String upload_http_url = "http://148.153.93.30:30103/upload";
    String download_http_url = "http://148.153.93.30:30103/10MB.txt";
    String download_http_url2 = "http://148.153.93.30:30103/5MB.txt";
    String upload_https_url = "https://frank-web-demo.rtns.sd-rtn.com:30113/upload";
    String download_https_url = "https://frank-web-demo.rtns.sd-rtn.com:30113/1MB.txt";
    private FpaService fpaOkhttpPlugIn;
    FpaConfig config = new FpaConfig();
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        initUI();
        initFpaService();
        //ActivityCompat.requestPermissions(MainActivity.this, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
    }


    public void initFpaService() {
        config.setAppId(<YOUR APPID>);
        config.setToken(<YOUR TOKEN>);
        Map<String ,Integer> chainIdTable = new HashMap<>();
        chainIdTable.put("frank-web-demo.rtns.sd-rtn.com:30113",<YOUR USEABLE CHAIN_ID>);
        chainIdTable.put("148.153.93.30:30103",<YOUR USEABLE CHAIN_ID>);
        config.setChainIdTable(chainIdTable);
        //config.setLogLevel(1);
        //config.setLogFilePath("/sdcard/test.log");
        try {
            fpaOkhttpPlugIn = FpaService.createFpaService(config);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    private void initUI() {
        modeSpinner = (Spinner)findViewById(R.id.sp_mode);

        modeSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {

            public void onItemSelected(AdapterView<?> arg0, View arg1, int arg2, long arg3) {
                mode = Integer.valueOf(modeSpinner.getSelectedItem().toString());
            }

            public void onNothingSelected(AdapterView<?> arg0) {
            }
        });
        modeSpinner.setSelection(0);
        tvInfo = (TextView) findViewById(R.id.tv_info);

    }

    public void onClickHttpsDownload(View view) {
        tvInfo.setText("");
        int count = 1;
        for (int i=0;i<count;i++) {
            new Thread(new DownloaderThread(download_https_url,false,mode,"/sdcard/download.pptx",i)).start();
        }
    }

    public void onClickHttpDownload(View view) {
        tvInfo.setText("");
        int count = 1;
        for (int i=0;i<count;i++) {
            new Thread(new DownloaderThread(download_http_url,false,mode,"/sdcard/download.pptx",i)).start();
        }
    }

    public void onClickCreateFpaServcie(View view) {
        initFpaService();
    }

    public void onClickDestroyFpaServcie(View view) {
        fpaOkhttpPlugIn.destroy();
    }

    class DownloaderThread implements Runnable {

        private String url;
        private boolean isStaging;
        private int mode;
        private String download_file_path;
        private int flag;
        public DownloaderThread(String url, boolean isStaging,int mode,String download_file_path,int flag) {
            this.url = url;
            this.isStaging = isStaging;
            this.mode = mode;
            this.download_file_path = download_file_path;
            this.flag = flag;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            //String downloadUrl = "http://148.153.132.174:30100/5MB.txt";
            String downloadUrl = "https://tsp-test.dev.yeego.com/prod/api/system/download?key=tsp/guard_file/20210629/TESTCAR0039328896-20210629181255.mp4";
            OkhttpUtil.get(fpaOkhttpPlugIn).download(this.url, this.mode,this.download_file_path, this.isStaging,new OkhttpUtil.OnDownloadListener() {
                @Override
                public void onDownloadSuccess(double totalTime) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = tempInfo +"\n" +"onDownloadSuccess total time:"+totalTime;

                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }

                @Override
                public void onDownloading(int progress) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = "onDownloading "+progress+"%";
                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }

                @Override
                public void onDownloadFailed() {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = tempInfo +"\n" +"onDownloadFailed";
                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }
            });
        }
    };

    public void onClickHttpUpload(View view) {
        tvInfo.setText("");
        int count = 1;
        for (int i=0;i<count;i++) {
            new Thread(new UploadThread(upload_http_url,false,mode,"/sdcard/10MB.txt",i)).start();
        }
        // new Thread(new HttpConnectionTest()).start();
    }


    public void onClickHttpsUpload(View view) {
        tvInfo.setText("");
        int count = 1;
        for (int i=0;i<count;i++) {
            new Thread(new UploadThread(upload_https_url,false,mode,"/sdcard/100KB.txt",i)).start();
        }
    }


    class UploadThread implements Runnable  {
        private String url;
        private boolean isStaging;
        private int mode;
        private String upload_file_path;
        private int flag;
        public UploadThread(String url, boolean isStaging,int mode,String upload_file_path,int flag) {
            this.url = url;
            this.isStaging = isStaging;
            this.mode = mode;
            this.upload_file_path = upload_file_path;
            this.flag = flag;
        }

        @Override
        public void run() {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            OkhttpUtil.get(fpaOkhttpPlugIn).upload(this.url, this.mode,this.upload_file_path,this.isStaging,new OkhttpUtil.OnUploadListener() {

                @Override
                public void onUploadSuccess(double totalTime) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = tempInfo +"\n" +"onUploadSuccess total time:"+totalTime;

                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }

                @Override
                public void onUploading(int progress) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = "onUploading "+progress+"%";
                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }

                @Override
                public void onUploadFailed() {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            String tempInfo = tvInfo.getText().toString();
                            tempInfo = tempInfo +"\n" +"onUploadFailed";
                            String finalTempInfo = tempInfo;
                            tvInfo.setText(finalTempInfo);
                        }
                    });
                }
            });
        }
    };



    class HttpConnectionTest implements Runnable  {

        @Override
        public void run() {
            try {
                URL url = new URL(download_http_url);
                Proxy proxy = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(Constants.BASE_HOST, fpaOkhttpPlugIn.getHttpProxyPort()));
                HttpURLConnection connection = (HttpURLConnection) url.openConnection(proxy);


                connection.setRequestMethod("GET");
                connection.connect();
                int responseCode = connection.getResponseCode();
                if(responseCode == HttpURLConnection.HTTP_OK){
                    LogUtil.i("HttpConnectionTest test ok");
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    };

}