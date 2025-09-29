/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 1
/// Strings: 53
///
/// Built on 2025-09-05 at 06:51 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
  en(languageCode: 'en', build: Translations.build);

  const AppLocale(
      {required this.languageCode,
      this.scriptCode,
      this.countryCode,
      required this.build}); // ignore: unused_element

  @override
  final String languageCode;
  @override
  final String? scriptCode;
  @override
  final String? countryCode;
  @override
  final TranslationBuilder<AppLocale, Translations> build;

  /// Gets current instance managed by [LocaleSettings].
  Translations get translations =>
      LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider
    extends BaseTranslationProvider<AppLocale, Translations> {
  TranslationProvider({required super.child})
      : super(settings: LocaleSettings.instance);

  static InheritedLocaleData<AppLocale, Translations> of(
          BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
  Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings
    extends BaseFlutterLocaleSettings<AppLocale, Translations> {
  LocaleSettings._() : super(utils: AppLocaleUtils.instance);

  static final instance = LocaleSettings._();

  // static aliases (checkout base methods for documentation)
  static AppLocale get currentLocale => instance.currentLocale;
  static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
  static AppLocale setLocale(AppLocale locale,
          {bool? listenToDeviceLocale = false}) =>
      instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
  static AppLocale setLocaleRaw(String rawLocale,
          {bool? listenToDeviceLocale = false}) =>
      instance.setLocaleRaw(rawLocale,
          listenToDeviceLocale: listenToDeviceLocale);
  static AppLocale useDeviceLocale() => instance.useDeviceLocale();
  @Deprecated('Use [AppLocaleUtils.supportedLocales]')
  static List<Locale> get supportedLocales => instance.supportedLocales;
  @Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]')
  static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
  static void setPluralResolver(
          {String? language,
          AppLocale? locale,
          PluralResolver? cardinalResolver,
          PluralResolver? ordinalResolver}) =>
      instance.setPluralResolver(
        language: language,
        locale: locale,
        cardinalResolver: cardinalResolver,
        ordinalResolver: ordinalResolver,
      );
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
  AppLocaleUtils._()
      : super(baseLocale: _baseLocale, locales: AppLocale.values);

  static final instance = AppLocaleUtils._();

  // static aliases (checkout base methods for documentation)
  static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
  static AppLocale parseLocaleParts(
          {required String languageCode,
          String? scriptCode,
          String? countryCode}) =>
      instance.parseLocaleParts(
          languageCode: languageCode,
          scriptCode: scriptCode,
          countryCode: countryCode);
  static AppLocale findDeviceLocale() => instance.findDeviceLocale();
  static List<Locale> get supportedLocales => instance.supportedLocales;
  static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations.build(
      {Map<String, Node>? overrides,
      PluralResolver? cardinalResolver,
      PluralResolver? ordinalResolver})
      : assert(overrides == null,
            'Set "translation_overrides: true" in order to enable this feature.'),
        $meta = TranslationMetadata(
          locale: AppLocale.en,
          overrides: overrides ?? {},
          cardinalResolver: cardinalResolver,
          ordinalResolver: ordinalResolver,
        ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  // Translations
  late final _StringsAppEn app = _StringsAppEn._(_root);
  late final _StringsAuthEn auth = _StringsAuthEn._(_root);
  late final _StringsDashboardEn dashboard = _StringsDashboardEn._(_root);
  late final _StringsSongEn song = _StringsSongEn._(_root);
  late final _StringsAudioEn audio = _StringsAudioEn._(_root);
  late final _StringsSettingsEn settings = _StringsSettingsEn._(_root);
}

// Path: app
class _StringsAppEn {
  _StringsAppEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => 'Shir Book';
  String get subtitle =>
      'Apprenez, gérez et maîtrisez votre répertoire choral en un seul endroit';
}

// Path: auth
class _StringsAuthEn {
  _StringsAuthEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get login => 'Se connecter';
  String get selectRole => 'Sélectionnez votre rôle';
  String get choriste => 'Choriste';
  String get maestro => 'Maestro';
  String get selectVoicePart => 'Choisissez votre pupitre';
  String get soprano => 'Soprano';
  String get alto => 'Alto';
  String get tenor => 'Ténor';
  String get bass => 'Basse';
  String get enterName => 'Entrez votre nom';
  String get namePlaceholder => 'Votre nom';
}

// Path: dashboard
class _StringsDashboardEn {
  _StringsDashboardEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get welcome => 'Bienvenue';
  String get repertoire => 'Répertoire';
  String get searchSongs => 'Rechercher des chants...';
  String get searchPlaceholder => 'Rechercher titre, compositeur...';
  String get filterAll => 'Tous';
  String get filterNotStarted => 'Non commencé';
  String get filterInProgress => 'En cours';
  String get filterMastered => 'Maîtrisé';
  String get notifications => 'Notifications';
  String get nowPlaying => 'En lecture';
  String get progress => 'Progression';
  String get noSongsFound => 'Aucun chant trouvé';
  String get clearSearch => 'Effacer la recherche';
  String get totalSongs => 'chants au total';
}

// Path: song
class _StringsSongEn {
  _StringsSongEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get composer => 'Compositeur';
  String get key => 'Tonalité';
  String get voicePart => 'Pupitre';
  String get status => 'Statut';
  String get notStarted => 'Non commencé';
  String get inProgress => 'En cours d\'apprentissage';
  String get mastered => 'Maîtrisé';
  String get lyrics => 'Paroles';
  String get phonetics => 'Phonétique';
  String get translation => 'Traduction';
  String get maestroNotes => 'Notes du maestro';
}

// Path: audio
class _StringsAudioEn {
  _StringsAudioEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get play => 'Lecture';
  String get pause => 'Pause';
  String get tempo => 'Tempo';
  String get volume => 'Volume';
  String get reset => 'Réinitialiser';
  String get allVoices => 'Toutes les voix';
}

// Path: settings
class _StringsSettingsEn {
  _StringsSettingsEn._(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => 'Paramètres';
  String get account => 'Compte';
  String get theme => 'Thème';
  String get themeSystem => 'Système';
  String get themeLight => 'Clair';
  String get themeDark => 'Sombre';
  String get language => 'Langue';
  String get notifications => 'Notifications';
  String get about => 'À propos';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'app.title':
        return 'Shir Book';
      case 'app.subtitle':
        return 'Interface de gestion de chorale';
      case 'auth.login':
        return 'Se connecter';
      case 'auth.selectRole':
        return 'Sélectionnez votre rôle';
      case 'auth.choriste':
        return 'Choriste';
      case 'auth.maestro':
        return 'Maestro';
      case 'auth.selectVoicePart':
        return 'Choisissez votre pupitre';
      case 'auth.soprano':
        return 'Soprano';
      case 'auth.alto':
        return 'Alto';
      case 'auth.tenor':
        return 'Ténor';
      case 'auth.bass':
        return 'Basse';
      case 'auth.enterName':
        return 'Entrez votre nom';
      case 'auth.namePlaceholder':
        return 'Votre nom';
      case 'dashboard.welcome':
        return 'Bienvenue';
      case 'dashboard.repertoire':
        return 'Répertoire';
      case 'dashboard.searchSongs':
        return 'Rechercher des chants...';
      case 'dashboard.searchPlaceholder':
        return 'Rechercher titre, compositeur...';
      case 'dashboard.filterAll':
        return 'Tous';
      case 'dashboard.filterNotStarted':
        return 'Non commencé';
      case 'dashboard.filterInProgress':
        return 'En cours';
      case 'dashboard.filterMastered':
        return 'Maîtrisé';
      case 'dashboard.notifications':
        return 'Notifications';
      case 'dashboard.nowPlaying':
        return 'En lecture';
      case 'dashboard.progress':
        return 'Progression';
      case 'dashboard.noSongsFound':
        return 'Aucun chant trouvé';
      case 'dashboard.clearSearch':
        return 'Effacer la recherche';
      case 'dashboard.totalSongs':
        return 'chants au total';
      case 'song.composer':
        return 'Compositeur';
      case 'song.key':
        return 'Tonalité';
      case 'song.voicePart':
        return 'Pupitre';
      case 'song.status':
        return 'Statut';
      case 'song.notStarted':
        return 'Non commencé';
      case 'song.inProgress':
        return 'En cours d\'apprentissage';
      case 'song.mastered':
        return 'Maîtrisé';
      case 'song.lyrics':
        return 'Paroles';
      case 'song.phonetics':
        return 'Phonétique';
      case 'song.translation':
        return 'Traduction';
      case 'song.maestroNotes':
        return 'Notes du maestro';
      case 'audio.play':
        return 'Lecture';
      case 'audio.pause':
        return 'Pause';
      case 'audio.tempo':
        return 'Tempo';
      case 'audio.volume':
        return 'Volume';
      case 'audio.reset':
        return 'Réinitialiser';
      case 'audio.allVoices':
        return 'Toutes les voix';
      case 'settings.title':
        return 'Paramètres';
      case 'settings.account':
        return 'Compte';
      case 'settings.theme':
        return 'Thème';
      case 'settings.themeSystem':
        return 'Système';
      case 'settings.themeLight':
        return 'Clair';
      case 'settings.themeDark':
        return 'Sombre';
      case 'settings.language':
        return 'Langue';
      case 'settings.notifications':
        return 'Notifications';
      case 'settings.about':
        return 'À propos';
      default:
        return null;
    }
  }
}
