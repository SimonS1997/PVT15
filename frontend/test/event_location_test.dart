import 'package:flutter_test/flutter_test.dart';
import 'package:kulturnatten/models/event_location.dart';

void main() {
  test('fromJson parsar ett fullständigt event korrekt', () {
    // typisk JSON från backend med alla fält ifyllda
    final json = <String, dynamic>{
      'id': 1,
      'name': 'Konsert',
      'venue': 'Konserthuset',
      'address': 'Hötorget 8',
      'timeStart': '19:00',
      'timeEnd': '21:00',
      'district': 'City',
      'description': 'Live music',
      'bookingRequired': true,
      'nearestStation': 'Hötorget',
      'category': 'MUSIC',
      'latitude': 59.33,
      'longitude': 18.06,
    };

    final event = EventLocation.fromJson(json);

    // kontrollera att fälten plockas ut i rätt typer
    expect(event.id, 1);
    expect(event.name, 'Konsert');
    expect(event.bookingRequired, true);
    expect(event.latitude, 59.33);
    expect(event.longitude, 18.06);
  });

  test('fromJson hanterar optionella fält som null', () {
    // bara obligatoriska fält skickas med — resten ska bli null
    final json = <String, dynamic>{
      'id': 2,
      'name': 'Visning',
      'venue': 'Operan',
      'address': 'Gustav Adolfs torg 2',
      'latitude': 59.32,
      'longitude': 18.07,
    };

    final event = EventLocation.fromJson(json);

    // de optionella fälten ska vara null när nyckeln saknas
    expect(event.timeStart, isNull);
    expect(event.district, isNull);
    expect(event.category, isNull);
  });

  test('fromJson defaultar bookingRequired till false när nyckeln saknas', () {
    // bookingRequired är en bool, inte nullable — ska defaulta till false
    final json = <String, dynamic>{
      'id': 3,
      'name': 'Gratis event',
      'venue': 'Park',
      'address': 'Kungsträdgården',
      'latitude': 59.33,
      'longitude': 18.07,
    };

    final event = EventLocation.fromJson(json);

    expect(event.bookingRequired, false);
  });
}
