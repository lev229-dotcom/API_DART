import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

//АБстрактный класс для работы с token
abstract class AppUtilts {
  const AppUtilts._();

  static int getIdFromToken(String token) {
    try {
      final key = Platform.environment["SECKET_KEY"] ?? 'SECRET_KEY';
      final jwtClaim = verifyJwtHS256Signature(token, key);
      return int.parse(jwtClaim["id"].toString());
    } catch (e) {
      rethrow;
    }
  }

  static int getIdFromHeader(String header) {
    try {
      final token = const AuthorizationBearerParser().parse(header);
      final id = getIdFromToken(token ?? "");
      return id;
    } catch (e) {
      rethrow;
    }
  }
}
