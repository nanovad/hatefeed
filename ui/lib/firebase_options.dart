// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9i9L1R3yMyx1qYejEPeMG8d4glAr5Hzw',
    appId: '1:745668140557:web:9aaef4f7080b355ad93f44',
    messagingSenderId: '745668140557',
    projectId: 'hatefeed-ee623',
    authDomain: 'hatefeed-ee623.firebaseapp.com',
    storageBucket: 'hatefeed-ee623.firebasestorage.app',
    measurementId: 'G-N72EX2H8BE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtQc07JBKoS-V6KVngCBETzVmYMkoO02k',
    appId: '1:745668140557:android:3e00e1c38c286001d93f44',
    messagingSenderId: '745668140557',
    projectId: 'hatefeed-ee623',
    storageBucket: 'hatefeed-ee623.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDB7e0xHMtkOu90heDHslttUHKohpjQLyM',
    appId: '1:745668140557:ios:706813b617649f60d93f44',
    messagingSenderId: '745668140557',
    projectId: 'hatefeed-ee623',
    storageBucket: 'hatefeed-ee623.firebasestorage.app',
    iosBundleId: 'com.example.hatefeed',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDB7e0xHMtkOu90heDHslttUHKohpjQLyM',
    appId: '1:745668140557:ios:706813b617649f60d93f44',
    messagingSenderId: '745668140557',
    projectId: 'hatefeed-ee623',
    storageBucket: 'hatefeed-ee623.firebasestorage.app',
    iosBundleId: 'com.example.hatefeed',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC9i9L1R3yMyx1qYejEPeMG8d4glAr5Hzw',
    appId: '1:745668140557:web:4953cd5e697b008bd93f44',
    messagingSenderId: '745668140557',
    projectId: 'hatefeed-ee623',
    authDomain: 'hatefeed-ee623.firebaseapp.com',
    storageBucket: 'hatefeed-ee623.firebasestorage.app',
    measurementId: 'G-EJ86100F52',
  );
}
