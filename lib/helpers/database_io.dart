import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Connection? _connection;

  Future<Connection> get connection async {
    _connection ??= await _connect();
    return _connection!;
  }

  Future<Connection> _connect() async {
    final connection = await Connection.open(
      Endpoint(
        host: dotenv.env['DB_HOST']!,
        port: int.parse(dotenv.env['DB_PORT']!),
        database: dotenv.env['DB_NAME']!,
        username: dotenv.env['DB_USER']!,
        password: dotenv.env['DB_PASSWORD']!,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return connection;
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
    }
  }
}
