import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/song.dart';
import '../../services/song_service.dart';
import '../../theme/app_theme.dart';

class AdminSongFormScreen extends StatefulWidget {
  const AdminSongFormScreen({super.key});

  @override
  State<AdminSongFormScreen> createState() => _AdminSongFormScreenState();
}

class _AdminSongFormScreenState extends State<AdminSongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SongService _songService = SongService();

  final _numberController = TextEditingController();
  final _titleController = TextEditingController();
  final _lyricsEnController = TextEditingController();
  final _lyricsFrController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _lyricsEnController.dispose();
    _lyricsFrController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final song = Song(
        id: '',
        songNumber: int.tryParse(_numberController.text.trim()) ?? 0,
        title: _titleController.text.trim(),
        lyricsEn: _lyricsEnController.text.trim(),
        lyricsFr: _lyricsFrController.text.trim(),
        youtubeLinks: [],
        createdAt: DateTime.now(),
      );
      await _songService.addSong(song);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chanson ajoutée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une chanson')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numéro du cantique
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Numéro du cantique (optionnel)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),

              // Paroles EN
              TextFormField(
                controller: _lyricsEnController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Paroles (Anglais)',
                  prefixIcon: Icon(Icons.translate),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Paroles FR
              TextFormField(
                controller: _lyricsFrController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Paroles (Français)',
                  prefixIcon: Icon(Icons.translate),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                    _isLoading ? 'Enregistrement...' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
