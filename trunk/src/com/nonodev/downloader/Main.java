package com.nonodev.downloader;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.util.ResourceBundle;

public class Main {
	public static void main(String[] args) {

		String propertyFile = null;
		if (args.length < 1) {
			System.out.println("No property file in args");
			System.exit(-1);
		} else {
			propertyFile = args[0];
		}
		
		String classPath = null;
		classPath = getClassPath(Main.class.getName());

		ResourceBundle properties = null;
		try {
			properties = 
					ResourceBundle.getBundle(classPath + "." + propertyFile);
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(-1);
		}
		
		Downloader downloader = 
				getDownloader(properties, classPath);
		
		Thread thread = new Thread(downloader);
		thread.run();
	}

	private static String getClassPath(String className) {
		String classPath = null;
		int lastDot = className.lastIndexOf ('.');
		if (lastDot != -1) {
			classPath = className.substring (0, lastDot);
		} else {
			classPath = "";
		}
		return classPath;
	}

	@SuppressWarnings("unchecked")
	private static Downloader getDownloader(ResourceBundle properties,
			String classPath) {
		Downloader downloader = null;
		String downloaderClassString = properties.getString("class");
		Class<Downloader> downloaderClass = null;
		try {
			downloaderClass = (Class<Downloader>) 
					Class.forName(classPath + "." + downloaderClassString);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
		
		Constructor<Downloader> constructor = null;
		try {
			constructor = downloaderClass.getConstructor(
					new Class[]{ResourceBundle.class});
		} catch (NoSuchMethodException e1) {
			e1.printStackTrace();
		}
		
		try {
			downloader = (Downloader)constructor.newInstance(
					new Object[]{properties});
		} catch (InvocationTargetException e) {
			e.printStackTrace();
		} catch (InstantiationException e) {
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			e.printStackTrace();
		}
		return downloader;
	}
}
