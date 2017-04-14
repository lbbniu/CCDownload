package com.bokecc.sdk.mobile.demo.model;

/**
 * 某一任务正在下载时的信息
 * 
 * @author shichaohui@meiriq.com
 * 
 */
public class DownloadingInfo {

	private String kbps = "0"; // 每秒下载速度
	private long secondSize = 0; // 一秒钟累计下载量
	private long start = 0; // 文件大小
	private long end = 0;
	private int progress;
	private String progressText;

	public int getProgress() {
		return progress;
	}

	public void setProgress(int progress) {
		this.progress = progress;
	}

	public String getProgressText() {
		return progressText;
	}

	public void setProgressText(String progressText) {
		this.progressText = progressText;
	}

	public String getKbps() {
		return kbps;
	}

	public void setKbps(String kbps) {
		this.kbps = kbps;
	}

	public long getSecondSize() {
		return secondSize;
	}

	public void setSecondSize(long secondSize) {
		this.secondSize = secondSize;
	}
	public long getStart() {
		return start;
	}

	public void setStart(long start) {
		this.start = start;
	}
	public long getEnd() {
		return end;
	}

	public void setEnd(long end) {
		this.end = end;
	}

	@Override
	public String toString() {
		return "DownloadingInfo [kbps=" + kbps + ", secondSize=" + secondSize
				+ ", start=" + start + ", end="+ end +"]";
	}

}
