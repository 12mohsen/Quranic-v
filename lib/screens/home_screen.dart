import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reciter.dart';
import '../services/quran_service.dart';
import 'surah_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuranService _quranService = QuranService();
  List<Surah>? _surahs;
  Reciter? _selectedReciter;

  @override
  void initState() {
    super.initState();
    _selectedReciter = _quranService.reciters.first;
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    final surahs = await _quranService.getSurahs();
    setState(() {
      _surahs = surahs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F1A),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Quran Player',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.teal.withOpacity(0.3),
                      const Color(0xFF0F0F1A),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.menu_book_rounded,
                        size: 60,
                        color: Colors.teal.shade300,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildReciterSelector(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          if (_surahs == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final surah = _surahs![index];
                  return _buildSurahCard(surah);
                },
                childCount: _surahs?.length ?? 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReciterSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Reciter',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Reciter>(
            value: _selectedReciter,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF2A2A3C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            dropdownColor: const Color(0xFF2A2A3C),
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
            ),
            items: _quranService.reciters.map((reciter) {
              return DropdownMenuItem(
                value: reciter,
                child: Text(
                  '${reciter.name} - ${reciter.arabicName}',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
            onChanged: (reciter) {
              setState(() {
                _selectedReciter = reciter;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(Surah surah) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurahScreen(
              surah: surah,
              reciter: _selectedReciter!,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  surah.number.toString(),
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${surah.englishName} • ${surah.numberOfAyahs} verses',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
