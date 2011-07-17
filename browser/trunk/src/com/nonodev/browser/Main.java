package com.nonodev.browser;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.ResourceBundle;
import org.apache.http.NameValuePair;
import org.apache.http.message.BasicNameValuePair;
import org.apache.log4j.PropertyConfigurator;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

public class Main {
    public static void main(String[] args) {
    	ClassLoader loader = Thread.currentThread().getContextClassLoader();
    	URL log4jUrl = loader.getResource("log4j.properties");
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
        
        InputStream content = browser.get(url);
        String authToken = null;
        Document doc = null;
        try {
			doc = Jsoup.parse(content, null, "");
			content.close();
		} catch (IOException e1) {
			e1.printStackTrace();
		}
        Element at =
        		doc.select("input[name=authenticity_token]").first();
        authToken = at.attr("value");
		
        List <NameValuePair> nvps = new ArrayList <NameValuePair>();
        nvps.add(new BasicNameValuePair("authenticity_token", authToken));
        nvps.add(new BasicNameValuePair("username", username));
        nvps.add(new BasicNameValuePair("password", password));
        String redirectLocation = browser.FormLogin(url, nvps);
        
        InputStream in = browser.get(redirectLocation);
        OutputStream out = System.out;
        int nextChar;
        try {
			while (( nextChar = in.read()) > -1) {
				out.write((char)nextChar);
			}
			out.write( '\n' );
			out.flush();
			in.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
        browser.shutdownClient();
    }
}
