import 'ecampus_auth_service.dart';

abstract class EcampusTodoClient {
  Future<String> fetchTodoHtml(EcampusSession session);
}
