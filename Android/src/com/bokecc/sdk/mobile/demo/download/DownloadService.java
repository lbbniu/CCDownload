package com.bokecc.sdk.mobile.demo.download;

import java.io.File;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Map.Entry;


import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.bokecc.sdk.mobile.demo.model.DownloadInfo;
import com.bokecc.sdk.mobile.demo.model.DownloadingInfo;
import com.bokecc.sdk.mobile.demo.util.ConfigUtil;
import com.bokecc.sdk.mobile.demo.util.DataSet;
import com.bokecc.sdk.mobile.demo.util.MediaUtil;
import com.bokecc.sdk.mobile.demo.util.ParamsUtil;
import com.bokecc.sdk.mobile.download.DownloadListener;
import com.bokecc.sdk.mobile.download.Downloader;
import com.bokecc.sdk.mobile.exception.DreamwinException;



/**
 * DownloadService，用于支持后台下载
 * 
 * @author CC视频
 *
 */
public class DownloadService extends Service {
	
	private final String TAG = "LbbDownloadService";
	
	private Map<String, Downloader> downloadMap = null; //正在下载的视频
	private Map<String, DownloadingInfo> downloadingInfos = null; //视频下载进度
	private final int MAX_COUNT = 2; // 最大并行下载量
	private int currentCount = 0; // 当前并行下载量
	
	private String title;
	private DownloadBinder binder = new DownloadBinder();
	
	/**
	 * 下载之前的准备工作，并自动开始下载
	 * 
	 * @param context
	 */
	public void prepare(String title) {
		if (currentCount < MAX_COUNT) {
			start(title);
		} else {
			Log.d("lbbniu","等待下载____" + title);
		}
	}
	/**
	 * 开始下载
	 * TODO:需要修改
	 */
	private synchronized void start(String title) {
		if(title == null){
			if (LbbDownload.downloadingInfos != null && LbbDownload.downloadingInfos.isEmpty()) {
				Log.d("lbbniu","LbbDownload.downloadingInfos != null");
				return;
			}
			for (DownloadInfo downloadInfo: LbbDownload.downloadingInfos) {
				if (downloadInfo.getStatus() == Downloader.WAIT) {
					title = downloadInfo.getTitle();
					break;
				}
			}
		}
		String videoId = getVideoId(title);
		if (videoId == null) {
			Log.i(TAG, "videoId is null");
			return;
		}
		Downloader downloaderTool = LbbDownload.downloaderHashMap.get(title);
		if ( downloaderTool == null){
			Log.d("lbbniu","downloaderTool == null____" + videoId);
			File file = MediaUtil.createFile(title);
			if (file == null) {
				Log.i(TAG, "File is null");
				return ;
			}
			downloaderTool = new Downloader(file, videoId, ConfigUtil.USERID, ConfigUtil.API_KEY);
			LbbDownload.downloaderHashMap.put(title, downloaderTool);
		}
		
		if (downloadMap.size() < MAX_COUNT) { // 保证downloadMap.size() <= 2
			if (!downloadMap.containsKey(videoId)) {
				downloadMap.put(videoId, downloaderTool);
				currentCount++;
			}
			downloaderTool.setDownloadListener(downloadListener);
			//downloaderTool.start();
			if (downloaderTool.getStatus() == Downloader.WAIT) {
				downloaderTool.start();
			}
			
			if (downloaderTool.getStatus() == Downloader.PAUSE) {
				downloaderTool.resume();
			}
			
			Intent notifyIntent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
			notifyIntent.putExtra("status", Downloader.WAIT);
			notifyIntent.putExtra("title", title);
			sendBroadcast(notifyIntent);
			Log.d("lbbniu","开始下载____" + videoId);
		} else {
			Log.d("lbbniu","等待啊啊____" + videoId);
		}
				
	}
	
	/**
	 * 暂停
	 * 
	 * @param urlString
	 * @param paused
	 * @return 下载任务是否存在的标识
	 */
	public void pauseVideo(String title) {
		String videoId = getVideoId(title);
		if (downloadMap.containsKey(videoId)) {
			Downloader downloaderTool = downloadMap.get(videoId);
			if(downloaderTool.getStatus() == Downloader.DOWNLOAD){
				downloaderTool.pause();
			}
			downloadMap.remove(videoId);
			currentCount--;
			//TODO: 暂停一个视频，可以继续下载等待中的 start(null);
			//return true;
		}
		//return false;
	}
	
	/** 暂停所有的下载任务 */
	public void pauseAll() {
		// 如果需要边遍历集合边删除数据，需要从后向前遍历，否则会出异常（Caused by:
		// java.util.ConcurrentModificationException）
		String[] keys = new String[downloadMap.size()];
		downloadMap.keySet().toArray(keys);
		for (int i = keys.length - 1; i >= 0; i--) {
			pauseVideo(keys[i]);
		}
	}
	
