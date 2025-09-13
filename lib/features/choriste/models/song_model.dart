import 'voice_models.dart';

class Song {
  final String id;
  final String title;
  final String composer;
  final String key;
  final Map<String, String> audioUrls; // URL audio par pupitre (legacy)
  final Map<String, int> audioDurations; // Durée audio par pupitre (en secondes)
  final Duration duration; // Durée du chant (général)
  final double? sizeMb; // Taille du fichier audio en MB
  final DateTime createdAt;

  // Nouvelles propriétés pour la synchronisation
  final SongAvailability availability;
  final int? version;
  final String? localPath;
  final DateTime? lastSync;

  // 🆕 NOUVELLE STRUCTURE HIÉRARCHIQUE
  final Map<String, VoicePart>? voiceParts; // Structure moderne
  final Map<String, Translation>? translations; // Traductions globales
  final ResourcesCollection? resources; // Ressources externes
  final MusicalInfo? musicalInfo; // Métadonnées musicales

  // CHAMPS CALCULÉS LORS DE LA CRÉATION (remplace les getters)
  final Map<String, String> voicePartKeys; // Tonalité par pupitre  
  final Map<String, String> lyrics; // Paroles par pupitre
  final Map<String, String>? phonetics; // Phonétique par pupitre
  final Map<String, String>? translation; // Traduction française par pupitre
  final Map<String, String> maestroNotes; // Notes du chef par pupitre

  const Song({
    required this.id,
    required this.title,
    required this.composer,
    required this.key,
    this.audioUrls = const {},
    this.audioDurations = const {},
    required this.duration,
    this.sizeMb,
    required this.createdAt,
    this.availability = SongAvailability.localOnly,
    this.version,
    this.localPath,
    this.lastSync,
    // Nouveaux paramètres hiérarchiques
    this.voiceParts,
    this.translations,
    this.resources,
    this.musicalInfo,
    // Champs calculés
    this.voicePartKeys = const {},
    this.lyrics = const {},
    this.phonetics,
    this.translation,
    this.maestroNotes = const {},
  });

  factory Song.fromJson(
    Map<String, dynamic> json, {
    SongAvailability? availability,
    int? version,
    String? localPath,
    DateTime? lastSync,
  }) {
    try {
      // Debug: Afficher le JSON complet
      print('🔍 [Song.fromJson] Parsing JSON: ${json.keys.toList()}');
      
      String id;
      try {
        id = json['id'] as String;
        print('✅ [Song.fromJson] id: $id');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing id: $e, valeur: ${json['id']}');
        throw Exception('Erreur parsing id: $e');
      }

      String title;
      try {
        title = json['title'] as String;
        print('✅ [Song.fromJson] title: $title');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing title: $e, valeur: ${json['title']}');
        throw Exception('Erreur parsing title: $e');
      }

      String composer;
      try {
        composer = json['composer'] as String? ?? 'Compositeur inconnu';
        print('✅ [Song.fromJson] composer: $composer');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing composer: $e, valeur: ${json['composer']}');
        composer = 'Compositeur inconnu';
      }

      String key;
      try {
        key = json['key'] as String? ?? '';
        print('✅ [Song.fromJson] key: $key');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing key: $e, valeur: ${json['key']}');
        key = '';
      }

      Duration duration;
      try {
        duration = Duration(seconds: json['duration'] as int? ?? 0);
        print('✅ [Song.fromJson] duration: $duration');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing duration: $e, valeur: ${json['duration']}');
        throw Exception('Erreur parsing duration: $e');
      }

      DateTime createdAt;
      try {
        createdAt = json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now();
        print('✅ [Song.fromJson] createdAt: $createdAt');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing createdAt: $e, valeur: ${json['createdAt']}');
        createdAt = DateTime.now();
      }

      Map<String, VoicePart>? voiceParts;
      try {
        voiceParts = json['voiceParts'] != null
            ? _parseVoiceParts(json['voiceParts'])
            : null;
        print('✅ [Song.fromJson] voiceParts: ${voiceParts?.keys.toList()}');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing voiceParts: $e');
        throw Exception('Erreur parsing voiceParts: $e');
      }

      Map<String, Translation>? translations;
      try {
        translations = json['translations'] != null
            ? _parseTranslations(json['translations'])
            : null;
        print('✅ [Song.fromJson] translations: ${translations?.keys.toList()}');
      } catch (e) {
        print('❌ [Song.fromJson] Erreur parsing translations: $e');
        throw Exception('Erreur parsing translations: $e');
      }

      // Créer audioUrls depuis voiceParts
      final audioUrls = <String, String>{};
      if (voiceParts != null) {
        voiceParts.forEach((partId, voicePart) {
          final firstVoice = voicePart.voices.values.first;
          audioUrls[partId] = firstVoice.audioUrl;
        });
      }

      // Récupérer audioDurations du JSON
      final audioDurations = <String, int>{};
      final jsonAudioDurations = json['audioDurations'] as Map<String, dynamic>?;
      if (jsonAudioDurations != null) {
        jsonAudioDurations.forEach((key, value) {
          audioDurations[key] = value as int;
        });
      }

      // Calculer les champs de compatibilité
      final voicePartKeys = <String, String>{};
      final lyricsMap = <String, String>{};
      final phoneticsMap = <String, String>{};
      final translationMap = <String, String>{};  
      final maestroNotesMap = <String, String>{};

      if (voiceParts != null) {
        // voicePartKeys : tonalité principale pour chaque pupitre
        voiceParts.forEach((partId, part) {
          voicePartKeys[partId] = key;
        });

        // maestroNotes : notes du chef depuis la première voix
        voiceParts.forEach((partId, part) {
          final firstVoice = part.voices.values.first;
          if (firstVoice.maestroNotes?.isNotEmpty == true) {
            maestroNotesMap[partId] = firstVoice.maestroNotes!;
          }
        });
      }

      if (translations != null && voiceParts != null) {
        final firstTranslation = translations.values.first;
        final frenchTranslation = translations['french'];

        // lyrics : paroles de la première traduction
        if (firstTranslation.lyrics.isNotEmpty) {
          voiceParts.keys.forEach((partId) {
            lyricsMap[partId] = firstTranslation.lyrics;
          });
        }

        // phonetics : phonétique de la première traduction
        if (firstTranslation.phonetics?.isNotEmpty == true) {
          voiceParts.keys.forEach((partId) {
            phoneticsMap[partId] = firstTranslation.phonetics!;
          });
        }

        // translation : traduction française si disponible
        if (frenchTranslation?.lyrics.isNotEmpty == true) {
          voiceParts.keys.forEach((partId) {
            translationMap[partId] = frenchTranslation!.lyrics;
          });
        }
      }

      return Song(
        id: id,
        title: title,
        composer: composer,
        key: key,
        audioUrls: audioUrls,
        audioDurations: audioDurations,
        duration: duration,
        sizeMb: json['size_mb'] as double?,
        createdAt: createdAt,
        availability: availability ?? SongAvailability.localOnly,
        version: version,
        localPath: localPath,
        lastSync: lastSync,
        voiceParts: voiceParts,
        translations: translations,
        resources: json['resources'] 
        
        != null
            ? ResourcesCollection.fromJson(json['resources'])
            : null,
        musicalInfo: json['musicalInfo'] != null
            ? MusicalInfo.fromJson(json['musicalInfo'])
            : null,
        // Champs calculés
        voicePartKeys: voicePartKeys,
        lyrics: lyricsMap,
        phonetics: phoneticsMap.isNotEmpty ? phoneticsMap : null,
        translation: translationMap.isNotEmpty ? translationMap : null,
        maestroNotes: maestroNotesMap,
      );
    } catch (e) {
      print('❌ [Song.fromJson] Erreur générale: $e');
      print('❌ [Song.fromJson] JSON complet: $json');
      rethrow;
    }
  }

