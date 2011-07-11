package com.nonodev.downloader;

import java.util.ResourceBundle;

public class DownloaderKanal75 extends Downloader implements Runnable {

	public DownloaderKanal75(ResourceBundle properties) {
		super(properties);
	}

	@Override
	public void run() {
		System.out.println("Running in thread...");
		//System.exit(-1);
		
		browser.FormLogin(browser.basicLogin());
	    String html = browser.get("https://nonodev.com/its/my/page");
	    System.out.println(html);
	    browser.shutdownClient();	

	}


}
