import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum JobStatus { queued, running, completed, failed }

class QueuedJob {
  final String id;
  final String task;
  final Map<String, dynamic> payload;
  JobStatus status;
  int attempts;

  QueuedJob({
    required this.id,
    required this.task,
    required this.payload,
    this.status = JobStatus.queued,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'task': task,
    'payload': payload,
    'status': status.toString(),
    'attempts': attempts,
  };

  factory QueuedJob.fromJson(Map<String, dynamic> json) => QueuedJob(
    id: json['id'],
    task: json['task'],
    payload: json['payload'],
    status: JobStatus.values.firstWhere((e) => e.toString() == json['status']),
    attempts: json['attempts'],
  );
}

class OfflineQueue extends ChangeNotifier {
  static final OfflineQueue _instance = OfflineQueue._internal();
  factory OfflineQueue() => _instance;
  OfflineQueue._internal();

  List<QueuedJob> _jobs = [];
  bool _isProcessing = false;
  late final File _queueFile;
  bool _isInitialized = false;

  List<QueuedJob> get jobs => _jobs;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final appSupportDir = await getApplicationSupportDirectory();
    _queueFile = File(p.join(appSupportDir.path, 'offline_queue.json'));
    await _loadQueue();
    _isInitialized = true;
    _startProcessing();
  }

  Future<void> _loadQueue() async {
    if (await _queueFile.exists()) {
      final content = await _queueFile.readAsString();
      final List<dynamic> jsonJobs = jsonDecode(content);
      _jobs = jsonJobs.map((json) => QueuedJob.fromJson(json)).toList();
    }
  }

  Future<void> _persistQueue() async {
    final jsonJobs = _jobs.map((job) => job.toJson()).toList();
    await _queueFile.writeAsString(jsonEncode(jsonJobs));
  }

  void enqueue(String task, Map<String, dynamic> payload) {
    final job = QueuedJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      task: task,
      payload: payload,
    );
    _jobs.add(job);
    _persistQueue();
    notifyListeners();
    _startProcessing();
  }

  void _startProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _processNextJob();
      if (_jobs.where((j) => j.status == JobStatus.queued || j.status == JobStatus.failed).isEmpty) {
        timer.cancel();
        _isProcessing = false;
      }
    });
  }

  Future<void> _processNextJob() async {
    final job = _jobs.firstWhere(
      (j) => j.status == Job.queued || (j.status == JobStatus.failed && j.attempts < 5),
      orElse: () => null,
    );

    if (job == null) return;

    job.status = JobStatus.running;
    job.attempts++;
    notifyListeners();

    try {
      // Simulate network operation
      await _executeTask(job.task, job.payload);
      job.status = JobStatus.completed;
    } catch (e) {
      job.status = JobStatus.failed;
      // Exponential backoff
      await Future.delayed(Duration(seconds: pow(2, job.attempts).toInt()));
    }

    _persistQueue();
    notifyListeners();
  }

  Future<void> _executeTask(String task, Map<String, dynamic> payload) async {
    // This is where the actual job logic would go.
    // For example, an export job.
    print('Executing task: $task with payload: $payload');
    // Simulate a failure 30% of the time
    if (Random().nextDouble() < 0.3) {
      throw Exception('Simulated network failure');
    }
    await Future.delayed(const Duration(seconds: 2));
  }
}
