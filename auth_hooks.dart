import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:like/like.dart';
import 'package:toastification/toastification.dart';
import 'package:scola_connect/core/config/environment.dart';
import 'package:scola_connect/core/constants/uri_manager.dart';
import 'package:scola_connect/core/toasts/toast_manager.dart';
import 'package:scola_connect/routes/app_routes.dart';
import 'package:scola_connect/routes/route_services.dart';
import 'package:scola_connect/storage/token_storage.dart';
import 'package:scola_connect/storage/userdata_storage.dart';

/// Centralized lifecycle and interception hooks for the application authentication module.
/// Bridges the [LikeAuthInterceptor] engine with app storage, routing, and Toast layers.
class AuthHooks {
  /// Resolves the current JWT access token from storage.
  static Future<String?> getToken() async => await TokenStorage.getToken();

  /// Executes the silent refresh token rotation flow.
  static Future<String?> refreshToken() async {
    final rToken = await TokenStorage.getRefreshToken();
    if (rToken == null || rToken.isEmpty) {
      debugPrint(
        "[AuthInterceptor] Silent refresh skipped: No refresh token stored.",
      );
      return null;
    }

    try {
      debugPrint("[AuthInterceptor] Initiating silent token refresh...");
      final dio = Dio(
        BaseOptions(
          baseUrl: LikeHelpers.normalizeBaseUrl(Environment.apiUrl),
          connectTimeout: Duration(seconds: LikeConstants.connectTimeout),
          receiveTimeout: Duration(seconds: LikeConstants.receiveTimeout),
          sendTimeout: Duration(seconds: LikeConstants.sendTimeout),
        ),
      );

      final response = await dio.post(
        UriManager.refreshToken,
        data: {'refresh_token': rToken},
        options: Options(
          headers: {
            'Content-Type': LikeConstants.defaultContentTypeHeader,
            'Accept': LikeConstants.defaultAcceptHeader,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null) {
          Map<String, dynamic> body;
          if (data is Map<String, dynamic>) {
            body = data;
          } else if (data is String) {
            body = Map<String, dynamic>.from(jsonDecode(data));
          } else {
            debugPrint(
              "[AuthInterceptor] Refresh failed: Unexpected response format.",
            );
            return null;
          }

          final newAccessToken = body['access_token'] ?? body['accessToken'];
          final newRefreshToken =
              body['refresh_token'] ?? body['refreshToken'] ?? rToken;

          if (newAccessToken != null && newAccessToken.toString().isNotEmpty) {
            debugPrint("[AuthInterceptor] Token refresh succeeded!");
            await TokenStorage.saveToken(
              newAccessToken.toString(),
              newRefreshToken.toString(),
            );
            return newAccessToken.toString();
          }
        }
      }
      debugPrint(
        "[AuthInterceptor] Token refresh failed with status: ${response.statusCode}",
      );
      return null;
    } catch (e) {
      debugPrint("[AuthInterceptor] Token refresh failed with exception: $e");
      return null;
    }
  }

  /// Triggers credential revocation and automatic user routing back to Login on expired session.
  static Future<void> onLogout({int? statusCode, bool force = false}) async {
    debugPrint(
      "[AuthInterceptor] Session dead/refresh failed. Clearing session...",
    );

    // Clear L1 session cache from LIKE engine
    LikeClient().clearSession();

    // Delete stored credentials and local application data
    await TokenStorage.deleteToken();
    await UserdataStorage.deleteAllData();

    // Redirect to login screen
    RouteServices.removeUntil(AppRoutes.login, (route) => false);

    // Show session expired notification to the user
    ToastManager.showToast(
      message: "Session Expired",
      submessage: "Please log in again to continue.",
      type: ToastificationType.warning,
    );
  }
}
