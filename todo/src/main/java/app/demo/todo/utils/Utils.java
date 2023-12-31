package app.demo.todo.utils;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

public class Utils {
  private static DateFormat DATE_FORMAT = new SimpleDateFormat("yyyy-MM-dd HH:mm a z");

  public static String toJsonValueContent(String value) {
    if (value == null)
      return "null";
    return value.replace("\'", "\\'").replace("\"", "\\\"");
  }

  public static String toJsonValueContent(Date value) {
    if (value == null)
      return "null";
    return DATE_FORMAT.format(value);
  }

  public static String shortenString(String value) {

    return shortenString(value, 7);
    // if (value == null) {
    // return "";
    // }

    // if (value.length() <= 5) {
    // return value;
    // }

    // return value.substring(0, 4) + "...";
  }

  public static String shortenString(String value, int maxLength) {

    if (value == null) {
      return "";
    }

    if (maxLength < 7) {
      maxLength = 7;
    }

    if (value.length() <= maxLength) {
      return value;
    }

    return value.substring(0, maxLength - 3) + "...";
  }
}
