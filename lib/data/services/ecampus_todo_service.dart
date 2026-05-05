import '../models/ecampus_models.dart';
import 'ecampus_auth_service.dart';

abstract class EcampusTodoService {
  Future<String> fetchTodoHtml(EcampusSession session);

  List<ParsedEcampusTask> parseTodoHtml(String html);
}
