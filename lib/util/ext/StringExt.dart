extension ExtString on String {
  String dotText(int endIdx) {
    if(length >= endIdx) {
      return "${substring(0, endIdx)}..";
    } else {
      return "$this..";
    }
  }

  bool containsIgnoreCase(String str) {
    return toLowerCase().contains(str.toLowerCase());
  }
}
