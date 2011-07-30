package com.nonodev.downloader;

import java.util.Random;
import java.util.ResourceBundle;
import org.apache.log4j.Logger;
import com.nonodev.browser.Browser;

public abstract class Downloader implements Runnable {
	static Logger logger = Logger.getLogger(Downloader.class.getName());
	protected Browser browser = null;
	protected int minDownloadDelay = -1;
	protected int maxDownloadDelay = -1;

	public Downloader(ResourceBundle properties) {
		initBrowser(properties);
		this.minDownloadDelay = 
				Integer.parseInt(properties.getString("minDownloadDelay"));
		this.maxDownloadDelay = 
				Integer.parseInt(properties.getString("maxDownloadDelay"));
	}

	private void initBrowser(ResourceBundle properties) {
		String useragent = properties.getString("useragent");
		boolean allowAllHostname = 
				Boolean.parseBoolean(properties.
						getString("allowAllHostname").toLowerCase());
		this.browser = new Browser(useragent, allowAllHostname, false);
	}
	
	protected void downloadDelay() {
		Random rand = new Random();
		long sleep = -1;
		sleep = rand.nextInt(maxDownloadDelay * 1000 - minDownloadDelay * 1000) 
				+ minDownloadDelay * 1000;
		logger.debug("DOWNLOAD PAUSE " + sleep + " microseconds");
		try {
			Thread.sleep(sleep);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
}		
