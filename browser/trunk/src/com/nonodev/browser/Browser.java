package com.nonodev.browser;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.NameValuePair;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.ClientProtocolException;
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
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.params.HttpProtocolParams;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HTTP;
import org.apache.http.protocol.HttpContext;
import org.apache.http.util.EntityUtils;
import org.apache.log4j.Logger;

public class Browser {
	static Logger logger = Logger.getLogger(Browser.class.getName());
	private DefaultHttpClient httpclient = null;

	public Browser(String useragent, boolean allowAllHostname) {
		initClient(useragent, allowAllHostname);
	}

	private void initClient(String useragent, boolean allowAllHostname) {
		/*
		 * Learn more and adjust
		 * http://hc.apache.org/httpcomponents-client-ga/examples.html
		 * example "Threaded request execution"
		 */
		ThreadSafeClientConnManager cm = new ThreadSafeClientConnManager();
		cm.setMaxTotal(10);
		httpclient = new DefaultHttpClient(cm);

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
						long keepAlive = 
								super.getKeepAliveDuration(response, context);
						if (keepAlive == -1) {
							// Keep connections alive 5 seconds if a keep-alive value
							// has not be explicitly set by the server
							keepAlive = 5000;
						}
						return keepAlive;
					}
				});
		logger.info("USERAGENT " + " " + 
				httpclient.getParams().
				getParameter(HttpProtocolParams.USER_AGENT));
	}

	public void shutdownClient() {
		httpclient.getConnectionManager().shutdown();
		logger.info("Client shutdown");
	}

	public InputStream get(String url) {
		HttpGet httpget = new HttpGet(url);
		HttpResponse response = null;
		HttpEntity entity = null;
		InputStream content = null;
		try {
			response = httpclient.execute(httpget);
			entity = response.getEntity();
			content = entity.getContent();
		} catch (ClientProtocolException e1) {
			e1.printStackTrace();
		} catch (IOException e1) {
			e1.printStackTrace();
		} catch (IllegalStateException e) {
			e.printStackTrace();
		} finally {
			//httpclient.getConnectionManager().shutdown();
		}

		logger.info("GET " + url + " " + 
				response.getStatusLine() + " " + 
				response.getEntity().getContentLength());

		return content;
	}
	
	public InputStream post(String url, Map<String, String> keyValuePairs) {
		HttpResponse response = null;
		HttpEntity entity = null;
		List <NameValuePair> nvp = null;
		InputStream content = null;

		try {
			HttpPost httpost = new HttpPost(url);
			HttpContext context = new BasicHttpContext();
	        nvp = new ArrayList <NameValuePair>();
	        for (String key : keyValuePairs.keySet()) {
	        	nvp.add(new BasicNameValuePair(key, keyValuePairs.get(key)));
			}
			httpost.setEntity(new UrlEncodedFormEntity(nvp, HTTP.UTF_8));
			response = httpclient.execute(httpost, context);
			entity = response.getEntity();
			content = entity.getContent();
		} catch (Exception e) {
			e.getStackTrace();
		} finally {
			//httpclient.getConnectionManager().shutdown();
		}

		logger.info("POST " + url + " " + 
				response.getStatusLine() + " " + 
				response.getEntity().getContentLength());

		if (logger.isDebugEnabled()) {
			List<Cookie> cookies = httpclient.getCookieStore().getCookies();
			if (cookies != null) {
				for (int i = 0; i < cookies.size(); i++) {
					logger.debug("COOKIE " + cookies.get(i).toString());
				}
			}
			if (nvp != null) {
				for (int i = 0; i < nvp.size(); i++) {
					logger.debug("FORM PARAM " + nvp.get(i).toString());
				}
			}
		}
		return content;
	}
	
	/**
	 * 
	 * @param url
	 * @param basicRealm
	 * @param username
	 * @param password
	 * @return
	 */
	public void basicLogin(String url, String basicRealm, String username,
			String password) {
		HttpGet httpget = new HttpGet(url);
		HttpResponse response = null;
		HttpEntity entity = null;
		try {
			httpclient.getCredentialsProvider().setCredentials(
					new AuthScope(basicRealm, 443),
					new UsernamePasswordCredentials(username, password));
			response = httpclient.execute(httpget);
			entity = response.getEntity();
			EntityUtils.consume(entity);
		} catch (ClientProtocolException e1) {
			e1.printStackTrace();
		} catch (IOException e1) {
			e1.printStackTrace();
		} catch (IllegalStateException e) {
			e.printStackTrace();
		} finally {
			//httpclient.getConnectionManager().shutdown();
		}

		logger.info("BASIC LOGIN " + url + " " + 
				response.getStatusLine() + " " + 
				response.getEntity().getContentLength());

		if (logger.isDebugEnabled()) {
			logger.debug("USERNAME " + username);
			logger.debug("PASSWORD " + password);
		}
	}

	/**
	 * 
	 * @param url
	 * @param keyValuePairs
	 * @return
	 */
	public String FormLogin(String url, Map<String, String> keyValuePairs) {
		String redirectLocation = null;
		HttpResponse response = null;
		HttpEntity entity = null;
		List <NameValuePair> nvp = null;

		try {
			HttpPost httpost = new HttpPost(url);
			HttpContext context = new BasicHttpContext();
	        nvp = new ArrayList <NameValuePair>();
	        for (String key : keyValuePairs.keySet()) {
	        	nvp.add(new BasicNameValuePair(key, keyValuePairs.get(key)));
			}
			httpost.setEntity(new UrlEncodedFormEntity(nvp, HTTP.UTF_8));
			response = httpclient.execute(httpost, context);
			entity = response.getEntity();
			if (response.getStatusLine().getStatusCode() != HttpStatus.SC_OK) {
				Header[] headers = response.getHeaders("Location");
				if (headers != null && headers.length != 0) {
					redirectLocation = headers[headers.length - 1].getValue();
				}
			}
			EntityUtils.consume(entity);
		} catch (Exception e) {
			e.getStackTrace();
		} finally {
			//httpclient.getConnectionManager().shutdown();
		}

		logger.info("FORM LOGIN " + url + " " + 
				response.getStatusLine() + " " + 
				response.getEntity().getContentLength());

		logger.info("REDIRECT " + redirectLocation);

		if (logger.isDebugEnabled()) {
			List<Cookie> cookies = httpclient.getCookieStore().getCookies();
			if (cookies != null) {
				for (int i = 0; i < cookies.size(); i++) {
					logger.debug("COOKIE " + cookies.get(i).toString());
				}
			}
			if (nvp != null) {
				for (int i = 0; i < nvp.size(); i++) {
					logger.debug("FORM PARAM " + nvp.get(i).toString());
				}
			}
		}

		return redirectLocation;
	}
}
