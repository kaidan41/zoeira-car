// GERADO AUTOMATICAMENTE por scripts\gerar_firebase_options.ps1
// Nao edite manualmente. Rode o script de novo se trocar o google-services.json.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('App Android-only; web nao suportado.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions nÃ£o estÃ¡ configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5-e2cWFx3yzfjCVuMEu9bxPKxX30aA40',
    appId: '1:414915249554:android:4e4d87e7e1fc4c66a4ed4b',
    messagingSenderId: '414915249554',
    projectId: 'zoeira-car',
    storageBucket: 'zoeira-car.appspot.com',
    authDomain: 'zoeira-car.firebaseapp.com',
  );
}