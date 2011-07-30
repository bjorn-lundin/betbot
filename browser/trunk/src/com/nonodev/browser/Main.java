package com.nonodev.browser;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;
import java.util.ResourceBundle;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.apache.log4j.PropertyConfigurator;

public class Main {
	public static void main(String[] args) {
		ClassLoader loader = Thread.currentThread().getContextClassLoader();
		URL log4jUrl = loader.getResource("browser-log4j.properties");
		PropertyConfigurator.configure(log4jUrl);

		ResourceBundle properties = null;
		try {
			properties =
					ResourceBundle.getBundle("com.nonodev.browser.production");
		} catch (Exception e) {
			System.out.println(e.getMessage());
			System.out.println("Please copy default.properties to "
					+ "production.properties and set "
					+ "relevant properties for production.");
			System.exit(1);
		}
		String useragent = properties.getString("useragent");
		boolean allowAllHostname = Boolean.parseBoolean(
				properties.getString("allowAllHostname").toLowerCase());
		Browser browser = new Browser(useragent, allowAllHostname);


		String url = properties.getString("url");
		String username = properties.getString("username");
		String password = properties.getString("password");
		browser.basicLogin(url, null, username, password);

		String authToken = null;
//		<input name="authenticity_token" type="hidden" value="0MblOUmCBMigLEH/iaBepPG3gF/OrPqtYIvbtYh2xWY=" />
		String html = null;
		String re = "<input name=\"authenticity_token\".*?value=\"(.*?)\".*?>";
		Pattern p = Pattern.compile(re, (Pattern.CASE_INSENSITIVE | Pattern.DOTALL));
		html = browser.getAsString(url);
		System.out.println(html);
		Matcher m = p.matcher(html);
		
		if (m.find()) {
			System.out.println(m.group(1));
			authToken = m.group(1);
		} else {
			System.out.println("Nope!");
			System.exit(-1);
		}
		
		Map <String, String> keyValuePairs = new HashMap<String, String>();
		keyValuePairs.put("authenticity_token", authToken);
		keyValuePairs.put("username", username);
		keyValuePairs.put("password", password);

		String redirectLocation = browser.FormLogin(url, keyValuePairs);
		printStream(browser.get(redirectLocation));
		browser.shutdownClient();
	}
	
	private static void printStream(InputStream is) {
		OutputStream out = System.out;
		int nextChar;
		try {
			while (( nextChar = is.read()) > -1) {
				out.write((char)nextChar);
			}
			out.write( '\n' );
			out.flush();
			is.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
}
