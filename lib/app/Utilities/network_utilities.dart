import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class NetworkUtilities {
  /// returns Dio client with enabled certificate verification for APIs,
  /// a logging inspector and basic configurations
  ///
  static String baseUrl = 'https://amped-express.interakt.ai/api/v17.0/';
  static Dio getDioClient() {
    Dio dioClient = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // headers: {
        //   "ApiAccessAuthentication": ApiConstants.apiToken,
        // },
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 60), // 60 seconds
        receiveTimeout: const Duration(seconds: 60), // 60 seconds
        validateStatus: (status) {
          if (status == null) return false;
          return true;
        },
      ),
    );

    //Adding interceptors to log request and response data for all API calls for debugging
    dioClient.interceptors.add(
      PrettyDioLogger(
        enabled: kDebugMode,
        error: true,
        requestBody: true,
        requestHeader: true,
        responseBody: true,
        responseHeader: true,
        logPrint: (object) {
          Utilities.dLog(object);
        },
      ),
    );

    //to avoid 'CERTIFICATE_VERIFY_FAILED: Hostname mismatch' error
    // dioClient.httpClientAdapter = IOHttpClientAdapter(
    //   createHttpClient: () {
    //     // Don't trust any certificate just because their root cert is trusted.
    //     final HttpClient client =
    //         HttpClient(context: SecurityContext(withTrustedRoots: false));
    //     // You can test the intermediate / root cert here. We just ignore it.
    //     client.badCertificateCallback =
    //         ((X509Certificate cert, String host, int port) => true);
    //     return client;
    //   },
    // );

    return dioClient;
  }

  static Future<Map<String, dynamic>> getAuthHeader() async {
    // String token = await LocalStorage().getToken() ?? '';
    // return {'Authorization': 'Bearer $token'};
    return {};
  }

  /// exception handler to manage dio exceptions and show snackbar respectively
  static void dioExceptionHandler(DioException e) {
    String snackbarBody = 'Something went wrong. Please try again.';

    switch (e.type) {
      case DioExceptionType.connectionError:
        snackbarBody =
            'No internet connection. Please check your network and try again.';
        break;
      case DioExceptionType.badResponse:
        snackbarBody =
            'We’re having trouble fetching data right now. Please try again later.';
        break;
      case DioExceptionType.connectionTimeout:
        snackbarBody = 'The request timed out. Please try again in a moment.';
        break;
      case DioExceptionType.receiveTimeout:
        snackbarBody =
            'The server took too long to respond. Please try again later.';
        break;
      case DioExceptionType.sendTimeout:
        snackbarBody =
            'Unable to reach the server. Please check your connection and try again.';
        break;
      default:
        snackbarBody = 'An unexpected error occurred. Please try again later.';
    }

    Utilities.showSnackbar(SnackType.ERROR, snackbarBody);
  }
}
