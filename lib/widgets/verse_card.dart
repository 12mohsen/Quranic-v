import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reciter.dart';
import 'verse_share_card.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;
  final Surah surah;
  final bool isPlaying;
  final bool isCurrentVerse;
  final VoidCallback onPlay;

  const VerseCard({
    super.key,
    required this.verse,
    required this.surah,
    required this.isPlaying,
    required this.isCurrentVerse,
    required this.onPlay,
  });

  void _showShareOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShareOptionsDialog(
        verseTextWithTashkeel: verse.text,
        verseTextWithoutTashkeel: verse.textWithoutTashkeel,
        surahName: surah.name,
        verseNumber: verse.number,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentVerse
            ? Colors.teal.withOpacity(0.15)
            : const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentVerse
              ? Colors.teal.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: isCurrentVerse
            ? [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verse number and actions row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentVerse
                        ? Colors.teal.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verse.number.toString(),
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCurrentVerse ? Colors.teal.shade200 : Colors.white70,
                    ),
                  ),
                ),
                const Spacer(),
                // Share button
                IconButton(
                  onPressed: () => _showShareOptions(context),
                  icon: const Icon(Icons.share),
                  color: isCurrentVerse ? Colors.teal.shade300 : Colors.white60,
                  tooltip: 'Share verse',
                ),
                const SizedBox(width: 4),
                // Play button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isPlaying && isCurrentVerse
                        ? Colors.teal
                        : Colors.teal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onPlay,
                    icon: Icon(
                      isPlaying && isCurrentVerse
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: isPlaying && isCurrentVerse
                        ? Colors.white
                        : Colors.teal,
                    iconSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Arabic text with tashkeel
            Text(
              verse.text,
              style: GoogleFonts.amiri(
                fontSize: 26,
                height: 1.8,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
