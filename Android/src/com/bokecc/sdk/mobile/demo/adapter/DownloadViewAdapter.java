package com.bokecc.sdk.mobile.demo.adapter;

import java.util.List;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;

import com.bokecc.sdk.mobile.demo.model.DownloadInfo;
import com.bokecc.sdk.mobile.demo.view.DownloadView;

public class DownloadViewAdapter extends BaseAdapter{
	
	private List<DownloadInfo> downloadInfos;

	private Context context;

	public DownloadViewAdapter(Context context, List<DownloadInfo> downloadInfos){
		this.context = context;
		this.downloadInfos = downloadInfos;
	}

	@Override
	public int getCount() {
		return downloadInfos.size();
	}

	@Override
	public Object getItem(int position) {
		return downloadInfos.get(position);
	}

	@Override
	public long getItemId(int position) {
		return position;
	}

	@Override
	public View getView(int position, View convertView, ViewGroup parent) {
		DownloadInfo downloadInfo = downloadInfos.get(position);
		if (convertView == null) {
			DownloadView downloadView = new DownloadView(context, 
					downloadInfo.getTitle(),
					downloadInfo.getStatusInfo(),
					downloadInfo.getProgressText(),
					downloadInfo.getProgress());
			
			downloadView.setTag(downloadInfo.getTitle());
			
			return downloadView;
		} else if (convertView instanceof DownloadView) {
			DownloadView downloadView = (DownloadView) convertView;
			
			// 若当前视图为缓存视图，则只更新进度
			if (downloadView.getTitle().equals(downloadInfo.getTitle())) {
				
				downloadView.setProgress(downloadInfo.getProgress());
				downloadView.setProgressText(downloadInfo.getProgressText());
			} else {
				downloadView = new DownloadView(context, 
						downloadInfo.getTitle(),
						downloadInfo.getStatusInfo(),
						downloadInfo.getProgressText(),
						downloadInfo.getProgress());
				
				downloadView.setTag(downloadInfo.getTitle());
			}
			
			return downloadView;
		} else {
			
			return convertView;
		}
		
	}
}
