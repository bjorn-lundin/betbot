package com.nonodev.browser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLException;
import javax.net.ssl.SSLSession;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.conn.ssl.X509HostnameVerifier;
import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.SingleClientConnManager;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpParams;
import org.apache.http.protocol.HTTP;
import org.apache.http.util.EntityUtils;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

class Browser {
    private String username = null;
    private String password = null;
    private String url = null;
    private String useragent = null;
    private String basicRealm = null;
    private boolean ignoreSSLTrustedCert = true;
    private boolean ignoreSSLHostnameMatch = true;
    private DefaultHttpClient httpclient = null;

    public Browser(Map<String, String> config, boolean ignoreSSLTrustedCert,
            boolean ignoreSSLHostnameMatch) {
        this.useragent = config.get("useragent");
        this.username = config.get("username");
        this.password = config.get("password");
        this.url = config.get("url");
        this.basicRealm = config.get("basicRealm");
        this.ignoreSSLTrustedCert = ignoreSSLTrustedCert;
        this.ignoreSSLHostnameMatch = ignoreSSLHostnameMatch;
        initClient();
    }

    public void shutdownClient() {
        httpclient.getConnectionManager().shutdown();
    }

    private void initClient() {
        if (ignoreSSLTrustedCert) {
            try {
                SSLSocketFactory sf = null;
                // Set up a TrustManager that trusts
                // everything (self signed et.al.)
                SSLContext sslContext = SSLContext.getInstance("SSL");
                sslContext.init(null, new TrustManager[] {
                    new X509TrustManager() {
                        public X509Certificate[] getAcceptedIssuers() {
                            return null;
                        }

                        public void checkClientTrusted(X509Certificate[] certs,
                                String authType) {
                        }

                        public void checkServerTrusted(X509Certificate[] certs,
                                String authType) {
                        }
                    }
                }, new SecureRandom());
                sf = new SSLSocketFactory(sslContext);

                if (ignoreSSLHostnameMatch) {
                    sf.setHostnameVerifier(new X509HostnameVerifier() {
                        public boolean verify(String hostname,
                                SSLSession session) {
                            return true;
                        }

                        public void verify(String host, String[] cns, String[]
                                subjectAlts) throws SSLException {
                        }

                        public void verify(String host, X509Certificate cert)
                                throws SSLException {
                        }

                        public void verify(String host, SSLSocket ssl)
                                throws IOException {
                        }
                    });
                }

                Scheme httpsScheme = new Scheme("https", sf, 443);
                SchemeRegistry schemeRegistry = new SchemeRegistry();
                schemeRegistry.register(httpsScheme);
                HttpParams params = new BasicHttpParams();
                ClientConnectionManager cm = new SingleClientConnManager(params,
                        schemeRegistry);
                httpclient = new DefaultHttpClient(cm, params);
            }
            catch (Exception e) {
            }
        } else {
            httpclient = new DefaultHttpClient();
        }
        httpclient.getParams().setParameter("USER_AGENT", useragent);
    }

    //public void basicLogin() throws Exception {
    public void basicLogin() {
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

                Document doc = Jsoup.parse(entity.getContent(), null, "");
                //Element link = doc.select("a").first();

                //Element content = doc.getElementById("content");
                //Elements links = content.getElementsByTag("input");
                Elements links = doc.getElementsByTag("input");
                for (Element link : links) {
                  //System.out.println(link.attr("value"));
                  //System.out.println(link.getElementsByAttribute("tabindex"));
                  System.out.println(link.getAllElements());
                  //System.out.println(link.text());
                }
                System.exit(25);
                Element link = doc.select("input").first();

                //String text = doc.body().text(); // "An example link"
                //String linkHref = link.attr("href"); // "http://example.com/"
                String linkHref = link.attr("value"); // "http://example.com/"
                String linkText = link.text(); // "example""

                System.out.println(linkHref + linkText);

                BufferedReader reader = new BufferedReader(
                        new InputStreamReader(entity.getContent()));
                StringBuilder sb = new StringBuilder();
                String line = null;
                while ((line = reader.readLine()) != null) {
                  sb.append(line);
                  sb.append("\n");
                }
                System.out.println("Content:\n" + sb.toString());
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
    }

    public void FormLogin() throws Exception {
        //DefaultHttpClient httpclient = new DefaultHttpClient();
        try {
            
             //HttpGet httpget = new HttpGet("https://portal.sun.com/portal/dt");
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

            List <NameValuePair> nvps = new ArrayList <NameValuePair>();
            nvps.add(new BasicNameValuePair("IDToken1", "username"));
            nvps.add(new BasicNameValuePair("IDToken2", "password"));

            httpost.setEntity(new UrlEncodedFormEntity(nvps, HTTP.UTF_8));

            response = httpclient.execute(httpost);
            entity = response.getEntity();

            System.out.println("Login form get: " + response.getStatusLine());
            EntityUtils.consume(entity);

            System.out.println("Post logon cookies:");
            cookies = httpclient.getCookieStore().getCookies();
            if (cookies.isEmpty()) {
                System.out.println("None");
            } else {
                for (int i = 0; i < cookies.size(); i++) {
                    System.out.println("- " + cookies.get(i).toString());
                }
            }

        } finally {
            // When HttpClient instance is no longer needed,
            // shut down the connection manager to ensure
            // immediate deallocation of all system resources
            //httpclient.getConnectionManager().shutdown();
        }
    }

    // For execution context see
    // http://hc.apache.org/httpcomponents-client-ga/tutorial/html/fundamentals.html

}

