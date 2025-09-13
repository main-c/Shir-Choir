import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/choriste/models/song_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Database? _database;
  String? _songsDirectory;

  /// Initialise la base de données SQLite
  Future<void> initialize() async {
    // Créer le répertoire de stockage des chants
    final appDir = await getApplicationDocumentsDirectory();
    _songsDirectory = '${appDir.path}/data';
    await Directory(_songsDirectory!).create(recursive: true);

    // Initialiser la base de données
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'shir_choir.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Crée les tables de la base de données
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        composer TEXT,
        version INTEGER,
        sync_status TEXT DEFAULT 'localOnly',
        local_path TEXT,
        last_sync TEXT,
        metadata_json TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_status (
        song_id TEXT,
        user_id TEXT,
        status TEXT DEFAULT 'not_started',
        updated_at TEXT,
        FOREIGN KEY (song_id) REFERENCES songs(id)
      )
    ''');
  }

  /// Récupère tous les chants stockés localement
  Future<List<Song>> getStoredSongs() async {
    if (_database == null) await initialize();

    final maps = await _database!.query('songs');
    return maps.map((map) {
      final metadataJson = json.decode(map['metadata_json'] as String);
      return Song.fromJson(
        metadataJson,
        availability: _parseAvailability(map['sync_status'] as String),
        version: map['version'] as int?,
        localPath: map['local_path'] as String?,
        lastSync: map['last_sync'] != null
            ? DateTime.parse(map['last_sync'] as String)
            : null,
      );
    }).toList();
  }

  /// Sauvegarde un chant en local
  Future<void> storeSong(Song song) async {
    if (_database == null) await initialize();

    await _database!.insert(
      'songs',
      {
        'id': song.id,
        'title': song.title,
        'composer': song.composer,
        'version': song.version,
        'sync_status': song.availability.name,
        'local_path': song.localPath,
        'last_sync': song.lastSync?.toIso8601String(),
        'metadata_json': json.encode({
          'id': song.id,
          'title': song.title,
          'composer': song.composer,
          'key': song.key,
          'voicePartKeys': song.voicePartKeys,
          'lyrics': song.lyrics,
          'phonetics': song.phonetics,
          'translation': song.translation,
          'audioUrls': song.audioUrls,
          'audioDurations': song.audioDurations,
          'maestroNotes': song.maestroNotes,
          'duration': song.duration.inSeconds,
          'createdAt': song.createdAt.toIso8601String(),
          // 🆕 NOUVELLE STRUCTURE HIÉRARCHIQUE
          'voiceParts': song.voiceParts?.map((id, part) => MapEntry(id, part.toJson())),
          'translations': song.translations?.map((id, trans) => MapEntry(id, trans.toJson())),
          'resources': song.resources?.toJson(),
          'musicalInfo': song.musicalInfo?.toJson(),
        }),
        'created_at': song.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Met à jour le statut de synchronisation d'un chant
  Future<void> updateSongStatus(String songId, SongAvailability status) async {
    if (_database == null) await initialize();

    await _database!.update(
      'songs',
      {'sync_status': status.name},
      where: 'id = ?',
      whereArgs: [songId],
    );
  }

  /// Récupère le chemin du répertoire des chants
  String get songsDirectory => _songsDirectory!;

  /// Parse le statut de disponibilité depuis la DB
  SongAvailability _parseAvailability(String status) {
    return SongAvailability.values.firstWhere(
      (e) => e.name == status,
      orElse: () => SongAvailability.localOnly,
    );
  }

  /// Supprime un chant de la base de données et du stockage
  Future<void> deleteSong(String songId) async {
    if (_database == null) await initialize();

    // Supprimer de la DB
    await _database!.delete('songs', where: 'id = ?', whereArgs: [songId]);

    // Supprimer les fichiers locaux
    final songDir = Directory('$_songsDirectory/$songId');
    if (await songDir.exists()) {
      await songDir.delete(recursive: true);
    }
  }
}
