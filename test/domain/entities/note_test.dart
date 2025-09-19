import 'package:flutter_test/flutter_test.dart';
import 'package:simple_tuner/domain/entities/note.dart';

void main() {
  group('Note', () {
    test('should create a note with correct properties', () {
      // arrange
      const note = Note(
        name: 'A',
        frequency: 440.0,
        octave: 4,
      );

      // assert
      expect(note.name, 'A');
      expect(note.frequency, 440.0);
      expect(note.octave, 4);
    });

    test('should have correct toString representation', () {
      // arrange
      const note = Note(
        name: 'A',
        frequency: 440.0,
        octave: 4,
      );

      // act
      final result = note.toString();

      // assert
      expect(result, 'A4 (440.00Hz)');
    });

    test('should be equal when all properties are the same', () {
      // arrange
      const note1 = Note(name: 'A', frequency: 440.0, octave: 4);
      const note2 = Note(name: 'A', frequency: 440.0, octave: 4);

      // assert
      expect(note1, equals(note2));
      expect(note1.hashCode, equals(note2.hashCode));
    });

    test('should not be equal when properties differ', () {
      // arrange
      const note1 = Note(name: 'A', frequency: 440.0, octave: 4);
      const note2 = Note(name: 'B', frequency: 440.0, octave: 4);

      // assert
      expect(note1, isNot(equals(note2)));
    });
  });
}
