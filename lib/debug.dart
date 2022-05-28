import 'package:flutter/foundation.dart';

debugprint(String object) {
  if (kDebugMode) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(object).forEach((match) => print(match.group(0)));
  }
}
