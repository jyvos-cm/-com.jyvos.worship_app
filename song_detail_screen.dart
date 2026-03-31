import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openYoutube(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la vidéo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.songNumber > 0
            ? 'N°${song.songNumber} — ${song.title}'
            : song.title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '🇬🇧 English'),
            Tab(text: '🇫🇷 Français'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Paroles
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LyricsView(lyrics: song.lyricsEn, lang: 'EN'),
                _LyricsView(lyrics: song.lyricsFr, lang: 'FR'),
              ],
            ),
          ),

          // Section vidéos
          if (song.youtubeLinks.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎬 Vidéos disponibles',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),
                  ...song.youtubeLinks.map((link) => _YoutubeButton(
                        link: link,
                        onTap: () => _openYoutube(link.url),
                      )),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.videocam_off, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('Aucune vidéo disponible',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  final String lyrics;
  final String lang;
  const _LyricsView({required this.lyrics, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.text_snippet_outlined,
                size: 50, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Paroles $lang non disponibles',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        lyrics,
        style: const TextStyle(
          fontSize: 16,
          height: 1.8,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}

class _YoutubeButton extends StatelessWidget {
  final YoutubeLink link;
  final VoidCallback onTap;
  const _YoutubeButton({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.red.withOpacity(0.05),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill,
                  color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(link.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    Text('Langue : ${link.lang}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMedium)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
