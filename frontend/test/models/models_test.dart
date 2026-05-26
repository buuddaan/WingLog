import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/geo_service.dart';
import 'package:frontend/screens/gallery_screen.dart';

void main() {
  group('Sighting Model Tests (GeoService)', () {
    test('9. Sighting.fromJson ska mappa alla fält korrekt', () {
      final json = {
        'id': '123',
        'userId': 'user1',
        'speciesName': 'Koltrast',
        'latitude': 59.3293,
        'longitude': 18.0686,
        'description': 'Såg den i trädet',
        'createdAt': '2026-05-22T12:00:00.000Z',
        'public': true
      };

      final sighting = Sighting.fromJson(json);

      expect(sighting.id, '123');
      expect(sighting.userId, 'user1');
      expect(sighting.speciesName, 'Koltrast');
      expect(sighting.latitude, 59.3293);
      expect(sighting.longitude, 18.0686);
      expect(sighting.description, 'Såg den i trädet');
      expect(sighting.isPublic, isTrue);
    });

    test('10. Sighting.fromJson ska hantera avsaknad av description (null)', () {
      final json = {
        'id': '1', 'userId': 'u', 'speciesName': 'Svan',
        'latitude': 1.0, 'longitude': 1.0, 'createdAt': '2026-05-22T12:00:00.000Z'
      };
      final sighting = Sighting.fromJson(json);
      expect(sighting.description, isNull);
    });

    test('11. Sighting.fromJson ska sätta isPublic till true om fältet saknas', () {
      final json = {
        'id': '1', 'userId': 'u', 'speciesName': 'Svan',
        'latitude': 1.0, 'longitude': 1.0, 'createdAt': '2026-05-22T12:00:00.000Z'
      };
      final sighting = Sighting.fromJson(json);
      expect(sighting.isPublic, isTrue);
    });

    test('12. Sighting.fromJson ska kunna tolka isPublic via nyckeln "isPublic" eller "public"', () {
      final json = {
        'id': '1', 'userId': 'u', 'speciesName': 'Svan',
        'latitude': 1.0, 'longitude': 1.0, 'createdAt': '2026-05-22T12:00:00.000Z',
        'isPublic': false // Använder isPublic istället för public
      };
      final sighting = Sighting.fromJson(json);
      expect(sighting.isPublic, isFalse);
    });

    test('13. Sighting.fromJson ska parsa datum-strängar till DateTime', () {
      final json = {
        'id': '1', 'userId': 'u', 'speciesName': 'Svan',
        'latitude': 1.0, 'longitude': 1.0, 'createdAt': '2026-05-22T12:00:00.000Z'
      };
      final sighting = Sighting.fromJson(json);
      expect(sighting.createdAt.year, 2026);
      expect(sighting.createdAt.month, 5);
    });
  });

  group('BirdPhoto Model Tests (GalleryScreen)', () {
    test('14. BirdPhoto.fromJson ska mappa fält korrekt', () {
      final json = {'id': 'abc', 'imageUrl': 'http://bild.se', 'folderName': 'Blåmes'};
      final photo = BirdPhoto.fromJson(json);

      expect(photo.id, 'abc');
      expect(photo.imageUrl, 'http://bild.se');
      expect(photo.birdSpecies, 'Blåmes'); // folderName mappar till birdSpecies
    });

    test('15. BirdPhoto.fromJson ska sätta "Oidentifierade" om folderName saknas', () {
      final json = {'id': 'abc', 'imageUrl': 'http://bild.se'};
      final photo = BirdPhoto.fromJson(json);
      expect(photo.birdSpecies, 'Oidentifierade');
    });

    test('16. BirdPhoto.fromJson ska hantera helt tomma JSON-objekt med defaults', () {
      final json = <String, dynamic>{};
      final photo = BirdPhoto.fromJson(json);
      expect(photo.id, '');
      expect(photo.imageUrl, '');
      expect(photo.birdSpecies, 'Oidentifierade');
    });
  });
}