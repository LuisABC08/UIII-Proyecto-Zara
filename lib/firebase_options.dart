import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1msTTCI5bO7w6ju-fVtVJM73gxVwjlF4',
    appId: '1:745350814117:android:fd6bb192a1d0799aeaf04c',
    messagingSenderId: '745350814117',
    projectId: 'easydiet-568f1',
    storageBucket: 'easydiet-568f1.firebasestorage.app',
  );
}
