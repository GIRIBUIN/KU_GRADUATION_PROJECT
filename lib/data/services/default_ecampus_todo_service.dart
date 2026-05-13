import '../models/ecampus_models.dart';
import 'ecampus_auth_service.dart';
import 'ecampus_todo_client.dart';
import 'ecampus_todo_parser.dart';
import 'ecampus_todo_service.dart';

class DefaultEcampusTodoService implements EcampusTodoService {
  const DefaultEcampusTodoService({
    required this.client,
    required this.parser,
  });

  final EcampusTodoClient client;
  final EcampusTodoParser parser;

  @override
  Future<String> fetchTodoHtml(EcampusSession session) {
    return client.fetchTodoHtml(session);
  }

  @override
  EcampusTodoParseResult parseTodoHtml(String html) {
    return parser.parse(html);
  }

  @override
  Future<EcampusTodoParseResult> fetchAndParse(EcampusSession session) async {
    final html = await fetchTodoHtml(session);
    return parseTodoHtml(html);
  }
}
