import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'ecampus_auth_service.dart';
import 'ecampus_todo_client.dart';

class EcampusTodoFetchException implements Exception {
  const EcampusTodoFetchException(this.message);

  final String message;

  @override
  String toString() => 'EcampusTodoFetchException: $message';
}

class EcampusSessionExpiredException extends EcampusTodoFetchException {
  const EcampusSessionExpiredException() : super('e-campus session expired');
}

class HttpEcampusTodoClient implements EcampusTodoClient {
  const HttpEcampusTodoClient({
    required this.httpClient,
    this.baseUrl = 'https://ecampus.konkuk.ac.kr',
  });

  final http.Client httpClient;
  final String baseUrl;

  @override
  Future<String> fetchTodoHtml(EcampusSession session) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/ilos/mp/todo_list.acl'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        if (session.cookieHeader.isNotEmpty) 'Cookie': session.cookieHeader,
      },
      body: const {'STYPE': '1'},
    );

    if (response.statusCode != 200) {
      throw EcampusTodoFetchException(
        'failed to fetch todo html: ${response.statusCode}',
      );
    }

    if (_looksLikeLoginPage(response.body)) {
      throw const EcampusSessionExpiredException();
    }

    return response.body;
  }

  bool _looksLikeLoginPage(String body) {
    final document = html_parser.parse(body);
    return document.querySelector(
              'a[href="/ilos/main/member/login_form.acl"]',
            ) !=
            null ||
        document.querySelector('.header_login') != null;
  }
}
