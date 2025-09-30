import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  PostgreSQLConnection? _connection;

  Future<PostgreSQLConnection> get connection async {
    if (_connection == null || _connection!.isClosed) {
      _connection = await _connect();
    }
    return _connection!;
  }

  Future<PostgreSQLConnection> _connect() async {
    final connection = PostgreSQLConnection(
      'your_host',
      5432,
      'your_database',
      username: 'your_username',
      password: 'your_password',
    );
    await connection.open();
    return connection;
  }

  Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
    }
  }
}
