package com.bokecc.sdk.mobile.demo.download;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.os.Bundle;
import android.os.Environment;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.util.Pair;
import android.view.ContextMenu;
import android.view.ContextMenu.ContextMenuInfo;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnCreateContextMenuListener;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;

import com.bokecc.sdk.mobile.demo.R;
import com.bokecc.sdk.mobile.demo.adapter.VideoListViewAdapter;
import com.bokecc.sdk.mobile.demo.model.DownloadInfo;
import com.bokecc.sdk.mobile.demo.play.MediaPlayActivity;
import com.bokecc.sdk.mobile.demo.util.ConfigUtil;
import com.bokecc.sdk.mobile.demo.util.DataSet;
import com.bokecc.sdk.mobile.download.Downloader;

/**
 * 已下载标签页
 * 
 * @author CC视频
 *
 */
public class DownloadedFragment extends Fragment{

	private ListView downloadedListView;

	private List<Pair<String, Integer>> pairs;
	
	private Context context;

	private VideoListViewAdapter videoListViewAdapter;
	
	private FragmentActivity activity;
	
	private DownloadedReceiver receiver;
	
	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		activity = getActivity();
		context = activity.getApplicationContext();
		RelativeLayout downloadLayout = new RelativeLayout(activity.getApplicationContext());
		downloadLayout.setBackgroundColor(Color.WHITE);
		receiver = new DownloadedReceiver();
		activity.registerReceiver(receiver, new IntentFilter(ConfigUtil.ACTION_DOWNLOADED));
		
		downloadedListView = new ListView(context);
		downloadedListView.setPadding(10, 10, 10, 10);
		downloadedListView.setDivider(getResources().getDrawable(R.drawable.line));
		LayoutParams downloadedLayoutParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
		downloadLayout.addView(downloadedListView, downloadedLayoutParams);
		
		initData();

		downloadedListView.setOnItemClickListener(onItemClickListener);
		downloadedListView.setOnCreateContextMenuListener(onCreateContextMenuListener);

		return downloadLayout;
	}
	
	private void initData(){
		
		List<DownloadInfo> downloadInfos = DataSet.getDownloadInfos();

		pairs = new ArrayList<Pair<String,Integer>>();
		for (DownloadInfo downloadInfo : downloadInfos) {
			
			if (downloadInfo.getStatus() != Downloader.FINISH) {
				continue;
			}
			
			Pair<String, Integer> pair = new Pair<String, Integer>(downloadInfo.getTitle(), R.drawable.play);
			pairs.add(pair);
		}

		videoListViewAdapter = new VideoListViewAdapter(context, pairs);
		downloadedListView.setAdapter(videoListViewAdapter);
	}
	
	OnItemClickListener onItemClickListener = new OnItemClickListener() {
		@SuppressWarnings("unchecked")
		@Override
		public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
			Pair<String, Integer> pair = (Pair<String, Integer>) parent.getItemAtPosition(position);
			Intent intent = new Intent(context, MediaPlayActivity.class);
			intent.putExtra("videoId", pair.first);
			intent.putExtra("isLocalPlay", true);
			startActivity(intent);
		}
	};

	OnCreateContextMenuListener onCreateContextMenuListener = new OnCreateContextMenuListener() {
		@Override
		public void onCreateContextMenu(ContextMenu menu, View v, ContextMenuInfo menuInfo) {
			menu.setHeaderTitle("操作");
			menu.add(ConfigUtil.DOWNLOADED_MENU_GROUP_ID, 0, 0, "删除");
		}
	};
	
	@SuppressWarnings("unchecked")
	@Override
	public boolean onContextItemSelected(MenuItem item) {
		if (item.getGroupId() != ConfigUtil.DOWNLOADED_MENU_GROUP_ID) {
			return false;
		}
		
		int selectedPosition = ((AdapterContextMenuInfo) item.getMenuInfo()).position;
		
		Pair<String, Integer> pair = (Pair<String, Integer>)videoListViewAdapter.getItem(selectedPosition);
		
		DataSet.removeDownloadInfo(pair.first);
		
		File file = new File(Environment.getExternalStorageDirectory()+"/"+ConfigUtil.DOWNLOAD_DIR, pair.first+".mp4");
		if(file.exists()){
			file.delete();
		}
		
		initData();
		videoListViewAdapter.notifyDataSetChanged();
		downloadedListView.invalidate();
	
		if (getUserVisibleHint()) {
			return true;
		}

		return false;
	}

	private class DownloadedReceiver extends BroadcastReceiver{

		@Override
		public void onReceive(Context context, Intent intent) {
			
			initData();
			videoListViewAdapter.notifyDataSetChanged();
			downloadedListView.invalidate();
		}
		
	}

	@Override
	public void onDestroy() {
		activity.unregisterReceiver(receiver);
		super.onDestroy();
	}
	
}
