import 'package:drift/drift.dart';

final String migration002 = '''
ALTER TABLE documents ADD COLUMN parent_id INTEGER REFERENCES documents(id) ON DELETE SET NULL;
ALTER TABLE documents ADD COLUMN type TEXT NOT NULL DEFAULT 'document';
''';
