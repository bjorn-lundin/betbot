package com.nonodev.downloader;

import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;
import java.util.ResourceBundle;

public class DownloaderKanal75 extends Downloader implements Runnable {
	ResourceBundle properties = null;
	String username = null;
	String password = null;
	String url = null;
	
	public DownloaderKanal75(ResourceBundle properties) {
		super(properties);
		this.username = properties.getString("username");
		this.password = properties.getString("password");
		this.url = properties.getString("url");
	}

	@Override
	public void run() {
		System.out.println("Running in thread...");
//		browser.FormLogin(browser.basicLogin());
		
		File file = new File("C:/_dev/workspace/downloader/data/","test.html");
		
		try {
			Util.streamToFileConvertEncoding(browser.get(url),
					file, null, Charset.forName("ISO-8859-1"));
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

//		System.out.print(browser.getAsString(url));
//	    System.out.println(html);
	    browser.shutdownClient();	

	}


}
