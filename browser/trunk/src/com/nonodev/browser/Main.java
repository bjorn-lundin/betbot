package com.nonodev.browser;

import java.util.ResourceBundle;

public class Main {
    public static void main(String[] args) {
        //test1();
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
        Browser browser = new Browser(properties);
        //System.out.println(browser.get("https://secure.pensionsmyndigheten.se/"));
        //System.out.println(browser.get("http://pensionsmyndigheten.se/"));
        
        //System.out.println(browser.get("https://nonodev.com"));
        //System.exit(99);
        
        browser.FormLogin(browser.basicLogin());
        String html = browser.get("https://nonodev.com/its/my/page");
        System.out.println(html);
        browser.shutdownClient();
    }
}
