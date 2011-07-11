package com.nonodev.browser;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
import java.util.ResourceBundle;
import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.NameValuePair;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.ssl.AllowAllHostnameVerifier;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.conn.ssl.TrustStrategy;
import org.apache.http.conn.ssl.X509HostnameVerifier;
import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.DefaultConnectionKeepAliveStrategy;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HTTP;
import org.apache.http.protocol.HttpContext;
import org.apache.http.util.EntityUtils;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

public class Browser {
    private String username = null;
    private String password = null;
    private String url = null;
    private String useragent = null;
    private String basicRealm = null;
    private boolean allowAllHostname = false;
    private DefaultHttpClient httpclient = null;

    public Browser(ResourceBundle properties) {
        this.useragent = properties.getString("useragent");
        this.username = properties.getString("username");
        this.password = properties.getString("password");
        this.url = properties.getString("url");
        this.allowAllHostname = Boolean.parseBoolean(
        		properties.getString("allowAllHostname").toLowerCase());
        initClient();
    }

    public void shutdownClient() {
        httpclient.getConnectionManager().shutdown();
    }

    private void initClient() {
        httpclient = new DefaultHttpClient();
        
        if (allowAllHostname) {
	        TrustStrategy trustStrategy = new TrustSelfSignedStrategy();
	        X509HostnameVerifier hostnameVerifier = 
	        		new AllowAllHostnameVerifier();
	        try {
	            SSLSocketFactory sf =
	                    new SSLSocketFactory(trustStrategy, hostnameVerifier);
	            Scheme scheme = new Scheme("https", 443, sf);
	            httpclient.getConnectionManager().getSchemeRegistry().
	            		register(scheme);
	        }
	        catch (Exception e) {
	            e.getStackTrace();
	        }
        }
        
        httpclient.getParams().setParameter(
        		HttpProtocolParams.USER_AGENT, useragent);
        httpclient.setKeepAliveStrategy(
        		new DefaultConnectionKeepAliveStrategy() {
            @Override
            public long getKeepAliveDuration(HttpResponse response,
                    HttpContext context) {
                long keepAlive = super.getKeepAliveDuration(response, context);
                if (keepAlive == -1) {
                    // Keep connections alive 5 seconds if a keep-alive value
                    // has not be explicitly set by the server
                    keepAlive = 5000;
                }
                return keepAlive;
            }
        });
    }

    private String getContent(HttpEntity he) {
        StringBuilder sb = null;
        try {
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(he.getContent()));
            sb = new StringBuilder();
            String line = null;
            while ((line = reader.readLine()) != null) {
              sb.append(line);
              sb.append("\n");
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        return sb.toString();
    }

    public String get(String url) {
        HttpGet httpget = new HttpGet(url);
        HttpResponse response = null;
        String content = null;
        
        try {
            response = httpclient.execute(httpget);
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }
        if (null != response) {
        	content = getContent(response.getEntity());
        }
        return content;
    }

    public String basicLogin() {
        String authToken = null;
        System.out.println("httpclient user-agent parameter:");
        System.out.println(httpclient.getParams().getParameter("USER_AGENT"));
        try {
            httpclient.getCredentialsProvider().setCredentials(
                    new AuthScope(basicRealm, 443),
                    new UsernamePasswordCredentials(username, password));
            HttpGet httpget = new HttpGet(url);
            System.out.println("executing request" + httpget.getRequestLine());
            HttpResponse response = httpclient.execute(httpget);
            HttpEntity entity = response.getEntity();
            if (entity != null) {
                System.out.println("----------------------------------------");
                System.out.println(response.getStatusLine());
                System.out.println("ContentEncoding: " +
                        entity.getContentEncoding());
                System.out.println("ContentType: " +
                        entity.getContentType());
                System.out.println("Response content length: " +
                        entity.getContentLength());
                /*
                 * Working
                 */
                /*
                Document doc = Jsoup.parse(entity.getContent(), null, "");
                Element content = doc.getElementById("login-form");
                System.out.println(content);
                Element form = content.getElementsByTag("form").first();
                System.out.println(form);
                Element input = form.getElementsByTag("input").first();
                System.out.println(input.attr("value"));
                */
                Document doc = Jsoup.parse(entity.getContent(), null, "");
                Element at =
                        doc.select("input[name=authenticity_token]").first();
                System.out.println(at.attr("value"));
                authToken = at.attr("value");
                System.out.println(getContent(entity));
            }
            EntityUtils.consume(entity);
        } catch (Exception e) {
            System.out.println(e.getMessage());
        } finally {
            // When HttpClient instance is no longer needed,
            // shut down the connection manager to ensure
            // immediate deallocation of all system resources
            //httpclient.getConnectionManager().shutdown();
        }
        return authToken;
    }

    public String FormLogin(String authToken) {
        String redirectLocation = null;
        try {
            HttpGet httpget = new HttpGet(url);
            HttpResponse response = httpclient.execute(httpget);
            HttpEntity entity = response.getEntity();
            System.out.println("Login form get: " + response.getStatusLine());
            EntityUtils.consume(entity);
            System.out.println("Initial set of cookies:");
            List<Cookie> cookies = httpclient.getCookieStore().getCookies();
            if (cookies.isEmpty()) {
                System.out.println("None");
            } else {
                for (int i = 0; i < cookies.size(); i++) {
                    System.out.println("- " + cookies.get(i).toString());
                }
            }
            HttpPost httpost = new HttpPost("https://nonodev.com/its/login");
            HttpContext context = new BasicHttpContext();
            List <NameValuePair> nvps = new ArrayList <NameValuePair>();
            nvps.add(new BasicNameValuePair("authenticity_token", authToken));
            nvps.add(new BasicNameValuePair("username", username));
            nvps.add(new BasicNameValuePair("password", password));
            httpost.setEntity(new UrlEncodedFormEntity(nvps, HTTP.UTF_8));
            response = httpclient.execute(httpost, context);
            /*
            if (response.getStatusLine().getStatusCode() != HttpStatus.SC_OK)
                throw new IOException(response.getStatusLine().toString());
            
            HttpUriRequest currentReq = (HttpUriRequest) context.getAttribute( 
                    ExecutionContext.HTTP_REQUEST);
            HttpHost currentHost = (HttpHost)  context.getAttribute( 
                    ExecutionContext.HTTP_TARGET_HOST);
            String currentUrl = currentHost.toURI() + currentReq.getURI();
            */
            if (response.getStatusLine().getStatusCode() != HttpStatus.SC_OK) {
                Header[] headers = response.getHeaders("Location");
                if (headers != null && headers.length != 0) {
                    redirectLocation = headers[headers.length - 1].getValue();
                }
            }
            System.out.println("Location: " + response. getAllHeaders());
            entity = response.getEntity();
            System.out.println(getContent(entity));
            EntityUtils.consume(entity);
            System.out.println("Login form get: " + response.getStatusLine());
            System.out.println("Post logon cookies:");
            cookies = httpclient.getCookieStore().getCookies();
            if (cookies.isEmpty()) {
                System.out.println("None");
            } else {
                for (int i = 0; i < cookies.size(); i++) {
                    System.out.println("- " + cookies.get(i).toString());
                }
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        } finally {
            // When HttpClient instance is no longer needed,
            // shut down the connection manager to ensure
            // immediate deallocation of all system resources
            //httpclient.getConnectionManager().shutdown();
        }
        return redirectLocation;
    }
}

