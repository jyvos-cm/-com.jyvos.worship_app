import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongService {
  final CollectionReference _songs =
      FirebaseFirestore.instance.collection('songs');

  static const String _cacheKey = 'worship_songs_cache';

  // ─────────────────────────────────────────────
  // 🔵 Stream temps réel + cache hors-ligne
  // ─────────────────────────────────────────────

  Stream<List<Song>> getSongsStream() {
    return _songs
        .orderBy('song_number')
        .snapshots()
        .map((snapshot) {
      final songs = snapshot.docs
          .map((doc) =>
              Song.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      _saveCache(songs);
      return songs;
    });
  }

  // Charger depuis le cache local (hors-ligne)
  Future<List<Song>> getSongsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((e) => Song.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // Sauvegarder dans le cache local
  Future<void> _saveCache(List<Song> songs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = songs.map((s) => {...s.toMap(), 'id': s.id}).toList();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // 🔵 Une chanson par ID
  // ─────────────────────────────────────────────

  Future<Song?> getSongById(String id) async {
    final doc = await _songs.doc(id).get();
    if (!doc.exists) return null;
    return Song.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ─────────────────────────────────────────────
  // 🟢 Création
  // ─────────────────────────────────────────────

  Future<String> addSong(Song song) async {
    final docRef = await _songs.add(song.toMap());
    return docRef.id;
  }

  // ─────────────────────────────────────────────
  // 🟡 Modification
  // ─────────────────────────────────────────────

  Future<void> updateSong(Song song) async {
    await _songs.doc(song.id).update(song.toMap());
  }

  Future<void> addYoutubeLink(String songId, YoutubeLink link) async {
    final song = await getSongById(songId);
    if (song == null) return;
    final updatedLinks = [...song.youtubeLinks, link];
    await _songs.doc(songId).update({
      'youtube_links': updatedLinks.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> removeYoutubeLink(String songId, int linkIndex) async {
    final song = await getSongById(songId);
    if (song == null) return;
    final updatedLinks = [...song.youtubeLinks];
    updatedLinks.removeAt(linkIndex);
    await _songs.doc(songId).update({
      'youtube_links': updatedLinks.map((e) => e.toMap()).toList(),
    });
  }

  // ─────────────────────────────────────────────
  // 🔴 Suppression
  // ─────────────────────────────────────────────

  Future<void> deleteSong(String songId) async {
    await _songs.doc(songId).delete();
  }
}
