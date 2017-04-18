package com.bokecc.sdk.mobile.demo.play.controller;

import android.app.Activity;
import android.content.res.Configuration;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.RelativeLayout.LayoutParams;

import com.bokecc.sdk.mobile.demo.PlayDemoApplication;

public class PlayerUtil {

	// 获得当前屏幕的方向
	public static boolean isPortrait() {
		int mOrientation = PlayDemoApplication.getContext().getResources().getConfiguration().orientation;
		if (mOrientation == Configuration.ORIENTATION_LANDSCAPE) {
			return false;
		} else {
			return true;
		}
	}
	
	// 重新显示广告view的大小
	public static void resizeAdView(Activity activity, WindowManager wm, final ImageView iv, int adWidth, int adHeight) {
		if (adWidth == 0 || adHeight == 0) {
			return;
		}
		int screenWidth = wm.getDefaultDisplay().getWidth();
		int screenHeight = wm.getDefaultDisplay().getHeight();

		if (PlayerUtil.isPortrait()) {
			screenHeight = screenHeight * 2 / 5;
		} else {
			// 全屏下，广告素材为屏幕60%
			screenWidth = screenWidth * 6 / 10;
			screenHeight = screenHeight * 6 / 10;
		}

		// 等比缩放比例计算
		float widthRatio = (float) screenWidth / (float) adWidth;
		float heightRatio = (float) screenHeight / (float) adHeight;

		if (widthRatio > heightRatio) {
			screenWidth = (int) ((float) adWidth * heightRatio);
		} else {
			screenHeight = (int) ((float) adHeight * widthRatio);
		}
		
		final LayoutParams ivAdLayoutParams = new LayoutParams(screenWidth,
				screenHeight);
		ivAdLayoutParams.addRule(RelativeLayout.CENTER_IN_PARENT);

		activity.runOnUiThread(new Runnable() {

			@Override
			public void run() {
				iv.setLayoutParams(ivAdLayoutParams);
			}
		});
	}
}
