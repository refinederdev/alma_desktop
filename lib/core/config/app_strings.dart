class AppStrings {
  static const String tokenKey = "token";
  static const String userKey = "user";
  static const String country = "country";

  static const String noImageUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/1665px-No-Image-Placeholder.svg.png";

  static String textCutter({String? text, required int criteria}) {
    String output = "";
    if (text != null) {
      if (text.length > criteria) {
        output = "${text.substring(0, criteria)} ... ";
      } else {
        output = text;
      }
    }
    return output;
  }

  static String removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    return htmlText.replaceAll(exp, '');
  }
}
