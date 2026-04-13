import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reciter.dart';

class VerseShareCard extends StatelessWidget {
  final String verseText;
  final String surahName;
  final int verseNumber;
  final bool withTashkeel;
  final GlobalKey _repaintKey = GlobalKey();

  VerseShareCard({
    super.key,
    required this.verseText,
    required this.surahName,
    required this.verseNumber,
    required this.withTashkeel,
  });

  Future<void> captureAndShare() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/quran_verse_$verseNumber.png';

      final file = await File(filePath).create(recursive: true);
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: '$surahName - Verse $verseNumber',
        subject: 'Quran Verse',
      );
    } catch (e) {
      debugPrint('Error sharing verse: $e');
    }
  }

  Widget _buildShareCard() {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        width: 1080,
        height: 1080,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F0F23),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: 50,
              left: 50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: 60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bismillah
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: GoogleFonts.amiri(
                        fontSize: 32,
                        color: Colors.teal.shade300,
                        fontWeight: FontWeight.w500,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 40),
                    // Verse text
                    Text(
                      verseText,
                      style: GoogleFonts.amiri(
                        fontSize: 52,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.8,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 50),
                    // Decorative divider
                    Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.teal.shade400,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Surah and verse info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.teal.shade400.withOpacity(0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '$surahName - $verseNumber',
                        style: GoogleFonts.lato(
                          fontSize: 22,
                          color: Colors.teal.shade200,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // App watermark
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Quran Player',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.3),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShareCard();
  }
}

class ShareOptionsDialog extends StatelessWidget {
  final String verseTextWithTashkeel;
  final String verseTextWithoutTashkeel;
  final String surahName;
  final int verseNumber;

  const ShareOptionsDialog({
    super.key,
    required this.verseTextWithTashkeel,
    required this.verseTextWithoutTashkeel,
    required this.surahName,
    required this.verseNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share,
              color: Colors.teal,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Share Verse',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to share this verse',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              icon: Icons.text_fields,
              title: 'With Tashkeel',
              subtitle: 'Share with full diacritical marks',
              onTap: () => _shareWithTashkeel(context),
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.text_format,
              title: 'Without Tashkeel',
              subtitle: 'Share plain Arabic text',
              onTap: () => _shareWithoutTashkeel(context),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.teal.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.teal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _shareWithTashkeel(BuildContext context) {
    final card = VerseShareCard(
      verseText: verseTextWithTashkeel,
      surahName: surahName,
      verseNumber: verseNumber,
      withTashkeel: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GeneratingImageDialog(card: card),
    );
  }

  void _shareWithoutTashkeel(BuildContext context) {
    final card = VerseShareCard(
      verseText: verseTextWithoutTashkeel,
      surahName: surahName,
      verseNumber: verseNumber,
      withTashkeel: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GeneratingImageDialog(card: card),
    );
  }
}

class _GeneratingImageDialog extends StatefulWidget {
  final VerseShareCard card;

  const _GeneratingImageDialog({required this.card});

  @override
  State<_GeneratingImageDialog> createState() =>
      _GeneratingImageDialogState();
}

class _GeneratingImageDialogState extends State<_GeneratingImageDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.card.captureAndShare().then((_) {
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 20),
            Text(
              'Generating image...',
              style: GoogleFonts.lato(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
