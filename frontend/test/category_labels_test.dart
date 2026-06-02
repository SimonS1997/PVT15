import 'package:flutter_test/flutter_test.dart';
import 'package:kulturnatten/utils/category_labels.dart';

void main() {
  test('returnerar svensk label för känd kategori', () {
    // MUSIC ska översättas till "Musik"
    expect(localizedCategoryLabel('MUSIC'), 'Musik');
  });

  test('returnerar fallback när kategori är null eller tom', () {
    // null och tom sträng ska ge default-fallbacken
    expect(localizedCategoryLabel(null), 'Event');
    expect(localizedCategoryLabel(''), 'Event');
    // egen fallback ska också respekteras
    expect(localizedCategoryLabel(null, fallback: 'Okänd'), 'Okänd');
  });

  test('matchar oavsett gemener eller versaler', () {
    // små bokstäver ska konverteras till versaler innan uppslag
    expect(localizedCategoryLabel('music'), 'Musik');
  });

  test('returnerar inputvärdet när kategorin är okänd', () {
    // saknas i mappen → ge tillbaka råvärdet istället för att krascha
    expect(localizedCategoryLabel('UNKNOWN'), 'UNKNOWN');
  });
}
