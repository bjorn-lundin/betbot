package com.nonodev.downloader;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.io.Writer;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CodingErrorAction;

public class Util {

	public static void main(String[] args) {
		String p1 = "C:/_dev/workspace/downloader/data";
		String p2 = "C:\\_dev\\workspace\\downloader\\data";
		String p3 = "C:/_dev/workspace/downloader/data/";
		String p4 = "C:\\_dev\\workspace\\downloader\\data\\";

		System.out.println(platformPath(p1));
		System.out.println(platformPath(p2));
		System.out.println(platformPath(p3));
		System.out.println(platformPath(p4));
	}

	public static String platformPath(String path) {
		String[] parts = path.split("[/\\\\]");
		StringBuilder result = new StringBuilder();
		for (String part:parts) {
			result.append(part + File.separator);
		}
		return result.toString();
	}

	public static void fileToFileConvertEncoding(File infile, 
			File outfile, String from, String to)
					throws IOException, UnsupportedEncodingException {
		// Set up byte streams.
		InputStream in;
		if (infile != null)
			in = new FileInputStream(infile);
		else
			in = System.in;
		OutputStream out;
		if (outfile != null)
			out = new FileOutputStream(outfile);
		else
			out = System.out;

		// Use default encoding if no encoding is specified.
		if (from == null)
			//from = System.getProperty("file.encoding");
			from = Charset.defaultCharset().toString();
		if (to == null)
			//			to = System.getProperty("file.encoding");
			to = Charset.defaultCharset().toString();

		// Set up character streams.
		Reader r = new BufferedReader(new InputStreamReader(in, from));
		Writer w = new BufferedWriter(new OutputStreamWriter(out, to));

		// Copy characters from input to output. The InputStreamReader
		// converts from the input encoding to Unicode, and the
		// OutputStreamWriter converts from Unicode to the output encoding.
		// Characters that cannot be represented in the output encoding are
		// output as '?'
		char[] buffer = new char[4096];
		int len;
		while ((len = r.read(buffer)) != -1)
			// Read a block of input.
			w.write(buffer, 0, len); // And write it out.
		r.close(); // Close the input.
		w.close(); // Flush and close output.
	}

	public static void streamToFileConvertEncoding(
			InputStream inStream, File outFile, String from, String to)
					throws IOException, UnsupportedEncodingException {
		if (from == null)
			from = Charset.defaultCharset().toString();
		if (to == null)
			to = Charset.defaultCharset().toString();

		CharsetDecoder decoder = Charset.forName(from).newDecoder();
		CharsetEncoder encoder = Charset.forName(to).newEncoder();
		decoder.onMalformedInput(CodingErrorAction.IGNORE);
		decoder.onUnmappableCharacter(CodingErrorAction.IGNORE);
		encoder.onMalformedInput(CodingErrorAction.IGNORE);
		encoder.onUnmappableCharacter(CodingErrorAction.IGNORE);

		final int BUFFER_SIZE = 10000;
		ByteArrayOutputStream outStream = 
				new ByteArrayOutputStream(BUFFER_SIZE);
		byte[] buffer = new byte[BUFFER_SIZE];
		int r = -1;
		while ((r = inStream.read(buffer)) > -1) {
			outStream.write(buffer,0,r);
		}
		inStream.close();

		ByteBuffer inByteBuffer = ByteBuffer.wrap(outStream.toByteArray());
		CharBuffer decCharBuffer = decoder.decode(inByteBuffer);
		ByteBuffer encByteBuffer = encoder.encode(decCharBuffer);

		boolean append = false;
		FileChannel wChannel = 
				new FileOutputStream(outFile, append).getChannel();
		wChannel.write(encByteBuffer);
		wChannel.close();
	}

	public static void streamToFileRaw(InputStream inStream, File outFile)
			throws IOException {
		OutputStream out = new FileOutputStream(outFile);
		int read=0;
		final int BUFFER_SIZE = 10000;
		byte[] bytes = new byte[BUFFER_SIZE];
		while((read = inStream.read(bytes))!= -1){
			out.write(bytes, 0, read);
		}
		inStream.close();
		out.flush();
		out.close();	
	}

