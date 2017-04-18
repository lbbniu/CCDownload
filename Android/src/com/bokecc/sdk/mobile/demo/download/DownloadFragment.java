package com.bokecc.sdk.mobile.demo.download;

import java.io.File;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.app.AlertDialog.Builder;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.util.Pair;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;
import android.widget.Toast;

import com.bokecc.sdk.mobile.demo.R;
import com.bokecc.sdk.mobile.demo.adapter.VideoListViewAdapter;
import com.bokecc.sdk.mobile.demo.download.DownloadService.DownloadBinder;
import com.bokecc.sdk.mobile.demo.model.DownloadInfo;
import com.bokecc.sdk.mobile.demo.util.ConfigUtil;
import com.bokecc.sdk.mobile.demo.util.DataSet;
import com.bokecc.sdk.mobile.demo.util.MediaUtil;
import com.bokecc.sdk.mobile.demo.util.ParamsUtil;
import com.bokecc.sdk.mobile.demo.view.VideoListView;
import com.bokecc.sdk.mobile.download.Downloader;
import com.bokecc.sdk.mobile.download.OnProcessDefinitionListener;
import com.bokecc.sdk.mobile.exception.DreamwinException;
import com.bokecc.sdk.mobile.exception.ErrorCode;

/**
 * 
 * 下载列表标签页，用于展示待下载的视频ID
 * 
 * @author CC视频
 *
 */
public class DownloadFragment extends Fragment {

	final String POPUP_DIALOG_MESSAGE = "dialogMessage";
	
	final String GET_DEFINITION_ERROR  = "getDefinitionError";
	
	
	AlertDialog definitionDialog;

	private List<Pair<String, Integer>> pairs;
	
	private DownloadListViewAdapter downloadListViewAdapter;

	//TODO 待下载视频ID，可根据需求自定义
	public String[] downloadVideoIds = new String[] {"FD06098BB3DF4E2A9C33DC5901307461","0DE87E129151F23B9C33DC5901307461","56AF3FA9E76F216C9C33DC5901307461","4D4C63D0A3C2C9E79C33DC5901307461","782AA1BFBC0391099C33DC5901307461"};
	private ListView downloadListView;
	private Context context;
	private FragmentActivity activity;
	private DownloadService.DownloadBinder binder;
	private Intent service;
	private DownloadedReceiver receiver;
	private String videoId;
	private String title;
	private Downloader downloader;
	int[] definitionMapKeys;
	HashMap<Integer, String> hm;
	
	private ServiceConnection serviceConnection = new ServiceConnection() {
		@Override
		public void onServiceDisconnected(ComponentName name) {
			Log.i("service disconnected", name + "");
		}

		@Override
		public void onServiceConnected(ComponentName name, IBinder service) {
			binder = (DownloadBinder) service;
		}
	};

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		activity = getActivity();
		context = activity.getApplicationContext();
		receiver = new DownloadedReceiver();
		activity.registerReceiver(receiver, new IntentFilter(ConfigUtil.ACTION_DOWNLOADING));
		
