class Choir {
  final String id;
  final String name;
  final String description;
  final String? location;
  final String? website;
  final String? phone;
  final String? email;
  final String? coverImageUrl;
  final String? logoUrl;
  final DateTime foundedDate;
  final String conductor;
  final List<String> genres;
  final ChoirStats statistics;

  const Choir({
    required this.id,
    required this.name,
    required this.description,
    this.location,
    this.website,
    this.phone,
    this.email,
    this.coverImageUrl,
    this.logoUrl,
    required this.foundedDate,
    required this.conductor,
    required this.genres,
    required this.statistics,
  });

  factory Choir.demo() {
    return Choir(
      id: 'shir-choir-001',
      name: 'Shir Choir',
      description: 'Un choeur passionné dédié à l\'excellence musicale et à la beauté des harmonies vocales.',
      location: 'Paris, France',
      website: 'https://shir-choir.fr',
      phone: '+33 1 42 00 00 00',
      email: 'contact@shir-choir.fr',
      coverImageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      logoUrl: 'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
      foundedDate: DateTime(2018, 9, 1),
      conductor: 'Maestro Martin Dupont',
      genres: ['Classique', 'Gospel', 'Contemporain', 'Traditionnel'],
      statistics: ChoirStats.demo(),
    );
  }
}

class ChoirStats {
  final int totalMembers;
  final int totalSongs;
  final Map<String, int> membersByVoicePart;
  final int completedConcerts;
  final double averageLearningProgress;

  const ChoirStats({
    required this.totalMembers,
    required this.totalSongs,
    required this.membersByVoicePart,
    required this.completedConcerts,
    required this.averageLearningProgress,
  });

  factory ChoirStats.demo() {
    return const ChoirStats(
      totalMembers: 28,
      totalSongs: 15,
      membersByVoicePart: {
        'Soprano': 8,
        'Alto': 7,
        'Ténor': 6,
        'Basse': 7,
      },
      completedConcerts: 12,
      averageLearningProgress: 0.75,
    );
  }

  ChoirStats.empty()
      : totalMembers = 0,
        totalSongs = 0,
        membersByVoicePart = const {},
        completedConcerts = 0,
        averageLearningProgress = 0.0;
}

class UpcomingEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? location;
  final EventType type;

  const UpcomingEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.location,
    required this.type,
  });

  static List<UpcomingEvent> demoEvents() {
    return [
      UpcomingEvent(
        id: 'event-001',
        title: 'Répétition générale',
        description: 'Préparation du concert de Noël',
        date: DateTime.now().add(const Duration(days: 3)),
        location: 'Salle de répétition',
        type: EventType.rehearsal,
      ),
      UpcomingEvent(
        id: 'event-002',
        title: 'Concert de Noël',
        description: 'Concert annuel de fin d\'année',
        date: DateTime.now().add(const Duration(days: 10)),
        location: 'Église Saint-Martin',
        type: EventType.concert,
      ),
      UpcomingEvent(
        id: 'event-003',
        title: 'Auditions nouvelles voix',
        description: 'Recrutement de nouveaux membres',
        date: DateTime.now().add(const Duration(days: 21)),
        location: 'Studio 42',
        type: EventType.audition,
      ),
    ];
  }
}

enum EventType {
  rehearsal,
  concert,
  audition,
  workshop,
  meeting,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.rehearsal:
        return 'Répétition';
      case EventType.concert:
        return 'Concert';
      case EventType.audition:
        return 'Audition';
      case EventType.workshop:
        return 'Atelier';
      case EventType.meeting:
        return 'Réunion';
    }
  }

  String get icon {
    switch (this) {
      case EventType.rehearsal:
        return '🎵';
      case EventType.concert:
        return '🎭';
      case EventType.audition:
        return '🎤';
      case EventType.workshop:
        return '🎓';
      case EventType.meeting:
        return '👥';
    }
  }
}