	/**
	 * 
	 * @param inStream
	 * @param outStream
	 * @param from
	 * @param to
	 * @throws IOException
	 * @throws UnsupportedEncodingException
	 */
	public static void streamToStreamConvertEncoding(
			InputStream inStream, OutputStream outStream, String from,
			String to) throws IOException, UnsupportedEncodingException {
		if (from == null)
			from = Charset.defaultCharset().toString();
		if (to == null)
			to = Charset.defaultCharset().toString();

		CharsetDecoder decoder = Charset.forName(from).newDecoder();
		CharsetEncoder encoder = Charset.forName(to).newEncoder();
		decoder.onMalformedInput(CodingErrorAction.IGNORE);
		decoder.onUnmappableCharacter(CodingErrorAction.IGNORE);
		encoder.onMalformedInput(CodingErrorAction.IGNORE);
		encoder.onUnmappableCharacter(CodingErrorAction.IGNORE);

		final int BUFFER_SIZE = 10000;
		ByteArrayOutputStream parseStream = 
				new ByteArrayOutputStream(BUFFER_SIZE);
		byte[] buffer = new byte[BUFFER_SIZE];
		int r = -1;
		while ((r = inStream.read(buffer)) > -1) {
			parseStream.write(buffer,0,r);
		}
		inStream.close();

		ByteBuffer inByteBuffer = ByteBuffer.wrap(parseStream.toByteArray());
		CharBuffer decCharBuffer = decoder.decode(inByteBuffer);
		ByteBuffer encByteBuffer = encoder.encode(decCharBuffer);

		encByteBuffer.clear();
		buffer = new byte[encByteBuffer.capacity()];
		encByteBuffer.get(buffer, 0, buffer.length);
		outStream.write(buffer);
	}

	public static InputStream fileToStream(File file)
			throws IOException {
		FileInputStream fis = null;
		DataInputStream dis = null;
		try {
			fis = new FileInputStream(file);
			dis = new DataInputStream(fis);

		} catch (IOException e) {
			e.printStackTrace();
		}
		return dis;
	}

	public static String streamToStringSetEncoding(InputStream inStream,
			String encoding) throws IOException {
		String result = null;
		if (inStream != null) {
			Writer writer = new StringWriter();
			char[] buffer = new char[1024];
			try {
				Reader reader = new BufferedReader(
						new InputStreamReader(inStream, encoding));
				int n;
				while ((n = reader.read(buffer)) != -1) {
					writer.write(buffer, 0, n);
				}
			}
			finally {
				inStream.close();
			}
			result = writer.toString();
		}
		return result;
	}

	public static StringBuilder streamToStringBuilderSetEncoding(InputStream inStream,
			String encoding) throws IOException {
		StringBuilder result = null;
		if (inStream != null) {
			Writer writer = new StringWriter();
			char[] buffer = new char[1024];
			try {
				Reader reader = new BufferedReader(
						new InputStreamReader(inStream, encoding));
				int n;
				while ((n = reader.read(buffer)) != -1) {
					writer.write(buffer, 0, n);
				}
			}
			finally {
				inStream.close();
			}
			result = new StringBuilder(writer.toString());
		}
		return result;
	}

	public static String fileToStringSetEncoding(File file,
			String encoding) throws IOException {
		String result = null;
		if (file != null) {
			FileInputStream fis = new FileInputStream(file);
			Reader reader = new BufferedReader(
					new InputStreamReader(fis, encoding));
			Writer writer = new StringWriter();
			char[] buffer = new char[1024];
			int n;
			while ((n = reader.read(buffer)) > -1) {
					writer.write(buffer, 0, n);
				}
			result = writer.toString();
		}
		return result;
	}

	public static StringBuilder fileToStringBuilderSetEncoding(File file,
			String encoding) throws IOException {
		StringBuilder result = null;
		if (file != null) {
			FileInputStream fis = new FileInputStream(file);
			Reader reader = new BufferedReader(
					new InputStreamReader(fis, encoding));
			Writer writer = new StringWriter();
			char[] buffer = new char[1024];
			int n;
			while ((n = reader.read(buffer)) > -1) {
				writer.write(buffer, 0, n);
			}
			result = new StringBuilder(writer.toString());
		}
		return result;
	}
}
