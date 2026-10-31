part of 'app_database.dart';

extension _V7Migration on AppDatabase {
  Future<void> _ensureInbox() async {
    await customStatement(
      'INSERT OR IGNORE INTO task_lists(id,name,sort_order,created_at,updated_at) VALUES (?,?, -1,?,?)',
      [inboxListId, inboxListName, 0, 0],
    );
  }

  Future<void> _migrateV6(Migrator migrator) async {
    // Copy original rows before rebuilding. Do not rename referenced tables:
    // SQLite would otherwise retarget child foreign keys to the archive.
    await customStatement(
      'CREATE TABLE legacy_v6_tasks AS SELECT * FROM tasks',
    );
    await customStatement(
      'CREATE TABLE legacy_v6_lists AS SELECT * FROM folders',
    );
    await migrator.createTable(folderGroups);
    await migrator.createTable(folders);
    await customStatement('''
      INSERT INTO task_lists(id,name,color,icon,sort_order,deleted_at,created_at,updated_at)
      SELECT id,name,color,icon,sort_order,deleted_at,created_at,updated_at FROM folders
    ''');
    await _ensureInbox();
    await customStatement('DROP TABLE tasks');
    await migrator.createTable(tasks);
    await customStatement(
      '''
      INSERT INTO tasks(id,title,due_date,priority,memo,list_id,sort_order,completed_at,deleted_at,created_at,updated_at)
      SELECT id,title,due_date,priority,memo,
        CASE WHEN folder_id IN (SELECT id FROM task_lists) THEN folder_id ELSE ? END,
        sort_order,completed_at,deleted_at,created_at,updated_at FROM legacy_v6_tasks
    ''',
      [inboxListId],
    );
    await migrator.addColumn(ecampusCourses, ecampusCourses.listId);
    await customStatement('DROP TABLE folders');
    final problems = await customSelect('PRAGMA foreign_key_check').get();
    if (problems.any(
      (row) => !(row.data['table'] as String).startsWith('legacy_'),
    )) {
      throw StateError('목록 구조 이관 후 외래키 오류가 있습니다.');
    }
  }
}
