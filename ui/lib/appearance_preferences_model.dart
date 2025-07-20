import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearancePreferencesModel extends ChangeNotifier {
  bool _showAvatars = false;
  bool _colorBodySentiment = true;
  SharedPreferences? sharedPrefs;

  AppearancePreferencesModel() {
    SharedPreferences.getInstance().then((p) {
      sharedPrefs = p;
      showAvatars = p.getBool("show_avatars") ?? false;
      colorBodySentiment = p.getBool("show_body_sentiment") ?? true;
    });
  }

  bool get showAvatars => _showAvatars;
  set showAvatars (bool v)  {
    _showAvatars = v;
    sharedPrefs?.setBool("show_avatars", v);
    notifyListeners();
  }

  bool get colorBodySentiment => _colorBodySentiment;
  set colorBodySentiment (bool v)  {
    _colorBodySentiment = v;
    sharedPrefs?.setBool("show_body_sentiment", v);
    notifyListeners();
  }
}