		RelativeLayout downloadRelativeLayout = new RelativeLayout(context);
		downloadRelativeLayout.setBackgroundColor(Color.WHITE);
		downloadRelativeLayout.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT));
		
		downloadListView = new ListView(context);
		downloadListView.setPadding(10, 10, 10, 10);
		downloadListView.setDivider(getResources().getDrawable(R.drawable.line));
		LayoutParams listViewLayout = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
		downloadRelativeLayout.addView(downloadListView, listViewLayout);
		
		// 生成动态数组，加入数据
		pairs = new ArrayList<Pair<String,Integer>>();
		for (int i = 0; i < downloadVideoIds.length; i++) {
			Pair<String, Integer> pair = new Pair<String, Integer>(downloadVideoIds[i], R.drawable.download);
			pairs.add(pair);
		}

		downloadListViewAdapter = new DownloadListViewAdapter(context, pairs);
		downloadListView.setAdapter(downloadListViewAdapter);
		downloadListView.setOnItemClickListener(onItemClickListener);

		service = new Intent(context, DownloadService.class);
		activity.bindService(service, serviceConnection, Context.BIND_AUTO_CREATE);
		
		initDownloaderHashMap();
		
		return downloadRelativeLayout;
	}
	
	OnItemClickListener onItemClickListener = new OnItemClickListener() {

		@SuppressWarnings("unchecked")
		@Override
		public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
			//点击item时，downloader初始化使用的是设置清晰度方式
			Pair<String, Integer> pair = (Pair<String, Integer>) parent.getItemAtPosition(position);
			videoId = pair.first;
			
			downloader = new Downloader(videoId, ConfigUtil.USERID, ConfigUtil.API_KEY);
			downloader.setOnProcessDefinitionListener(onProcessDefinitionListener);
			downloader.getDefinitionMap();
		}
	};
	
	private void initDownloaderHashMap(){
		//初始化DownloaderHashMap
		List<DownloadInfo> downloadInfoList = DataSet.getDownloadInfos();
		for(int i = 0; i<downloadInfoList.size(); i++){
			DownloadInfo downloadInfo = downloadInfoList.get(i);
			if (downloadInfo.getStatus() == Downloader.FINISH) {
				continue;
			}
			
			String title = downloadInfo.getTitle();
			File file = MediaUtil.createFile(title);
			if (file == null ){
				continue;
			}
			
			String videoId = downloadInfo.getVideoId();
			Downloader downloader = new Downloader(file, videoId, ConfigUtil.USERID, ConfigUtil.API_KEY);
			
			int downloadInfoDefinition = downloadInfo.getDefinition();
			if (downloadInfoDefinition != -1){
				downloader.setDownloadDefinition(downloadInfoDefinition);
			}
			LbbDownload.downloaderHashMap.put(title, downloader);
		}
	}
	
	@SuppressLint("HandlerLeak") 
	private Handler handler = new Handler() {
		@Override
		public void handleMessage(Message msg) {
			String message = (String) msg.obj;
			if ( message.equals(POPUP_DIALOG_MESSAGE)) {
				String[] definitionMapValues = new String[hm.size()];
				definitionMapKeys = new int[hm.size()]; 
				Set<Map.Entry<Integer, String>> set = hm.entrySet();
				Iterator<Map.Entry<Integer, String>> iterator = set.iterator();
				int i = 0;
				while(iterator.hasNext()){
					Entry<Integer, String> entry = iterator.next();
					definitionMapKeys[i] = entry.getKey();
					definitionMapValues[i] = entry.getValue();
					i++;
				}
				
				AlertDialog.Builder builder = new Builder(activity);
				builder.setTitle("选择下载清晰度");
				builder.setSingleChoiceItems(definitionMapValues, 0, new DialogInterface.OnClickListener() {
					@Override
					public void onClick(DialogInterface dialog, int which) {
						
						int definition = definitionMapKeys[which];
						
						title = videoId + "-" + definition;
						if (DataSet.hasDownloadInfo(title)) {
							Toast.makeText(context, "文件已存在", Toast.LENGTH_SHORT).show();
							return;
						}
						
						File file = MediaUtil.createFile(title);
						if (file == null ){
							Toast.makeText(context, "创建文件失败", Toast.LENGTH_LONG).show();
							return;
						}
						
						if (binder == null || binder.isFree()) {
							Intent service = new Intent(context, DownloadService.class);
							service.putExtra("title", title);
							activity.startService(service);
						} else{
							Intent intent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
							activity.sendBroadcast(intent);
						}
						
						downloader.setFile(file); //确定文件名后，把文件设置到downloader里
						downloader.setDownloadDefinition(definition);
						LbbDownload.downloaderHashMap.put(title, downloader);
						DataSet.addDownloadInfo(new DownloadInfo(videoId, title, 0, null, Downloader.WAIT, new Date(), definition));
						
						definitionDialog.dismiss();
						Toast.makeText(context, "文件已加入下载队列", Toast.LENGTH_SHORT).show();
					}
				});
				definitionDialog = builder.create();
				definitionDialog.show();
			}
			
			if ( message.equals(GET_DEFINITION_ERROR)) {
				Toast.makeText(context, "网络异常，请重试", Toast.LENGTH_LONG).show();
			}
			super.handleMessage(msg);
		}
		
	};
	
	private OnProcessDefinitionListener onProcessDefinitionListener = new OnProcessDefinitionListener(){
		@Override
		public void onProcessDefinition(HashMap<Integer, String> definitionMap) {
			hm = definitionMap;
			if(hm != null){
				Message msg = new Message();
				msg.obj = POPUP_DIALOG_MESSAGE;
				handler.sendMessage(msg);
			} else {
				Log.e("get definition error", "视频清晰度获取失败");
			}
		}

		@Override
		public void onProcessException(DreamwinException exception) {
			Log.i("get definition exception", exception.getErrorCode().Value() + " : " + videoId);
			Message msg = new Message();
			msg.obj = GET_DEFINITION_ERROR;
			handler.sendMessage(msg);
		}
	};
	
	private class DownloadedReceiver extends BroadcastReceiver {
		
		@Override
		public void onReceive(Context context, Intent intent) {
			// 若下载出现异常，提示用户处理
			int errorCode = intent.getIntExtra("errorCode", ParamsUtil.INVALID);
			if (errorCode == ErrorCode.NETWORK_ERROR.Value()) {
				Toast.makeText(context, "网络异常，请检查", Toast.LENGTH_SHORT).show();
			} else if (errorCode == ErrorCode.PROCESS_FAIL.Value()) {
				Toast.makeText(context, "下载失败，请重试", Toast.LENGTH_SHORT).show();
			} else if (errorCode == ErrorCode.INVALID_REQUEST.Value()) {
				Toast.makeText(context, "下载失败，请检查帐户信息", Toast.LENGTH_SHORT).show();
			}
		}
	}
	
	@Override
	public void onDestroy() {
		if (serviceConnection != null) {
			activity.unbindService(serviceConnection);
		}
		
		activity.unregisterReceiver(receiver);
		super.onDestroy();
	}
	
	public class DownloadListViewAdapter extends VideoListViewAdapter{
		
		public DownloadListViewAdapter(Context context, List<Pair<String, Integer>> pairs){
			super(context, pairs);
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			
			Pair<String, Integer> pair = pairs.get(position);
			DownloadListView downloadListView = new DownloadListView(context, pair.first, pair.second);
			downloadListView.setTag(pair.first);
			return downloadListView;
		}

	}
	
	public class DownloadListView extends VideoListView{
		private Context context;
		
		public DownloadListView(Context context, String text, int resId) {
			super(context, text, resId);
			this.context = context;
			setImageListener();
		}
		
		//设置图片点击事件，点击图片的下载方式使用默认下载方式
		void setImageListener(){
			imageView.setOnClickListener(new OnClickListener() {
				@Override
				public void onClick(View v) {
					title = videoView.getText().toString();
					String videoId = title;
					
					if (DataSet.hasDownloadInfo(title)) {
						Toast.makeText(context, "文件已存在", Toast.LENGTH_SHORT).show();
						return;
					}
					
					File file = MediaUtil.createFile(title);
					if (file == null ){
						Toast.makeText(context, "创建文件失败", Toast.LENGTH_LONG).show();
						return;
					}
					
					downloader = new Downloader(file, videoId, ConfigUtil.USERID, ConfigUtil.API_KEY);
					LbbDownload.downloaderHashMap.put(title, downloader);
					DataSet.addDownloadInfo(new DownloadInfo(videoId, title, 0, null, Downloader.WAIT, new Date()));
					
					if (binder == null || binder.isFree()) {
						Intent service = new Intent(context, DownloadService.class);
						service.putExtra("title", title);
						activity.startService(service);
					} else{
						Intent intent = new Intent(ConfigUtil.ACTION_DOWNLOADING);
						activity.sendBroadcast(intent);
					}
					Toast.makeText(context, "文件已加入下载队列", Toast.LENGTH_SHORT).show();
				}
			});
		}
	}
}
