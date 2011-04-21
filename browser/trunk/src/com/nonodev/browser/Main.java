package com.nonodev.browser;

import java.util.HashMap;
import java.util.Map;
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
        Map<String, String> config = new HashMap<String, String>();
        config.put("username", properties.getString("username"));
        config.put("password", properties.getString("password"));
        config.put("url", properties.getString("url"));
        config.put("useragent", properties.getString("useragent"));
        boolean ignoreSSLTrustedCert = true;
        boolean ignoreSSLHostnameMatch = true;
        Browser browser = new Browser(config, ignoreSSLTrustedCert,
                ignoreSSLHostnameMatch);
        browser.FormLogin(browser.basicLogin());
        String html = browser.get("https://nonodev.com/its/my/page");
        System.out.println(html);
        browser.shutdownClient();
    }

    private static void test1(){
        Map<String, String> m = new HashMap<String, String>();
        m.put("user", "joakim");
        m.put("password", "secPasswd");
        System.out.println(m.get("user"));
        System.out.println(m.get("password"));
        System.out.println(m);

        ResourceBundle properties = null;
        try {
            properties = ResourceBundle.getBundle("com.nonodev.browser.productio");
        } catch (Exception e) {
            System.out.println(e.getMessage());
            System.out.println("Please copy default.properties to "
                    + "production.properties and set "
                    + "relevant properties for production.");
            System.exit(1);
        }
        System.out.println(properties.getString("url"));
        System.exit(0);
    }
}
