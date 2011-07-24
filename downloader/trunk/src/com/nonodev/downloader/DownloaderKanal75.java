package com.nonodev.downloader;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.log4j.Logger;

public class DownloaderKanal75 extends Downloader {
	static Logger logger = Logger.getLogger(DownloaderKanal75.class.getName());
	private String path = null;
	private String username = null;
	private String password = null;
	private String url = null;
	
	public DownloaderKanal75(ResourceBundle properties) {
		super(properties);
		this.path = Util.platformPath(properties.getString("path"));
		this.username = properties.getString("username");
		this.password = properties.getString("password");
		this.url = properties.getString("url");
	}
	
	@Override
	public void run() {
		logger.info("THREAD " + Thread.currentThread().getName());
		File kanal75_1 = new File(path,"kanal75_1.html");
		File kanal75_2 = new File(path,"kanal75_2.html");
		File kanal75_3 = new File(path,"kanal75_3.html");
		boolean fromNet = true;
		String isoEnc = "ISO-8859-1";
		String utfEnc = "UTF-8";
		StringBuilder workSB = null;
		StringBuilder regexp = null;
		Pattern pattern = null;
		Matcher matcher = null;
		String actionUrl = null;
		Map <String, String> keyValuePairs = null;
		
		workSB = new StringBuilder();
		try {
			if (fromNet) {
				Util.streamToFileConvertEncoding(browser.get(url), kanal75_1, utfEnc, isoEnc);
			}
			workSB = Util.fileToStringBuilderSetEncoding(kanal75_1, isoEnc);
		} catch (IOException e) {
			e.printStackTrace();
		}

		regexp = new StringBuilder("<form.*?action=\"(.*?)\".*?>");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE | 
				Pattern.DOTALL));
		matcher = pattern.matcher(workSB);
		if (matcher.find()) {
			actionUrl = matcher.group(1);
			logger.info("ACTION URL " + actionUrl);
		}
		
		regexp = new StringBuilder("<input.*?(?:name|value)=\"(.*?)\".*?" +
					"(?:name|value)=\"(.*?)\".*?>");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE | 
				Pattern.DOTALL));
		matcher = pattern.matcher(workSB);
		
		keyValuePairs = new HashMap<String, String>();
		while(matcher.find()) {
			keyValuePairs.put(matcher.group(1), matcher.group(2));
        }
		keyValuePairs.put("ssousername", username);
		keyValuePairs.put("password", password);
		
		if (logger.isDebugEnabled()) {
			for (String key : keyValuePairs.keySet()) {
				logger.debug("KEY/VALUE " + key + "=" + keyValuePairs.get(key));
			}
		}
		
		if (fromNet) {
			actionUrl = browser.FormLogin(actionUrl, keyValuePairs);
			logger.info("ACTION URL " + actionUrl);
		}
		
		// Manually copied from iframe tag
		String resultMainPage = "/pls/portal/infolagret_app.Webshell.getmainpage?p_name=RES";
		actionUrl = url + resultMainPage;
		logger.info("ACTION URL MANUAL " + actionUrl);
		
		workSB = new StringBuilder();
		try {
			if (fromNet) {
				Util.streamToFileConvertEncoding(browser.get(actionUrl), kanal75_2, utfEnc, isoEnc);
			}
			workSB = Util.fileToStringBuilderSetEncoding(kanal75_2, isoEnc);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		regexp = new StringBuilder("<a href=\"(.*?redirect_link.*?)\">Aktuella resultat</A>");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE));
		matcher = pattern.matcher(workSB);
		if (matcher.find()) {
			actionUrl = matcher.group(1);
			logger.info("ACTION URL " + actionUrl);
		}

		/*
		 * For date specific lookup
		regexp = new StringBuilder("<form action=\"(.*?redirect_form.*?)\".*?name=\"(.*?)\".*?value=\"(.*?)\"");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE));
		matcher = pattern.matcher(workSB);
		if (matcher.find()) {
			actionUrl = matcher.group(1);
			logger.info("ACTION URL " + actionUrl);
			logger.info("KEY/VALUE " + matcher.group(2) + "=" + matcher.group(3));
		}
		*/
		
		workSB = new StringBuilder();
		try {
			if (fromNet) {
				Util.streamToFileConvertEncoding(browser.get(url + actionUrl), kanal75_3, utfEnc, isoEnc);
			}
			workSB = Util.fileToStringBuilderSetEncoding(kanal75_3, isoEnc);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		regexp = new StringBuilder("<a href=\"(.*?redirect_link.*?)\">(.*?)</A>");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE));
		matcher = pattern.matcher(workSB);
//		while (matcher.find()) {
//			actionUrl = matcher.group(1);
//			logger.info("EVENT URL " + matcher.group(2) + " " + actionUrl);
//		}
		if (matcher.find()) {
			actionUrl = matcher.group(1);
			logger.info("EVENT URL " + matcher.group(2) + " " + actionUrl);
		}

		workSB = new StringBuilder();
		try {
			if (fromNet) {
				Util.streamToFileConvertEncoding(browser.get(url + actionUrl), 
						new File(path + "kanal75_4.html"), utfEnc, isoEnc);
			}
			workSB = Util.fileToStringBuilderSetEncoding(
					new File(path + "kanal75_4.html"), isoEnc);
		} catch (IOException e) {
			e.printStackTrace();
		}

//		<TR class="ingvartab">
//		<TD ALIGN="left">Resultat kompletta</TD>
//		<TD>11-07-24 18:22</TD>
//		<TD ALIGN="center">1</TD>
//		<TD align="CENTER"><a href="/pls/portal/infolagret_app.webshell.redirect_link?pin_arg=5D43328CA6EE3E5B61D125058E200D0A84F23C16C5A6C63FA10336BDBE72332C7CFD689B796900CE70DBB4D980E8BEBD76A6A6516DA90CEBB768AB78E9CDB5D70F0EB180CDBE1FC46CE7139AA21C6614226612AD93BF87C61520C9CF12897F0E059FCF31CFF49025206D37893B149B51D97D133E3536BFA92A81B3787D3FA3BF77A78A18E0C525C355A8F6E99F8CC20C6A37AE385E57BB1F6FDC5BB14099BA86"><img border="0" src="/ingvarimg/pc.gif" alt="txt" width="12" heigth="12"></A></TD>
//		<TD></TD>
//		</TR>
		
		regexp = new StringBuilder("Resultat kompletta.*?<a href=\"(.*?redirect_link.*?)\"");
		pattern = Pattern.compile(regexp.toString(), (Pattern.CASE_INSENSITIVE | Pattern.DOTALL));
		matcher = pattern.matcher(workSB);
		if (matcher.find()) {
			actionUrl = matcher.group(1);
			logger.info("ACTION URL " + actionUrl);
		}

		workSB = new StringBuilder();
		try {
			if (fromNet) {
				Util.streamToFileRaw(browser.get(url + actionUrl), 
						new File(path + "res_kompl.txt"));
			}
			workSB = Util.fileToStringBuilderSetEncoding(
					new File(path + "res_kompl.txt"), utfEnc);
		} catch (IOException e) {
			e.printStackTrace();
		}

	    browser.shutdownClient();	
	}
}
