import 'package:catcher_2/handlers/base_email_handler.dart';
import 'package:catcher_2/model/platform_type.dart';
import 'package:catcher_2/model/report.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailAutoHandler extends BaseEmailHandler {
  final String smtpHost;
  final int smtpPort;
  final String senderEmail;
  final String senderName;
  final String senderPassword;
  final bool enableSsl;
  final List<String> recipients;
  final bool sendHtml;
  final bool printLogs;

  EmailAutoHandler(
    this.smtpHost,
    this.smtpPort,
    this.senderEmail,
    this.senderName,
    this.senderPassword,
    this.recipients, {
    this.enableSsl = false,
    this.sendHtml = true,
    this.printLogs = false,
    String? emailTitle,
    String? emailHeader,
    bool enableDeviceParameters = true,
    bool enableApplicationParameters = true,
    bool enableStackTrace = true,
    bool enableCustomParameters = true,
  })  : assert(recipients.isNotEmpty, "Recipients can't be null or empty"),
        super(
          enableDeviceParameters: enableDeviceParameters,
          enableApplicationParameters: enableApplicationParameters,
          enableStackTrace: enableStackTrace,
          enableCustomParameters: enableCustomParameters,
          emailTitle: emailTitle,
          emailHeader: emailHeader,
        );

  @override
  Future<bool> handle(Report error, BuildContext? context) => _sendMail(error);

  Future<bool> _sendMail(Report report) async {
    try {
      final message = Message()
        ..from = Address(senderEmail, senderName)
        ..recipients.addAll(recipients)
        ..subject = getEmailTitle(report)
        ..text = setupRawMessageText(report);

      if (report.screenshot != null) {
        message.attachments = [FileAttachment(report.screenshot!)];
      }

      if (sendHtml) {
        message.html = setupHtmlMessageText(report);
      }
      _printLog('Sending email...');

      final result = await send(message, _setupSmtpServer());

      _printLog(
        'Email result: mail: ${result.mail} '
        'sending start time: ${result.messageSendingStart} '
        'sending end time: ${result.messageSendingEnd}',
      );

      return true;
    } catch (stacktrace, exception) {
      _printLog(stacktrace.toString());
      _printLog(exception.toString());
      return false;
    }
  }

  SmtpServer _setupSmtpServer() => SmtpServer(
        smtpHost,
        port: smtpPort,
        ssl: enableSsl,
        username: senderEmail,
        password: senderPassword,
      );

  void _printLog(String log) {
    if (printLogs) {
      logger.info(log);
    }
  }

  @override
  List<PlatformType> getSupportedPlatforms() => [
        PlatformType.android,
        PlatformType.iOS,
        PlatformType.web,
        PlatformType.linux,
        PlatformType.macOS,
        PlatformType.windows,
      ];
}
