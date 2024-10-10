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
    apiKey: 'AIzaSyBgLfCw4h-vj3mh8zr8V1xKQwvY3Nh0c_U',
    appId: '1:434793832350:web:b450be7532979dd70e808f',
    messagingSenderId: '434793832350',
    projectId: 'emoniot-fb5ce',
    authDomain: 'emoniot-fb5ce.firebaseapp.com',
    storageBucket: 'emoniot-fb5ce.appspot.com',
    measurementId: 'G-ZD8WTMG7LY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzZotbO7QzJETNeV8Sl_N-IEi-v-hVpTo',
    appId: '1:434793832350:android:c0b9d1c4eee126eb0e808f',
    messagingSenderId: '434793832350',
    projectId: 'emoniot-fb5ce',
    storageBucket: 'emoniot-fb5ce.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0APZoQ2W3I9Q6wODzpCMuCj6ok4KDejY',
    appId: '1:434793832350:ios:be3b3cff82e58d3f0e808f',
    messagingSenderId: '434793832350',
    projectId: 'emoniot-fb5ce',
    storageBucket: 'emoniot-fb5ce.appspot.com',
    iosBundleId: 'com.example.emonappV1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA0APZoQ2W3I9Q6wODzpCMuCj6ok4KDejY',
    appId: '1:434793832350:ios:be3b3cff82e58d3f0e808f',
    messagingSenderId: '434793832350',
    projectId: 'emoniot-fb5ce',
    storageBucket: 'emoniot-fb5ce.appspot.com',
    iosBundleId: 'com.example.emonappV1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBgLfCw4h-vj3mh8zr8V1xKQwvY3Nh0c_U',
    appId: '1:434793832350:web:614d981ac923e0130e808f',
    messagingSenderId: '434793832350',
    projectId: 'emoniot-fb5ce',
    authDomain: 'emoniot-fb5ce.firebaseapp.com',
    storageBucket: 'emoniot-fb5ce.appspot.com',
    measurementId: 'G-NHB3PHH3XP',
  );
}