	/**
	 * 恢复当前下载任务
	 * 
	 * @param urlString
	 * 要恢复下载的文件的地址
	 */
	public void resume(String videoId) {
		prepare(videoId);
	}
	
	/** 恢复所有的下载任务 */
	public void resumeAll() {
		for (Entry<String, Downloader> entity : downloadMap.entrySet()) {
			prepare(entity.getKey());
		}
	}

	/** 删除当前下载任务 */
	public void delete(String title) {
		String videoId = getVideoId(title);
		if (downloadMap.containsKey(videoId)) {
			pauseVideo(title);
		}
		//下载任务不存在，直接删除临时文件
		File file = MediaUtil.createFile(title);
		if(file != null && file.exists()){
			file.delete();
		}
	}
    
	public class DownloadBinder extends Binder {
		
		public String getTitle(){
			return title;
		}
		
		public int getProgress(String videoId){
			if(downloadingInfos.containsKey(videoId)){
				return downloadingInfos.get(videoId).getProgress();
			}
			return 0;
		}
		
		public String getProgressText(String videoId){
			if(downloadingInfos.containsKey(videoId)){
				return downloadingInfos.get(videoId).getProgressText();
			}
			return null;
		}
		public boolean isStop(){
			return downloadMap.isEmpty();
		}
		
		public boolean isFree(){
			return downloadMap.size()<MAX_COUNT;
		}
		
		public int getMaXCount(){
			return MAX_COUNT;
		}
		
		public void pause(String videoId){
			pauseVideo(videoId);
		}
		
		public void download(String videoId){
			prepare(videoId);
		}
		
		public void cancel(String videoId){
			if(downloadMap.containsKey(videoId)){
				Downloader downloader = downloadMap.get(videoId);
				pauseVideo(videoId);
				if (downloader == null) {
					return;
				}
				downloader.cancel();
			}
		}
		
		public int getDownloadStatus(String videoId){
			Downloader downloader = null;
			if(downloadMap.containsKey(videoId)){
				downloader = downloadMap.get(videoId);
			}
			if (downloader == null) {
				return Downloader.WAIT;
			}
			return downloader.getStatus();
		}
		
		public String[] getTitles(){
			String[] keys = new String[downloadMap.size()];
			downloadMap.keySet().toArray(keys);
			return keys;
		}
		
		public boolean exists(String videoId) {
			return downloadMap.containsKey(videoId);
		}
	}
	
	@Override
	public IBinder onBind(Intent intent) {
		Log.d(TAG,"onBind____");	
		return binder;
	}

	@Override
	public void onCreate() {
		Log.d(TAG,"onCreate____");	
		downloadMap = new HashMap<String, Downloader>();
		downloadingInfos = new HashMap<String, DownloadingInfo>();
		super.onCreate();
	}
	
	private String getVideoId(String title){
		if(title == null){
			return null;
		}
		
		int charIndex = title.indexOf('-');
		
		if (-1 == charIndex){
			return title;
		} else {
			return title.substring(0, charIndex);
		}
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		
		if (intent == null) {
			Log.i(TAG, "intent is null.");
			return android.app.Service.START_STICKY;
		}
		
		title = intent.getStringExtra("title");
		if (title == null) {
			Log.i(TAG, "title is null");
			return android.app.Service.START_STICKY;
		}
		prepare(title);
		Log.i(TAG, "Start download service");
		return super.onStartCommand(intent, flags, startId);
		/*
		videoId = getVideoId(title);
		if (videoId == null) {
			Log.i(TAG, "videoId is null");
			return android.app.Service.START_STICKY;
		}
		downloader = DownloadFragment.downloaderHashMap.get(title);
		if ( downloader == null){
			file = MediaUtil.createFile(title);
			if (file == null) {
				Log.i(TAG, "File is null");
				return android.app.Service.START_STICKY;
			}
			downloader = new Downloader(file, videoId, ConfigUtil.USERID, ConfigUtil.API_KEY);
			DownloadFragment.downloaderHashMap.put(title, downloader);
		}
		
		downloader.setDownloadListener(downloadListener);
		downloader.start();
		
		Intent notifyIntent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
		notifyIntent.putExtra("status", Downloader.WAIT);
		notifyIntent.putExtra("title", title);
		sendBroadcast(notifyIntent);
		stop = false;
	
		Log.i(TAG, "Start download service");
		return super.onStartCommand(intent, flags, startId);*/
	}

	@Override
	public void onTaskRemoved(Intent rootIntent) {
		if(!downloadMap.isEmpty()){
			pauseAll();//暂停所有
		}
		super.onTaskRemoved(rootIntent);
	}

