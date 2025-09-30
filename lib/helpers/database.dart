import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection == null) {
      _connection = await _connect();
    }
    return _connection!;
  }

  Future<Connection> _connect() async {
    final connection = await Connection.open(
      Endpoint(
        host: 'your_host',
        port: 5432,
        database: 'your_database',
        username: 'your_username',
        password: 'your_password',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );
    return connection;
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
    }
  }
}
