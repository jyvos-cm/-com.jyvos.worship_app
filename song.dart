class Song {
  final String id;
  final int songNumber;
  final String title;
  final String lyricsEn;
  final String lyricsFr;
  final List<YoutubeLink> youtubeLinks;
  final DateTime createdAt;

  Song({
    required this.id,
    this.songNumber = 0,
    required this.title,
    required this.lyricsEn,
    required this.lyricsFr,
    required this.youtubeLinks,
    required this.createdAt,
  });

  factory Song.fromMap(Map<String, dynamic> map, String id) {
    return Song(
      id: id,
      songNumber: map['song_number'] ?? 0,
      title: map['title'] ?? '',
      lyricsEn: map['lyrics_en'] ?? '',
      lyricsFr: map['lyrics_fr'] ?? '',
      youtubeLinks: (map['youtube_links'] as List<dynamic>? ?? [])
          .map((e) => YoutubeLink.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'song_number': songNumber,
      'title': title,
      'lyrics_en': lyricsEn,
      'lyrics_fr': lyricsFr,
      'youtube_links': youtubeLinks.map((e) => e.toMap()).toList(),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Song copyWith({
    int? songNumber,
    String? title,
    String? lyricsEn,
    String? lyricsFr,
    List<YoutubeLink>? youtubeLinks,
  }) {
    return Song(
      id: id,
      songNumber: songNumber ?? this.songNumber,
      title: title ?? this.title,
      lyricsEn: lyricsEn ?? this.lyricsEn,
      lyricsFr: lyricsFr ?? this.lyricsFr,
      youtubeLinks: youtubeLinks ?? this.youtubeLinks,
      createdAt: createdAt,
    );
  }
}

class YoutubeLink {
  final String url;
  final String label;
  final String lang;

  YoutubeLink({
    required this.url,
    required this.label,
    required this.lang,
  });

  factory YoutubeLink.fromMap(Map<String, dynamic> map) {
    return YoutubeLink(
      url: map['url'] ?? '',
      label: map['label'] ?? 'Vidéo',
      lang: map['lang'] ?? 'EN',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'label': label,
      'lang': lang,
    };
  }
}