  /// Helper pour parser les voiceParts depuis le JSON
  static Map<String, VoicePart> _parseVoiceParts(Map<String, dynamic> json) {
    final voiceParts = <String, VoicePart>{};
    json.forEach((id, data) {
      voiceParts[id] = VoicePart.fromJson(id, data);
    });
    return voiceParts;
  }

  /// Helper pour parser les translations depuis le JSON
  static Map<String, Translation> _parseTranslations(
      Map<String, dynamic> json) {
    final translations = <String, Translation>{};
    json.forEach((id, data) {
      translations[id] = Translation.fromJson(data);
    });
    return translations;
  }

  /// Obtenir toutes les voix disponibles par pupitre
  Map<String, String> get allAvailableVoices {
    final voices = <String, String>{};
    
    // D'abord essayer avec la nouvelle structure voiceParts
    if (voiceParts != null && voiceParts!.isNotEmpty) {
      voiceParts!.forEach((partId, part) {
        if (part.voices.isNotEmpty) {
          final firstVoice = part.voices.values.first;
          voices[partId] = firstVoice.audioUrl;
        }
      });
    }
    
    // Si pas de voix trouvées, utiliser audioUrls comme fallback
    if (voices.isEmpty && audioUrls.isNotEmpty) {
      return audioUrls;
    }
    
    return voices;
  }

  /// Méthode pour obtenir les voix par pupitre (nouvelle structure)
  Map<String, List<String>> get voicesByPart {
    if (voiceParts != null) {
      final result = <String, List<String>>{};
      voiceParts!.forEach((partId, part) {
        result[partId] = part.voices.keys.toList();
      });
      return result;
    } else {
      // Fallback sur l'ancienne structure (une voix par pupitre)
      final result = <String, List<String>>{};
      audioUrls.keys.forEach((voiceKey) {
        result[voiceKey] = [voiceKey];
      });
      return result;
    }
  }


  // Factory pour les données Firebase (manifeste)
  factory Song.fromManifest(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      composer: json['composer'] as String,
      key: json['key'] as String, // Sera rempli lors du téléchargement
      sizeMb: json['size_mb'] as double? ?? 0.0,
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      createdAt: DateTime.parse(json['last_updated']),
      availability: SongAvailability.availableForDownload,
      version: json['version'] as int?,
    );
  }

}

enum SongAvailability {
  downloadedAndReady, // ✅ Téléchargé, prêt à jouer
  availableForDownload, // ☁️ Visible mais pas téléchargé
  updateAvailable, // 🔄 Nouvelle version disponible
  downloading, // ⬇️ En cours de téléchargement
  localOnly, // 📱 Seulement en local (pas de réseau)
  syncError, // ❌ Erreur de synchronisation
}
