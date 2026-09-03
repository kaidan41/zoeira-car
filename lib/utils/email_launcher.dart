import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// E-mail de contato oficial do Zoeira Car.
const String zoeiraCarEmail = 'zoeiracarcontato@gmail.com';

/// Abre o app de e-mail direto (Gmail se estiver instalado) com a mensagem
/// pré-preenchida para o e-mail do Zoeira Car — sem o seletor de apps do
/// Android. Retorna false se não conseguiu abrir nada.
Future<bool> launchRequestEmail({
  required String subject,
  required String body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: zoeiraCarEmail,
    queryParameters: {'subject': subject, 'body': body},
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: uri.toString(),
        package: 'com.google.android.gm', // Gmail direto, sem seletor
      );
      await intent.launch();
      return true;
    } on PlatformException {
      // Gmail não instalado — cai no seletor padrão
    } on Exception {
      // Outra falha ao lançar o intent — cai no seletor padrão
    }
  }

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}