const Map<String, String> categoryLabels = {
  'MUSIC': 'Musik',
  'ART': 'Konst',
  'THEATRE': 'Teater',
  'FILM': 'Film',
  'DANCE': 'Dans',
  'GUIDED_TOUR': 'Guidad tur',
  'HISTORY': 'Historia',
  'LITERATURE': 'Litteratur',
  'WELLNESS': 'Wellness',
  'WORKSHOP': 'Workshop',
  'OTHER': 'Övrigt',
};

String localizedCategoryLabel(String? category, {String fallback = 'Event'}) {
  final value = category?.trim();
  if (value == null || value.isEmpty) return fallback;

  return categoryLabels[value.toUpperCase()] ?? value;
}
