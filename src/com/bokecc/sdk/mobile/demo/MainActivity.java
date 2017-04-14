package com.bokecc.sdk.mobile.demo;

import android.annotation.SuppressLint;
import android.app.ActionBar;
import android.app.ActionBar.Tab;
import android.app.ActionBar.TabListener;
import android.app.FragmentTransaction;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.view.ViewPager;
import android.support.v4.view.ViewPager.OnPageChangeListener;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;

import com.bokecc.sdk.mobile.demo.download.DownloadFragment;
import com.bokecc.sdk.mobile.demo.download.DownloadListActivity;
import com.bokecc.sdk.mobile.demo.play.PlayFragment;
import com.bokecc.sdk.mobile.demo.upload.UploadFragment;
import com.bokecc.sdk.mobile.demo.util.ConfigUtil;
import com.bokecc.sdk.mobile.demo.util.DataSet;
import com.bokecc.sdk.mobile.demo.util.LogcatHelper;
import com.bokecc.sdk.mobile.util.HttpUtil;
import com.bokecc.sdk.mobile.util.HttpUtil.HttpLogLevel;

/**
 * 
 * Demo主界面，包括播放、上传、下载三个标签页
 * 
 * @author CC视频
 *
 */
@SuppressLint("NewApi")
public class MainActivity extends FragmentActivity implements TabListener {

	private ViewPager viewPager;
	
	private static String[] TAB_TITLE = {"播放", "上传", "下载"};
	
	private TabFragmentPagerAdapter adapter;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);
		LogcatHelper.getInstance(this).start();
		HttpUtil.LOG_LEVEL = HttpLogLevel.DETAIL;
		viewPager = (ViewPager) this.findViewById(R.id.pager);
		
		initView();
		
		DataSet.init(this);
		
	}

	private void initView() {
		
		final ActionBar actionBar = getActionBar();
		
		actionBar.setDisplayHomeAsUpEnabled(false);
		actionBar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);
		
		adapter = new TabFragmentPagerAdapter(getSupportFragmentManager());
		viewPager.setAdapter(adapter);
		
		for (int i = 0; i < ConfigUtil.MAIN_FRAGMENT_MAX_TAB_SIZE;i++){
			Tab tab = actionBar.newTab();
			tab.setText(TAB_TITLE[i]).setTabListener(this);
			actionBar.addTab(tab);
		}
		
		viewPager.setOnPageChangeListener(new OnPageChangeListener() {
			
			@Override
			public void onPageSelected(int arg0) {
				
				actionBar.setSelectedNavigationItem(arg0);
			}
			
			@Override
			public void onPageScrolled(int arg0, float arg1, int arg2) {}
			
			@Override
			public void onPageScrollStateChanged(int arg0) {}
		});
	}

	public static class TabFragmentPagerAdapter extends FragmentPagerAdapter{

		private Fragment[] fragments;
		
		public TabFragmentPagerAdapter(FragmentManager fm) {
			super(fm);
			fragments = new Fragment[]{new PlayFragment(), new UploadFragment(), new DownloadFragment()};
		}

		@Override
		public Fragment getItem(int position) {
			return fragments[position];
			
		}
		@Override
		public int getCount() {
			
			return ConfigUtil.MAIN_FRAGMENT_MAX_TAB_SIZE;
		}
	}
	
	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.downloadItem:
			startActivity(new Intent(getApplicationContext(), DownloadListActivity.class));
			break;

		case R.id.accountInfo:
			startActivity(new Intent(getApplicationContext(), AccountInfoActivity.class));
			break;
		}
		
		return super.onOptionsItemSelected(item);
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		
		getMenuInflater().inflate(R.menu.main, menu);
		
		return super.onCreateOptionsMenu(menu);
	}

	@Override
	public void onTabSelected(Tab tab, FragmentTransaction ft) {
		viewPager.setCurrentItem(tab.getPosition());
	}

	@Override
	public void onTabUnselected(Tab tab, FragmentTransaction ft) {
		
	}

	@Override
	public void onTabReselected(Tab tab, FragmentTransaction ft) {
		
	}
	
	@Override
	protected void onDestroy() {
		Log.i("data", "save data... ...");
		DataSet.saveData();
		LogcatHelper.getInstance(this).stop();
		super.onDestroy();
	}
	
}
