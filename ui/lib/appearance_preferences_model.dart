import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearancePreferencesModel extends ChangeNotifier {
  bool _showAvatars = false;
  SharedPreferences? sharedPrefs;

  AppearancePreferencesModel() {
    SharedPreferences.getInstance().then((p) {
      sharedPrefs = p;
      showAvatars = p.getBool("show_avatars") ?? false;
    });
  }

  get showAvatars => _showAvatars;
  set showAvatars (v)  {
    _showAvatars = v;
    sharedPrefs?.setBool("show_avatars", v);
    notifyListeners();
  }
}
