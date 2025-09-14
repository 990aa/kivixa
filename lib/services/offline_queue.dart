import 'dart:async';
import 'dart:convert';
import 'package:kivixa/ai/provider_config_service.dart'; // Assuming this provides AppDatabase and JobQueueData/Companion
import 'package:drift/drift.dart';

class OfflineQueue {
  final AppDatabase _db;
  final _controller = StreamController<Job>.broadcast();

  OfflineQueue(this._db);

  Stream<Job> get jobUpdates => _controller.stream;

  Future<int> enqueue(String jobType, Map<String, dynamic> payload) async {
    // Ensure all required fields for JobQueues table are present or have defaults
    final companion = JobQueueCompanion.insert(
      jobType: jobType,
      payload: jsonEncode(payload),
      // Assuming 'attempts', 'status', 'createdAt', 'updatedAt' have DB defaults or are handled by Drift
    );
    final newId = await _db.into(_db.jobQueue).insert(companion);

    // Fetch the complete job data from the DB to ensure all fields (including DB defaults) are populated
    final jobData = await (_db.select(
      _db.jobQueue,
    )..where((tbl) => tbl.id.equals(newId))).getSingle();
    _controller.add(Job.fromData(jobData));
    return newId;
  }

  Future<void> processQueue() async {
    // Fetch jobs ordered by creation time
    final jobsToProcess =
        await (_db.select(_db.jobQueue)
              ..where(
                (tbl) => tbl.status.equals('pending'),
              ) // Only process pending jobs
              ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
            .get();

    for (final jobData in jobsToProcess) {
      final job = Job.fromData(jobData);
      try {
        await _processJob(job);
        // If successful, delete the job from the queue
        await (_db.delete(
          _db.jobQueue,
        )..where((tbl) => tbl.id.equals(job.id!))).go();
        // Optionally, notify about successful completion if needed
      } catch (e) {
        // If processing fails, update attempts and reset status if necessary
        final updatedJob = job.copyWith(
          attempts: job.attempts + 1,
          status:
              'pending', // Or a specific 'failed_retry' status if you have one
          updatedAt: DateTime.now(),
        );
        await (_db.update(_db.jobQueue)..where((tbl) => tbl.id.equals(job.id!)))
            .write(updatedJob.toCompanion());
        _controller.add(updatedJob); // Notify listeners about the update
        // print('Error processing job ${job.id}: $e. Will retry.');
      }
    }
  }

  Future<void> _processJob(Job job) async {
    // Update job status to 'in_progress'
    await (_db.update(
      _db.jobQueue,
    )..where((tbl) => tbl.id.equals(job.id!))).write(
      JobQueueCompanion.custom(
        status: const Variable<String>('in_progress'),
        // Remove or correct updatedAt if not a valid named parameter
      ),
    );
    _controller.add(
      job.copyWith(status: 'in_progress', updatedAt: DateTime.now()),
    ); // Notify stream

    // Simulate actual job processing based on job.jobType and job.payload
    // print('Processing job ${job.id} of type ${job.jobType}...');
    await Future.delayed(const Duration(seconds: 2)); // Simulate work
    // print('Finished processing job ${job.id}.');

    // NOTE: In a real app, the deletion or update to 'completed' status
    // would happen in processQueue after _processJob completes successfully.
    // Here, _processJob is self-contained for simulation.
  }
}

class Job {
  final int? id;
  final String jobType;
  final String payload;
  final int attempts;
  final DateTime createdAt;
  final String status;
  final DateTime updatedAt;

  Job({
    this.id,
    required this.jobType,
    required this.payload,
    required this.attempts,
    required this.createdAt,
    required this.status,
    required this.updatedAt,
  });

  // Factory constructor from Drift's generated data class
  Job.fromData(
    JobQueueData data,
  ) // Assuming JobQueueData is your Drift data class for JobQueues table
  : id = data.id,
      jobType = data.jobType,
      payload = data.payload,
      attempts =
          data.attempts, // Assuming 'attempts' is a non-nullable column in DB
      createdAt = data.createdAt,
      status = data.status, // Assuming 'status' is a non-nullable column in DB
      updatedAt = data.updatedAt;

  // Constructor from a companion, ensuring defaults for non-nullable fields if companion values are absent
  Job.fromCompanion(this.id, JobQueueCompanion companion)
    : jobType = companion.jobType.present
          ? companion.jobType.value
          : 'unknown_type',
      payload = companion.payload.present ? companion.payload.value : '{}',
      attempts = companion.attempts.present ? companion.attempts.value : 0,
      createdAt = companion.createdAt.present
          ? companion.createdAt.value
          : DateTime.now(),
      status = companion.status.present ? companion.status.value : 'pending',
      updatedAt = companion.updatedAt.present
          ? companion.updatedAt.value
          : DateTime.now();

  Job copyWith({
    int? id,
    String? jobType,
    String? payload,
    int? attempts,
    DateTime? createdAt,
    String? status,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      jobType: jobType ?? this.jobType,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Converts Job instance to a Drift companion for database operations
  JobQueueCompanion toCompanion() {
    return JobQueueCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      jobType: Value(jobType),
      payload: Value(payload),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }
}
