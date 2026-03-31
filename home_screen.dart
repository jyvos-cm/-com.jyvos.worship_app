import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';
import '../services/song_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'song_detail_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SongService _songService = SongService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isOffline = false;
  List<Song> _offlineSongs = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return songs;
    return songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.songNumber.toString() == q ||
          s.lyricsEn.toLowerCase().contains(q) ||
          s.lyricsFr.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Worship Songs'),
        actions: [
          StreamBuilder<User?>(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final isAdmin = snapshot.data != null;
              if (isAdmin) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.admin_panel_settings),
                  onSelected: (value) async {
                    if (value == 'dashboard') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen()),
                      );
                    } else if (value == 'logout') {
                      await _authService.signOut();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'dashboard',
                      child: Row(children: [
                        Icon(Icons.dashboard, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Tableau de bord'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Déconnexion'),
                      ]),
                    ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.lock_outlined),
                  tooltip: 'Admin',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Bannière hors-ligne
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mode hors-ligne — données en cache',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher par titre, numéro ou paroles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Liste des chansons
          Expanded(
            child: StreamBuilder<List<Song>>(
              stream: _songService.getSongsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  if (!_isOffline) {
                    Future.microtask(() async {
                      final cached = await _songService.getSongsFromCache();
                      if (mounted) {
                        setState(() {
                          _isOffline = true;
                          _offlineSongs = cached;
                        });
                      }
                    });
                  }
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isOffline) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rawSongs = (_isOffline && !snapshot.hasData)
                    ? _offlineSongs
                    : (snapshot.data ?? _offlineSongs);

                if (snapshot.hasData && _isOffline) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isOffline = false);
                  });
                }

                final songs = _filterSongs(rawSongs);

                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.music_off,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun résultat pour "$_searchQuery"'
                              : 'Aucune chanson disponible',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    return _SongCard(song: songs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte chanson ────────────────────────────────────────────

class _SongCard extends StatelessWidget {
  final Song song;
  const _SongCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: song.songNumber > 0
              ? Center(
                  child: Text(
                    '${song.songNumber}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )
              : const Icon(Icons.music_note, color: AppTheme.primary),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textDark),
        ),
        subtitle: Row(
          children: [
            _LangBadge(label: '🇬🇧', hasContent: song.lyricsEn.isNotEmpty),
            const SizedBox(width: 6),
            _LangBadge(label: '🇫🇷', hasContent: song.lyricsFr.isNotEmpty),
            const SizedBox(width: 6),
            if (song.youtubeLinks.isNotEmpty)
              _Badge(
                label: '▶ ${song.youtubeLinks.length}',
                color: Colors.red,
              ),
          ],
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppTheme.textMedium),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
        ),
      ),
    );
  }
}

class _LangBadge extends StatelessWidget {
  final String label;
  final bool hasContent;
  const _LangBadge({required this.label, required this.hasContent});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasContent ? 1.0 : 0.3,
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
