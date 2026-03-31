import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/song.dart';
import '../../services/song_service.dart';
import '../../theme/app_theme.dart';

class AdminSongEditScreen extends StatefulWidget {
  final Song song;
  const AdminSongEditScreen({super.key, required this.song});

  @override
  State<AdminSongEditScreen> createState() => _AdminSongEditScreenState();
}

class _AdminSongEditScreenState extends State<AdminSongEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberController;
  late TextEditingController _titleController;
  late TextEditingController _lyricsEnController;
  late TextEditingController _lyricsFrController;
  final SongService _songService = SongService();
  late TabController _tabController;
  bool _loading = false;
  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _tabController = TabController(length: 3, vsync: this);
    _numberController = TextEditingController(
        text: _currentSong.songNumber > 0
            ? '${_currentSong.songNumber}'
            : '');
    _titleController = TextEditingController(text: _currentSong.title);
    _lyricsEnController =
        TextEditingController(text: _currentSong.lyricsEn);
    _lyricsFrController =
        TextEditingController(text: _currentSong.lyricsFr);
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _lyricsEnController.dispose();
    _lyricsFrController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final updated = _currentSong.copyWith(
        songNumber: int.tryParse(_numberController.text.trim()) ?? 0,
        title: _titleController.text.trim(),
        lyricsEn: _lyricsEnController.text.trim(),
        lyricsFr: _lyricsFrController.text.trim(),
      );
      await _songService.updateSong(updated);
      setState(() => _currentSong = updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chanson mise à jour !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addYoutubeLink() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AddYoutubeLinkSheet(
        onAdd: (link) async {
          await _songService.addYoutubeLink(_currentSong.id, link);
          final updated =
              await _songService.getSongById(_currentSong.id);
          if (updated != null && mounted) {
            setState(() => _currentSong = updated);
          }
        },
      ),
    );
  }

  Future<void> _removeLink(int index) async {
    await _songService.removeYoutubeLink(_currentSong.id, index);
    final updated = await _songService.getSongById(_currentSong.id);
    if (updated != null && mounted) {
      setState(() => _currentSong = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSong.title),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('SAUVEGARDER',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '🇬🇧 EN'),
            Tab(text: '🇫🇷 FR'),
            Tab(text: '🎬 Vidéos'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Numéro + Titre
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'N°',
                        prefixIcon: Icon(Icons.tag, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre *',
                        prefixIcon: Icon(Icons.music_note),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requis'
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // Onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _lyricsEnController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Paroles en anglais...',
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _lyricsFrController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Paroles en français...',
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  _VideosTab(
                    links: _currentSong.youtubeLinks,
                    onAdd: _addYoutubeLink,
                    onRemove: _removeLink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Onglet vidéos ───────────────────────────────────────────

class _VideosTab extends StatelessWidget {
  final List<YoutubeLink> links;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _VideosTab(
      {required this.links,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une vidéo YouTube'),
            ),
          ),
        ),
        Expanded(
          child: links.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off,
                          size: 50, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Aucune vidéo ajoutée',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: links.length,
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_fill,
                            color: Colors.red, size: 32),
                        title: Text(link.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Langue : ${link.lang}',
                                style:
                                    const TextStyle(fontSize: 12)),
                            Text(
                              link.url,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          onPressed: () => onRemove(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Bottom sheet ajout YouTube ──────────────────────────────

class _AddYoutubeLinkSheet extends StatefulWidget {
  final Future<void> Function(YoutubeLink) onAdd;
  const _AddYoutubeLinkSheet({required this.onAdd});

  @override
  State<_AddYoutubeLinkSheet> createState() =>
      _AddYoutubeLinkSheetState();
}

class _AddYoutubeLinkSheetState extends State<_AddYoutubeLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _labelController = TextEditingController();
  String _lang = 'EN';
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final link = YoutubeLink(
      url: _urlController.text.trim(),
      label: _labelController.text.trim().isEmpty
          ? 'Vidéo'
          : _labelController.text.trim(),
      lang: _lang,
    );

    await widget.onAdd(link);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidéo ajoutée !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎬 Ajouter une vidéo YouTube',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Lien YouTube *',
                prefixIcon: Icon(Icons.link),
                hintText: 'https://youtube.com/watch?v=...',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'URL requise';
                if (!v.contains('youtube') && !v.contains('youtu.be')) {
                  return 'Ce n\'est pas un lien YouTube valide';
                }
                return null;
              },
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: Icon(Icons.label_outline),
                hintText: 'Ex: Version live, Instrumentale...',
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _lang,
              decoration: const InputDecoration(
                labelText: 'Langue de la vidéo',
                prefixIcon: Icon(Icons.language),
              ),
              items: const [
                DropdownMenuItem(value: 'EN', child: Text('🇬🇧 Anglais')),
                DropdownMenuItem(value: 'FR', child: Text('🇫🇷 Français')),
                DropdownMenuItem(
                    value: 'Both', child: Text('🌍 Les deux')),
              ],
              onChanged: (v) => setState(() => _lang = v ?? 'EN'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Ajouter la vidéo',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
