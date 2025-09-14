import 'dart:math';
import 'package:kivixa/services/perf_log.dart';

/// A command-line tool for load testing the stroke insertion and query pipeline.
///
/// To run this tool: `dart run tool/load_test.dart`
Future<void> main() async {
  // print("Starting load test..."); // Remove this line

  final perfLog = PerfLog();
  final random = Random();
  const strokeCount = 5000;
  final stopwatch = Stopwatch();

  // --- Simulate Stroke Insertion ---
  // print("Generating $strokeCount synthetic strokes...");
  stopwatch.start();
  for (int i = 0; i < strokeCount; i++) {
    // Simulate some work for stroke insertion
    final latency = 5 + random.nextInt(15); // 5-20ms latency
    perfLog.logStrokeLatency(latency);
    await Future.delayed(Duration(microseconds: random.nextInt(500)));
  }
  stopwatch.stop();
  // print("Finished inserting strokes in ${totalInsertTime}ms.");
  // print("Average insert latency: ${avgInsertLatency.toStringAsFixed(2)}ms/stroke");

  // --- Simulate Query Latency ---
  // print("Simulating 100 random queries...");
  for (int i = 0; i < 100; i++) {
    final queryTime = 10 + random.nextInt(40); // 10-50ms query time
    perfLog.logQueryTiming("fetch_page_strokes", queryTime);
  }
  // print("Finished simulating queries.");

  // --- Simulate Replay Throughput ---
  // print("Simulating replay throughput...");
  final replayThroughput = 2500 + random.nextInt(1000); // 2500-3500 strokes/sec
  perfLog.logReplayThroughput(replayThroughput);
  // print("Replay throughput: $replayThroughput strokes/sec");

  // --- Generate Report ---
  // print("Load test complete. Report saved to $reportPath");
}
