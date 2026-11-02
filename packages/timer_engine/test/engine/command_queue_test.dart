import 'dart:async';
import 'package:test/test.dart';
import 'package:timer_engine/src/engine/command_queue.dart';

void main() {
  group('CommandQueue Concurrency Control', () {
    test('serializes concurrent tasks in strict FIFO order', () async {
      final queue = CommandQueue();
      final executed = <int>[];

      final future1 = queue.run(() async {
        await Future.delayed(const Duration(milliseconds: 20));
        executed.add(1);
        return 'one';
      });

      final future2 = queue.run(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        executed.add(2);
        return 'two';
      });

      final future3 = queue.run(() async {
        executed.add(3);
        return 'three';
      });

      final results = await Future.wait([future1, future2, future3]);

      expect(executed, equals([1, 2, 3]));
      expect(results, equals(['one', 'two', 'three']));
    });

    test('continues executing subsequent tasks if a task throws', () async {
      final queue = CommandQueue();
      final executed = <int>[];

      expect(
        () => queue.run(() async {
          throw Exception('Task 1 failed');
        }),
        throwsException,
      );

      final result = await queue.run(() async {
        executed.add(2);
        return 'recovered';
      });

      expect(executed, equals([2]));
      expect(result, equals('recovered'));
    });

    test('continues executing pre-queued tasks when an earlier task throws',
        () async {
      final queue = CommandQueue();
      final executed = <int>[];

      final task1 = queue.run(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw StateError('Task 1 failure');
      });

      final task2 = queue.run(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        executed.add(2);
        return 'task 2 done';
      });

      final task3 = queue.run(() async {
        executed.add(3);
        return 'task 3 done';
      });

      await expectLater(task1, throwsStateError);
      final r2 = await task2;
      final r3 = await task3;

      expect(r2, equals('task 2 done'));
      expect(r3, equals('task 3 done'));
      expect(executed, equals([2, 3]));
    });

    test('handles synchronous throw in action gracefully', () async {
      final queue = CommandQueue();
      final executed = <int>[];

      final task1 = queue.run<int>(() {
        throw ArgumentError('Sync throw');
      });

      final task2 = queue.run<int>(() async {
        executed.add(2);
        return 42;
      });

      await expectLater(task1, throwsArgumentError);
      final r2 = await task2;

      expect(r2, equals(42));
      expect(executed, equals([2]));
    });
  });
}
