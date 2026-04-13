class Reciter {
  final String id;
  final String name;
  final String arabicName;
  final String serverUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.serverUrl,
  });
}

class Surah {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
  });
}

class Verse {
  final int number;
  final String text;
  final String textWithoutTashkeel;

  const Verse({
    required this.number,
    required this.text,
    required this.textWithoutTashkeel,
  });
}
