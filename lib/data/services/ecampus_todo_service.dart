import '../models/ecampus_models.dart';
import 'ecampus_auth_service.dart';

abstract class EcampusTodoService {
  Future<String> fetchTodoHtml(EcampusSession session);

  EcampusTodoParseResult parseTodoHtml(String html);

  Future<EcampusTodoParseResult> fetchAndParse(EcampusSession session);
}
