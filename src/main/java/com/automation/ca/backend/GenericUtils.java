package com.automation.ca.backend;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import org.apache.commons.io.FileUtils;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;

import javax.crypto.spec.SecretKeySpec;
import javax.crypto.Mac;

import org.apache.commons.codec.binary.Hex;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import java.nio.charset.StandardCharsets;

public class GenericUtils {

    /**
     * Returns a MAP object of the JSON string
     * 
     * @param jsonString a JSON string
     * @return A MAP object of the JSON string
     */
    public static Map<String, String> convertJSONStringToMap(String jsonString) {
        ObjectMapper mapper = new ObjectMapper();
        Map<String, String> output = null;
        try {

            output = mapper.readValue(jsonString, Map.class);

        } catch (IOException e) {
            e.printStackTrace();
        }
        return output;
    }

    /**
     * Returns an HMAC SHA256 hashed object
     * 
     * @param data The data to be hashed
     * @param key  The key to be used to hash
     * @return an HMAC SHA256 hashed object
     */
    public static byte[] HmacSHA256(String data, byte[] key) throws Exception {
        String algorithm = "HmacSHA256";
        Mac mac = Mac.getInstance(algorithm);
        mac.init(new SecretKeySpec(key, algorithm));
        return mac.doFinal(data.getBytes("UTF-8"));
    }

    /**
     * Returns a HEX String of a converted BYTE
     * 
     * @param byteData the byte data to be converted
     * @return a HEX String of a converted BYTE
     */
    public static String convertByteToHexString(byte[] byteData) {
        char[] result = Hex.encodeHex(byteData);
        return new String(result);
    }

    /**
     * Returns a SHA256 hashed object
     * 
     * @param data The data to be hashed
     * @return a SHA256 hashed object
     */
    public static byte[] hashSHA256(String data) throws NoSuchAlgorithmException {
        MessageDigest digest = null;
        try {
            digest = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            System.err.println(e.getMessage());
            throw e;
        }
        byte[] output = digest.digest(data.getBytes(StandardCharsets.UTF_8));
        return output;
    }

    /**
     * Returns the current date time for a given format
     * 
     * @param format The date time format
     * @return the current date time for a given format
     */
    public static String getCurrentDateTime(String format) {
        SimpleDateFormat sdfDate = new SimpleDateFormat(format);
        sdfDate.setTimeZone(TimeZone.getTimeZone("UTC"));
        Date now = new Date();
        String strDate = sdfDate.format(now);
        return strDate;
    }

    /**
     * Returns a stringified text of a multiline text
     * 
     * @param data The multiline text to be stringified
     * @return a stringified text of a multiline text
     */
    public static String stringify(String data) {
        data = data.replaceAll("\r", "\\\\r");
        data = data.replaceAll("\n", "\\\\n");
        data = data.replaceAll("\t", "\\\\t");
        data = data.replaceAll("\"", "\\\\\"");
        return data;
    }

    /**
     * Returns an ISO String of the current date
     *
     * @return The ISO String of the current date
     */
    public static String CreateDate() {
        TimeZone tz = TimeZone.getTimeZone("GMT");
        // DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm'Z'"); // Quoted "Z"
        // to indicate UTC, no timezone offset
        DateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm"); // Quoted "Z" to indicate UTC, no timezone offset
        df.setTimeZone(tz);
        String nowAsISO = df.format(new Date());
        // System.out.println("--------Printing Date-------"+ nowAsISO);

        return nowAsISO;
    }

    /**
     * Returns the full string of an HTML page
     *
     * @return The full string of an HTML page
     */
    public static String getHTML_String() {
        String Path = System.getProperty("user.dir");
        StringBuilder contentBuilder = new StringBuilder();
        try {
            BufferedReader in = new BufferedReader(
                    new FileReader(Path + "/target/CustomReport.html/CustomReport.html"));
            String str;
            while ((str = in.readLine()) != null) {
                contentBuilder.append(str);
            }
            in.close();
        } catch (IOException e) {
        }
        return contentBuilder.toString();

    }

    /**
     * Updates custom report with data
     */
    public static void UpdateReport(String ID, int cell) {

        String html = getHTML_String();
        // System.out.println("-------Print Html Before change------"+ html);
        Document document = Jsoup.parse(html);
        Elements Table_Row = document.getElementsByAttributeValue("id", ID);
        Element Table_Cell = Table_Row.select("td").get(cell);
        Table_Cell.html("<td>Pass</td>");
        // System.out.println("-------Print Html after change------"+
        // document.outerHtml());
        WriteResultFile(document.outerHtml());
    }

    /**
     * Writes custom report with data
     */
    private static void WriteResultFile(String Text) {
        try {
            String Path = System.getProperty("user.dir");
            FileWriter myWriter = new FileWriter(Path + "/target/CustomReport.html/CustomReport.html");
            myWriter.write(Text);
            myWriter.close();
            // System.out.println("Successfully wrote to the file.");
        } catch (IOException e) {
            System.out.println("An error occurred.");
            e.printStackTrace();
        }

    }

    /**
     * Copy custom report to target folder
     */
    public static void BeforeAll() {
        String Path = System.getProperty("user.dir");

        try {
            File srcFile = new File(Path + "/src/test/java/CA/CustomReport.html");
            File destDir = new File(Path + "/target/CustomReport.html");
            FileUtils.copyFileToDirectory(srcFile, destDir);
        } catch (Exception e) {

        }

    }

}