	private DownloadListener downloadListener = new DownloadListener() {
		
		DecimalFormat decimalFormat = new DecimalFormat("#.##"); // 小数格式化
		Timer timer = null;
		@Override
		public void handleStatus(String videoId, int status) {
			
			Intent intent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
			intent.putExtra("status", status);
			intent.putExtra("title", videoId);
			
			updateDownloadInfoByStatus(videoId, status);
			
			switch (status) {
			case Downloader.PAUSE:
				sendBroadcast(intent);
				if (downloadingInfos.containsKey(videoId)) {
					downloadingInfos.remove(videoId);
				}
				Log.i(TAG, "pause");
				break;
			case Downloader.DOWNLOAD:
				sendBroadcast(intent);
				if (!downloadingInfos.containsKey(videoId)) {
					downloadingInfos.put(videoId, new DownloadingInfo());
				}
				Log.i(TAG, "download");
				break;
			case Downloader.FINISH:
				pauseVideo(videoId);
                // 停掉服务自身
				if(downloadMap.isEmpty()){
					stopSelf();  
				}
                // 重置下载服务
				// 通知已下载队列
				sendBroadcast(new Intent(ConfigUtil.ACTION_DOWNLOADED));
				// 通知下载中队列
				sendBroadcast(intent);
				//移除完成的downloader
				LbbDownload.downloaderHashMap.remove(videoId);
				if (downloadingInfos.containsKey(videoId)) {
					downloadingInfos.remove(videoId);
				}
				Log.i(TAG, "download finished.");
				break;
			}
		}
		String text = "已下载%sM / 共%sM \n占比%s  \n下载速度%skb/s";
		@Override
		public void handleProcess(long start, long end, String videoId) {
			if (downloadMap.isEmpty()) {
				return;
			}
			DownloadingInfo info = downloadingInfos.get(videoId);
			if (info != null) {
				if(info.getStart() > 0){
					info.setSecondSize(info.getSecondSize() + start - info.getStart());
				}
				info.setStart(start);
				info.setEnd(end);
				info.setProgress((int) ((double) start / end * 100));
				if (info.getProgress() <= 100) {
					//progressText = ParamsUtil.byteToM(start).
					//		concat(" M / ").
					//		concat(ParamsUtil.byteToM(end).
					//		concat(" M"));
					info.setProgressText(String.format(
							text,
							ParamsUtil.byteToM(start),
							ParamsUtil.byteToM(end),
							(int) (((float) start / (float) end) * 100) + "%", info
									.getKbps()));
	            }
			}
			
			if (timer == null) {
				timer = new Timer();
				timer.schedule(new TimerTask() {
					@Override
					public void run() {
						DownloadingInfo info = null;
						for (Entry<String, DownloadingInfo> entry : downloadingInfos
								.entrySet()) {
							info = entry.getValue();
							if (info != null) {
								info.setKbps(decimalFormat.format(info
										.getSecondSize() / 1024.0));
								info.setSecondSize(0);
							}
						}
					}
				}, 0, 1000);
			}
		}
		
		@Override
		public void handleException(DreamwinException exception, int status) {
			Log.i("Download exception", exception.getErrorCode().Value() + " : " + title+":status="+status);
			// 停掉服务自身
			if(downloadMap.isEmpty()){
				stopSelf();
			}
			updateDownloadInfoByStatus(status);
		
			Intent intent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
			intent.putExtra("errorCode", exception.getErrorCode().Value());
			intent.putExtra("title", title);
			sendBroadcast(intent);
		}

		@Override
		public void handleCancel(String videoId) {
			Log.i(TAG, "cancel download, title: " + title + ", videoId: " + videoId);
			if(downloadMap.isEmpty()){
				stopSelf();
			}
		}
	};
	private void updateDownloadInfoByStatus(String videoId, int status){
		DownloadingInfo downloadingInfo = downloadingInfos.get(videoId);
		DownloadInfo downloadInfo = DataSet.getDownloadInfo(videoId);
		if (downloadInfo == null) {
			return;
		}
		downloadInfo.setStatus(status);
		if (downloadingInfo != null && downloadingInfo.getProgress() > 0) {
			downloadInfo.setProgress(downloadingInfo.getProgress());
		}
		
		if (downloadingInfo != null && downloadingInfo.getProgressText() != null) {
			downloadInfo.setProgressText(downloadingInfo.getProgressText());
		}
		DataSet.updateDownloadInfo(downloadInfo);
	}
	
	private void updateDownloadInfoByStatus(int status){
		String[] keys = new String[downloadMap.size()];
		downloadMap.keySet().toArray(keys);
		for (int i = keys.length - 1; i >= 0; i--) {
			Downloader downloader = downloadMap.get(keys[i]);
			updateDownloadInfoByStatus(keys[i],downloader.getStatus());
			if(downloader.getStatus() != Downloader.DOWNLOAD){
				 downloadMap.remove(keys[i]);
				 currentCount--;
			}
		}
	}

}
