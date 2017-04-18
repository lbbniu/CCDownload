package com.bokecc.sdk.mobile.demo.play.controller;

import java.lang.ref.WeakReference;
import java.util.Calendar;

import android.content.pm.ActivityInfo;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;

import com.bokecc.sdk.mobile.demo.play.ADMediaPlayActivity;

public class PlayerSensorController implements SensorEventListener{

	private int mX, mY, mZ;
	private long lastTimeStamp = 0;
	private Calendar mCalendar;
	private WeakReference<ADMediaPlayActivity> mWeakReference;
	
	public PlayerSensorController(ADMediaPlayActivity activity) {
		mWeakReference = new WeakReference<ADMediaPlayActivity>(activity);
	}

	@Override
	public void onSensorChanged(SensorEvent event) {
		if (mWeakReference.get() == null) {
			return;
		}
		if (event.sensor == null) {
			return;
		}

		if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
			int x = (int) event.values[0];
			int y = (int) event.values[1];
			int z = (int) event.values[2];
			mCalendar = Calendar.getInstance();
			long stamp = mCalendar.getTimeInMillis() / 1000l;

			int second = mCalendar.get(Calendar.SECOND);// 53

			int px = Math.abs(mX - x);
			int py = Math.abs(mY - y);
			int pz = Math.abs(mZ - z);

			int maxvalue = getMaxValue(px, py, pz);
			if (maxvalue > 2 && (stamp - lastTimeStamp) > 1) {
				lastTimeStamp = stamp;
				mWeakReference.get().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR);
			}
			mX = x;
			mY = y;
			mZ = z;
		}
	}

	private int getMaxValue(int px, int py, int pz) {
		int max = 0;
		if (px > py && px > pz) {
			max = px;
		} else if (py > px && py > pz) {
			max = py;
		} else if (pz > px && pz > py) {
			max = pz;
		}

		return max;
	}

	@Override
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
		
	}
}
