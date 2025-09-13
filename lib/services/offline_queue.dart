import 'dart:async';
import 'dart:convert';
import 'package:kivixa/ai/provider_config_service.dart';
import 'package:drift/drift.dart';

class OfflineQueue {
  final AppDatabase _db;
  final _controller = StreamController<Job>.broadcast();

  OfflineQueue(this._db);

  Stream<Job> get jobUpdates => _controller.stream;

  Future<void> enqueue(String jobType, Map<String, dynamic> payload) async {
    final companion = JobQueueCompanion.insert(
      jobType: jobType,
      payload: jsonEncode(payload),
    );
    final newId = await _db.into(_db.jobQueue).insert(companion);
    _controller.add(Job.fromCompanion(newId, companion));
  }

  Future<void> processQueue() async {
    final jobs = await (_db.select(_db.jobQueue)..orderBy([(t) => t.createdAt.asc()])).get();
    for (final jobData in jobs) {
      final job = Job.fromData(jobData);
      try {
        await _processJob(job);
        await (_db.delete(_db.jobQueue)..where((tbl) => tbl.id.equals(job.id!))).go();
      } catch (e) {
        final updatedJob = job.copyWith(attempts: job.attempts + 1);
        await (_db.update(_db.jobQueue)..where((tbl) => tbl.id.equals(job.id!))).write(updatedJob.toCompanion());
        _controller.add(updatedJob);
      }
    }
  }

  Future<void> _processJob(Job job) async {
    // In a real app, you would have a switch statement or a map of handlers
    // to process different job types.
    print('Processing job ${job.id}: ${job.jobType}');
    await Future.delayed(const Duration(seconds: 2)); // Simulate work
  }
}

class Job {
  final int? id;
  final String jobType;
  final String payload;
  final int attempts;
  final DateTime createdAt;

  Job({this.id, required this.jobType, required this.payload, required this.attempts, required this.createdAt});

  Job.fromData(JobQueueData data)
      : id = data.id,
        jobType = data.jobType,
        payload = data.payload,
        attempts = data.attempts,
        createdAt = data.createdAt;

  Job.fromCompanion(int id, JobQueueCompanion companion)
      : id = id,
        jobType = companion.jobType.value,
        payload = companion.payload.value,
        attempts = companion.attempts.value,
        createdAt = companion.createdAt.value;

  Job copyWith({int? id, int? attempts}) {
    return Job(
      id: id ?? this.id,
      jobType: jobType,
      payload: payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
    );
  }

  JobQueueCompanion toCompanion() {
    return JobQueueCompanion(
      id: Value(id),
      jobType: Value(jobType),
      payload: Value(payload),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
    );
  }
}