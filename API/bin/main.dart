import 'package:conduit/conduit.dart';
import 'dart:io';
import 'package:dart_application_1/dart_application_1.dart';


void main() async {
  final port = int.parse(Platform.environment["PORT"] ?? '8888');
  final service = Application<AppService>()
    ..options.port = port;
    //..options.configurationFilePath = 'config.yaml';

    await service.start(numberOfInstances: 3, consoleLogging: true);
}
