import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reciter.dart';

class QuranService {
  static const String apiBaseUrl = 'https://api.alquran.cloud/v1';

  final List<Reciter> reciters = [
    const Reciter(
      id: 'ar.alafasy',
      name: 'Mishary Rashid Alafasy',
      arabicName: 'مشاري راشد العفاسي',
      serverUrl: 'https://server8.mp3quran.net/afs',
    ),
    const Reciter(
      id: 'ar.husary',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      serverUrl: 'https://server7.mp3quran.net/husry',
    ),
    const Reciter(
      id: 'ar.abdulbasit',
      name: 'Abdul Basit Abdul Samad',
      arabicName: 'عبد الباسط عبد الصمد',
      serverUrl: 'https://server7.mp3quran.net/basit',
    ),
    const Reciter(
      id: 'ar.minshawi',
      name: 'Mohamed Siddiq El-Minshawi',
      arabicName: 'محمد صديق المنشاوي',
      serverUrl: 'https://server8.mp3quran.net/minsh',
    ),
  ];

  Future<List<Surah>> getSurahs() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/surah'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final surahs = (data['data'] as List).map((s) => Surah(
          number: s['number'],
          name: s['name'],
          englishName: s['englishName'],
          numberOfAyahs: s['numberOfAyahs'],
        )).toList();
        return surahs;
      }
    } catch (e) {
      // Fallback to static data
    }
    return _getDefaultSurahs();
  }

  Future<List<Verse>> getVerses(int surahNumber) async {
    try {
      final responseWithTashkeel = await http.get(
        Uri.parse('$apiBaseUrl/surah/$surahNumber/quran-uthmani'),
      );
      final responseWithoutTashkeel = await http.get(
        Uri.parse('$apiBaseUrl/surah/$surahNumber/quran-simple'),
      );

      if (responseWithTashkeel.statusCode == 200 &&
          responseWithoutTashkeel.statusCode == 200) {
        final dataWith = jsonDecode(responseWithTashkeel.body);
        final dataWithout = jsonDecode(responseWithoutTashkeel.body);

        final versesWith = dataWith['data']['ayahs'] as List;
        final versesWithout = dataWithout['data']['ayahs'] as List;

        return List.generate(versesWith.length, (i) {
          return Verse(
            number: versesWith[i]['numberInSurah'],
            text: versesWith[i]['text'],
            textWithoutTashkeel: versesWithout[i]['text'],
          );
        });
      }
    } catch (e) {
      // Return empty on error
    }
    return [];
  }

  String getAudioUrl(Reciter reciter, int surahNumber) {
    final surahStr = surahNumber.toString().padLeft(3, '0');
    return '${reciter.serverUrl}/$surahStr.mp3';
  }

  List<Surah> _getDefaultSurahs() {
    return [
      const Surah(number: 1, name: 'الفاتحة', englishName: 'Al-Fatiha', numberOfAyahs: 7),
      const Surah(number: 2, name: 'البقرة', englishName: 'Al-Baqarah', numberOfAyahs: 286),
      const Surah(number: 112, name: 'الإخلاص', englishName: 'Al-Ikhlas', numberOfAyahs: 4),
      const Surah(number: 113, name: 'الفلق', englishName: 'Al-Falaq', numberOfAyahs: 5),
      const Surah(number: 114, name: 'الناس', englishName: 'Al-Nas', numberOfAyahs: 6),
    ];
  }
}
