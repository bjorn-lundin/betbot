package com.nonodev.downloader;

import java.util.ResourceBundle;
import com.nonodev.browser.Browser;

public abstract class Downloader implements Runnable {
	Browser browser;

	public Downloader(ResourceBundle properties) {
		this.browser = new Browser(properties);
	}
}