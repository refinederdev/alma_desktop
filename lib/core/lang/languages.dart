import 'package:get/get.dart';

import 'ar.dart';
import 'en.dart';

class Languages implements Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar_SA': ArLang.keys,
    'en_US': EnLang.keys,
  };
}
