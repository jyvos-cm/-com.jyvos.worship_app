import 'package:flutter/material.dart';
import '../../models/song.dart';
import '../../services/song_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'admin_song_form_screen.dart';
import 'admin_song_edit_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SongService _songService = SongService();
  final AuthService _authService = AuthService();
  String _searchQuery = '';

  Future<void> _confirmDelete(BuildContext context, Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la chanson ?'),
        content: Text(
            'Voulez-vous supprimer "${song.title}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _songService.deleteSong(song.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${song.title}" supprimée.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('👑 Espace Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminSongFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle chanson'),
        backgroundColor: AppTheme.accent,
      ),

      body: Column(
        children: [
          // Header stats
          StreamBuilder<List<Song>>(
            stream: _songService.getSongsStream(),
            builder: (context, snapshot) {
              final total = snapshot.data?.length ?? 0;
              final withVideo = snapshot.data
                      ?.where((s) => s.youtubeLinks.isNotEmpty)
                      .length ??
                  0;
              return Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.primary,
                child: Row(
                  children: [
                    _StatCard(
                        label: 'Total',
                        value: '$total',
                        icon: Icons.library_music),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Avec vidéo',
                        value: '$withVideo',
                        icon: Icons.videocam),
                    const SizedBox(width: 12),
                    _StatCard(
                        label: 'Sans vidéo',
                        value: '${total - withVideo}',
                        icon: Icons.videocam_off),
                  ],
                ),
              );
            },
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Liste admin
          Expanded(
            child: StreamBuilder<List<Song>>(
              stream: _songService.getSongsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final songs = (snapshot.data ?? [])
                    .where((s) =>
                        s.title.toLowerCase().contains(_searchQuery) ||
                        s.songNumber.toString().contains(_searchQuery))
                    .toList();

                if (songs.isEmpty) {
                  return const Center(
                    child: Text('Aucune chanson. Ajoutez-en une !',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return _AdminSongCard(
                      song: song,
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AdminSongEditScreen(song: song)),
                      ),
                      onDelete: () => _confirmDelete(context, song),
                    );
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AdminSongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AdminSongCard(
      {required this.song, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: song.songNumber > 0
              ? Center(
                  child: Text(
                    '${song.songNumber}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              : const Icon(Icons.music_note, color: AppTheme.primary),
        ),
        title: Text(song.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text('🇬🇧',
                style: TextStyle(
                    fontSize: 14,
                    color: song.lyricsEn.isNotEmpty
                        ? null
                        : Colors.grey.withOpacity(0.3))),
            const SizedBox(width: 4),
            Text('🇫🇷',
                style: TextStyle(
                    fontSize: 14,
                    color: song.lyricsFr.isNotEmpty
                        ? null
                        : Colors.grey.withOpacity(0.3))),
            const SizedBox(width: 8),
            if (song.youtubeLinks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('▶ ${song.youtubeLinks.length}',
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              )
            else
              const Text('Pas de vidéo',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: onEdit,
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
