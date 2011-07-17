package com.nonodev.downloader;

import java.util.ResourceBundle;
import com.nonodev.browser.Browser;

public abstract class Downloader implements Runnable {
	Browser browser;

	public Downloader(ResourceBundle properties) {
		initBrowser(properties);
	}

	private void initBrowser(ResourceBundle properties) {
		String useragent = properties.getString("useragent");
		boolean allowAllHostname = 
				Boolean.parseBoolean(properties.
						getString("allowAllHostname").toLowerCase());
		this.browser = new Browser(useragent, allowAllHostname);
	}
}		
