// Manual measurement: flutter test --no-pub --reporter expanded
//   test/benchmarks/task_repository_benchmark.dart
// This filename deliberately keeps the benchmark out of the normal test suite.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ku_task_management/data/local/app_database.dart' as db;
import 'package:ku_task_management/data/repositories/drift_task_repository.dart';

const _warmups = 3;
const _repetitions = 10;

void main() {
  test(
    'record task-list database baseline',
    () async {
      final startedAt = DateTime.now().toUtc();
      final scenarios = <Map<String, Object?>>[];
      for (final size in [100, 1000]) {
        final counter = _SelectCounter();
        final database = db.AppDatabase(
          NativeDatabase.memory().interceptWith(counter),
        );
        try {
          await _seed(database, size);
          final repository = DriftTaskRepository(database: database);

          for (var i = 0; i < _warmups; i++) {
            await repository.getTasks();
          }

          final samples = <Map<String, Object>>[];
          for (var i = 0; i < _repetitions; i++) {
            counter.selects = 0;
            final stopwatch = Stopwatch()..start();
            final tasks = await repository.getTasks();
            stopwatch.stop();
            final selects = counter.selects;

            // Check returned data outside the timed region. A fast but incomplete
            // relation loader must not produce a successful measurement artifact.
            expect(tasks.length, size);
            for (var index = 0; index < size; index++) {
              expect(tasks[index].id, 'task-$index');
              expect(tasks[index].tagIds.toSet(), {'tag-0', 'tag-1'});
              expect(tasks[index].folderIds, ['folder-0']);
            }
            samples.add({
              'iteration': i + 1,
              'elapsed_us': stopwatch.elapsedMicroseconds,
              'select_count': selects,
              'returned_tasks': tasks.length,
            });
          }

          final durations =
              samples.map((sample) => sample['elapsed_us']! as int).toList()
                ..sort();
          scenarios.add({
            'task_count': size,
            'tags_per_task': 2,
            'folders_per_task': 1,
            'samples': samples,
            'median_us': (durations[4] + durations[5]) / 2,
            'p95_us': durations[(durations.length * .95).ceil() - 1],
            'min_us': durations.first,
            'max_us': durations.last,
          });
        } finally {
          await database.close();
        }
      }

      final sourcePaths = [
        'lib/data/local/app_database.dart',
        'lib/data/local/app_database.g.dart',
        'lib/data/local/mappers/task_mapper.dart',
        'lib/data/repositories/drift_task_repository.dart',
        'test/benchmarks/task_repository_benchmark.dart',
        'pubspec.lock',
      ];
      final evidence = {
        'format_version': 1,
        'started_at_utc': startedAt.toIso8601String(),
        'finished_at_utc': DateTime.now().toUtc().toIso8601String(),
        'label': const String.fromEnvironment(
          'MEASUREMENT_LABEL',
          defaultValue: 'before-db-improvement',
        ),
        'command':
            'flutter test --no-pub --reporter expanded '
            'test/benchmarks/task_repository_benchmark.dart',
        'git_commit': _git(['rev-parse', 'HEAD']),
        'source_git_blob_hashes': {
          for (final path in sourcePaths) path: _git(['hash-object', path]),
        },
        'environment': {
          'flutter': _flutterVersion(),
          'os': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'dart': Platform.version,
          'logical_processors': Platform.numberOfProcessors,
          'database': 'Drift NativeDatabase.memory / synthetic data',
          'sqlite_version': await _sqliteVersion(),
          'execution':
              'host Flutter test; not an Android/iOS device measurement',
        },
        'method': {
          'operation':
              'DriftTaskRepository.getTasks() with default active filter',
          'seed':
              'deterministic; all active personal tasks; fixed UTC timestamps',
          'warmups_per_size': _warmups,
          'measured_repetitions_per_size': _repetitions,
          'timer':
              'Stopwatch; repository call including model/relation loading',
          'excluded':
              'database creation, seed inserts, warmups, result assertions',
          'query_counter':
              'QueryInterceptor.runSelect during measured operation',
          'instrumentation': 'same SELECT counter included in every timed run',
          'percentile': 'nearest rank; p95 of 10 samples is the maximum',
        },
        'scenarios': scenarios,
        'limitations': [
          'Warm in-memory host measurement; no disk I/O, UI or network timing.',
          'Not a claim about Android/iOS production or cold-start performance.',
          'No schema modification, production data or performance threshold.',
        ],
      };

      final stamp = startedAt.toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      final output = File('docs/evidence/db/task-list-$stamp.json');
      await output.parent.create(recursive: true);
      await output.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
      );
      // The JSON keeps raw samples. Console output is just a compact run summary.
      // ignore: avoid_print
      print('MEASUREMENT ${output.path}');
      for (final scenario in scenarios) {
        final samples = scenario['samples']! as List<Map<String, Object>>;
        // ignore: avoid_print
        print(
          'tasks=${scenario['task_count']} '
          'median_us=${scenario['median_us']} '
          'p95_us=${scenario['p95_us']} '
          'selects=${samples.first['select_count']}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

class _SelectCounter extends QueryInterceptor {
  int selects = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects++;
    return executor.runSelect(statement, args);
  }
}

Future<void> _seed(db.AppDatabase database, int count) async {
  final now = DateTime.utc(2026, 10, 29, 12);
  await database.batch((batch) {
    batch.insertAll(database.tags, [
      for (var i = 0; i < 2; i++)
        db.TagsCompanion.insert(
          id: 'tag-$i',
          name: 'Tag $i',
          color: '#1262D6',
          createdAt: now,
          updatedAt: now,
        ),
    ]);
    batch.insert(
      database.folders,
      db.FoldersCompanion.insert(
        id: 'folder-0',
        name: 'Folder',
        createdAt: now,
        updatedAt: now,
      ),
    );
    batch.insertAll(database.tasks, [
      for (var i = 0; i < count; i++)
        db.TasksCompanion.insert(
          id: 'task-$i',
          title: 'Synthetic task $i',
          folderId: const Value('folder-0'),
          sortOrder: Value(i),
          dueDate: Value(now.add(Duration(days: i % 30))),
          createdAt: now,
          updatedAt: now,
        ),
    ]);
    batch.insertAll(database.taskTags, [
      for (var i = 0; i < count; i++)
        for (var tag = 0; tag < 2; tag++)
          db.TaskTagsCompanion.insert(
            taskId: 'task-$i',
            tagId: 'tag-$tag',
            updatedAt: now,
          ),
    ]);
  });
}

String _git(List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    environment: {'GIT_OPTIONAL_LOCKS': '0'},
  );
  if (result.exitCode != 0) {
    throw StateError('Cannot capture git metadata: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

Object _flutterVersion() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return 'not captured';
  final file = File('$root/bin/cache/flutter.version.json');
  if (!file.existsSync()) return 'not captured';
  final version = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return {
    'version': version['frameworkVersion'],
    'framework_revision': version['frameworkRevision'],
    'engine_revision': version['engineRevision'],
  };
}

Future<String> _sqliteVersion() async {
  final database = db.AppDatabase(NativeDatabase.memory());
  try {
    final row = await database
        .customSelect('SELECT sqlite_version() AS version')
        .getSingle();
    return row.read<String>('version');
  } finally {
    await database.close();
  }
}
