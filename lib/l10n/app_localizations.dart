import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// Texte d'invitation à ajouter des fichiers
  ///
  /// In fr, this message translates to:
  /// **'ou cliquez pour en ajouter'**
  String get addFiles;

  /// Message d'installation via Homebrew avec paramètres dynamiques
  ///
  /// In fr, this message translates to:
  /// **'Homebrew est déjà installé sur votre Mac, vous pouvez installer {name} en tapant la commande\n\nbrew install {bin}\n\ndans votre terminal.\nAttendez la fin de l\'installation puis cliquez sur OK.'**
  String brewMessage(String bin, String name);

  /// Bouton pour parcourir les fichiers
  ///
  /// In fr, this message translates to:
  /// **'Parcourir'**
  String get browse;

  /// Lien de donation/soutien
  ///
  /// In fr, this message translates to:
  /// **'Achète-moi un café'**
  String get buyMeCoffee;

  /// Bouton d'annulation
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Option pour changer le nom du fichier de sortie
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom du fichier compressé'**
  String get changeCompressedName;

  /// Action de vérification des mises à jour
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les mises à jour'**
  String get checkUpdates;

  /// Alternative d'ajout de fichiers par clic
  ///
  /// In fr, this message translates to:
  /// **'ou cliquez pour en ajouter'**
  String get clickAdd;

  /// Invitation à démarrer une nouvelle compression
  ///
  /// In fr, this message translates to:
  /// **'Cliquez ici pour compresser de nouveaux fichiers'**
  String get clickNew;

  /// Option de sélection de fichiers par clic
  ///
  /// In fr, this message translates to:
  /// **'ou cliquez pour sélectionner vos fichiers'**
  String get clickSelect;

  /// Statut d'opération terminée
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get completed;

  /// Action de compression de fichiers
  ///
  /// In fr, this message translates to:
  /// **'Compresser'**
  String get compress;

  /// Message indiquant le pourcentage de compression réalisé
  ///
  /// In fr, this message translates to:
  /// **'Au total vos fichiers sont {percent}% plus légers.'**
  String compressedMessage(int percent);

  /// Indicateur de progression de compression
  ///
  /// In fr, this message translates to:
  /// **'Compression en cours...'**
  String get compressing;

  /// Message d'erreur de compression avec détails
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la compression - {error}.'**
  String compressionError(String error);

  /// Avertissement quand la compression n'apporte pas de gain significatif
  ///
  /// In fr, this message translates to:
  /// **'La compression n\'est pas assez efficace, le fichier original est conservé.'**
  String get compressionNotEffective;

  /// Confirmation avant fermeture de l'application
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir quitter ?'**
  String get confirmQuit;

  /// Message de confirmation de conversion avec format de sortie
  ///
  /// In fr, this message translates to:
  /// **'Tous vos fichiers ont été convertis en {format}.'**
  String convertedMessage(String format);

  /// Affichage du chemin actuel d'un outil
  ///
  /// In fr, this message translates to:
  /// **'Chemin actuel de {name}'**
  String currentPath(String name);

  /// Option de configuration personnalisée
  ///
  /// In fr, this message translates to:
  /// **'Personnalisée'**
  String get custom;

  /// Paramètre du dossier de destination par défaut
  ///
  /// In fr, this message translates to:
  /// **'Dossier de sortie par défaut'**
  String get defaultOutputDirectory;

  /// Option pour supprimer les fichiers sources après traitement
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les originaux'**
  String get deleteOriginals;

  /// Erreur de dossier introuvable
  ///
  /// In fr, this message translates to:
  /// **'Le dossier n\'existe pas.'**
  String get dirPathError;

  /// Message de succès de traitement des fichiers
  ///
  /// In fr, this message translates to:
  /// **'Vos fichiers ont été {type} avec succès.'**
  String doneMessage(String type);

  /// Action de téléchargement
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get download;

  /// Invitation au glisser-déposer de fichiers
  ///
  /// In fr, this message translates to:
  /// **'Déposez vos fichiers ici'**
  String get dropFiles;

  /// Indication que le glisser-déposer est accepté
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez lâcher !'**
  String get dropNow;

  /// Erreur de chemin vide ou invalide
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un chemin valide.'**
  String get emptyPath;

  /// Message d'erreur générique
  ///
  /// In fr, this message translates to:
  /// **'Une erreur s\'est produite.'**
  String get endError;

  /// Erreur spécifique : aucune conversion effectuée
  ///
  /// In fr, this message translates to:
  /// **'Aucun fichier n\'a été converti.'**
  String get endErrorDescription0;

  /// Erreur partielle : traitement incomplet
  ///
  /// In fr, this message translates to:
  /// **'Certains fichiers n\'ont pas pu être traité.'**
  String get endErrorDescription1;

  /// Titre générique d'erreur
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// Action d'exploration de fichiers/dossiers
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get explore;

  /// Invitation à donner un retour utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Donnez-moi votre avis ! '**
  String get feedback;

  /// Message de demande d'installation de FFmpeg
  ///
  /// In fr, this message translates to:
  /// **'Un module (ffmpeg) est nécessaire pour continuer. Voulez-vous l\'installer ? Une connexion internet est requise pour l\'installation.'**
  String get ffmpegRequired;

  /// Explication du rôle de FFmpeg
  ///
  /// In fr, this message translates to:
  /// **'FFmpeg vous permet de compresser\net convertir des fichiers audios et vidéos.'**
  String get ffmpegTooltip;

  /// Erreur de fichier manquant post-compression
  ///
  /// In fr, this message translates to:
  /// **'Fichier introuvable après la compression.'**
  String get fileNotFoundAfterCompression;

  /// Erreur de fichier introuvable
  ///
  /// In fr, this message translates to:
  /// **'Le fichier n\'existe pas.'**
  String get filePathError;

  /// Confirmation de fin de traitement
  ///
  /// In fr, this message translates to:
  /// **'Vos fichiers sont prêts !'**
  String get filesReady;

  /// Lien vers le code source du projet
  ///
  /// In fr, this message translates to:
  /// **'Dépôt GitHub'**
  String get githubRepository;

  /// Invitation au retour utilisateur
  ///
  /// In fr, this message translates to:
  /// **'Donnez-nous votre avis'**
  String get giveFeedback;

  /// Niveau de qualité bon
  ///
  /// In fr, this message translates to:
  /// **'Bonne'**
  String get good;

  /// Message de prérequis pour la compression PDF
  ///
  /// In fr, this message translates to:
  /// **'GhostScript est requis pour compresser des PDFs.'**
  String get gsRequired;

  /// Confirmation d'installation de GhostScript
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant compresser vos fichiers PDF.'**
  String get gsSuccess;

  /// Demande d'envoi de fichiers problématiques pour debug
  ///
  /// In fr, this message translates to:
  /// **'Pour nous aider à trouver plus simplement la cause de cette erreur, merci de nous envoyer les fichiers posants problèmes en pièce jointe.'**
  String get helpUsWithAttachments;

  /// Indicateur de localisation
  ///
  /// In fr, this message translates to:
  /// **'ici'**
  String get here;

  /// Niveau de qualité élevé
  ///
  /// In fr, this message translates to:
  /// **'Haute'**
  String get high;

  /// Option d'inclusion de fichiers dans un rapport
  ///
  /// In fr, this message translates to:
  /// **'Inclure les fichiers (recommandé)'**
  String get includeFiles;

  /// Explication de l'utilité d'inclure les fichiers
  ///
  /// In fr, this message translates to:
  /// **'Cela peut nous permettre de trouver l\'erreur plus rapidement.'**
  String get includeFilesDescription;

  /// Action d'installation
  ///
  /// In fr, this message translates to:
  /// **'Installer'**
  String get install;

  /// Instructions d'installation de GhostScript - partie 1
  ///
  /// In fr, this message translates to:
  /// **'• Pour installer GhostScript, cliquez '**
  String get installGs0;

  /// Instructions d'installation détaillées pour Windows
  ///
  /// In fr, this message translates to:
  /// **'pour télécharger le fichier d\'installation.\n\n• Exécutez le fichier téléchargé puis suivez les instructions données par l\'installeur.\n\n• Une fois l\'installation terminée, cliquez sur le bouton \'OK\' pour continuer.\n\n• L\'installation nécessite une connexion à Internet.'**
  String get installGs1MagickWindows;

  /// Instructions d'installation spécifiques à Linux
  ///
  /// In fr, this message translates to:
  /// **'pour télécharger le fichier AppImage.\n\n• Dans le terminal faites les commandes\n\nchmod +x <fichier>\nsudo mv <fichier> /usr/local/bin\n\n• L\'installation nécessite une connexion à Internet.'**
  String get installMagickLinux;

  /// Message d'erreur lors de l'installation d'un outil
  ///
  /// In fr, this message translates to:
  /// **'Une erreur s\'est produite lors de la vérification de {name}.'**
  String installationError(String name);

  /// Message d'erreur générique d'installation
  ///
  /// In fr, this message translates to:
  /// **'Désolé mais une erreur s\'est produite.\nAssurez-vous d\'être connecté à Internet.'**
  String get installationErrorGeneric;

  /// Conseil en cas d'erreur d'installation
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que vous avez bien suivi les instructions.'**
  String get installationErrorMessage;

  /// Message de succès d'installation d'un outil
  ///
  /// In fr, this message translates to:
  /// **'{name} a été installé avec succès.'**
  String installationSuccess(String name);

  /// Indicateur de progression d'installation
  ///
  /// In fr, this message translates to:
  /// **'Installation en cours'**
  String get installing;

  /// Option de conservation des métadonnées de fichiers
  ///
  /// In fr, this message translates to:
  /// **'Garder les métadonnées'**
  String get keepMetadata;

  /// Paramètre de langue de l'interface
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// Action de localisation d'un fichier/dossier
  ///
  /// In fr, this message translates to:
  /// **'Localiser'**
  String get locate;

  /// Action spécifique de localisation de FFmpeg
  ///
  /// In fr, this message translates to:
  /// **'Localiser ffmpeg'**
  String get locateFfmpeg;

  /// Niveau de qualité bas
  ///
  /// In fr, this message translates to:
  /// **'Faible'**
  String get low;

  /// Message de prérequis pour la compression d'images
  ///
  /// In fr, this message translates to:
  /// **'ImageMagick est requis pour compresser des images.'**
  String get magickRequired;

  /// Confirmation d'installation d'ImageMagick
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez maintenant compresser vos images.'**
  String get magickSuccess;

  /// Niveau de qualité moyen
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get medium;

  /// Notification de mise à jour disponible
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle version est disponible !'**
  String get newVersionAvailable;

  /// Erreur spécifique : pas de piste audio pour conversion MP3
  ///
  /// In fr, this message translates to:
  /// **'Aucune piste audio n\'a été trouvée dans le fichier pour la conversion MP3.'**
  String get noAudioTrackFound;

  /// Action d'ouverture dans l'explorateur Windows
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans l\'explorateur'**
  String get openExplorer;

  /// Action d'ouverture dans le Finder macOS
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans Finder'**
  String get openFinder;

  /// Paramètre du dossier de destination
  ///
  /// In fr, this message translates to:
  /// **'Dossier de sortie'**
  String get outputDirectory;

  /// Message d'attente pendant un traitement
  ///
  /// In fr, this message translates to:
  /// **'Veuillez patienter'**
  String get pleaseWait;

  /// Indicateur du nombre de fichiers traités
  ///
  /// In fr, this message translates to:
  /// **'fichiers traités'**
  String get processedFiles;

  /// Paramètre de qualité de compression
  ///
  /// In fr, this message translates to:
  /// **'Qualité'**
  String get quality;

  /// Action de fermeture de l'application
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get quit;

  /// Avertissement avant fermeture pendant un traitement
  ///
  /// In fr, this message translates to:
  /// **'Un processus de compression/conversion est en cours, voulez-vous vraiment quitter ?'**
  String get quitWarning;

  /// Action de signalement d'erreur par email
  ///
  /// In fr, this message translates to:
  /// **'Signaler par mail'**
  String get reportError;

  /// Titre pour les modules/outils nécessaires
  ///
  /// In fr, this message translates to:
  /// **'Module requis'**
  String get requiredModule;

  /// Action de remise à zéro des paramètres
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// Action de redémarrage de l'application
  ///
  /// In fr, this message translates to:
  /// **'Redémarrer'**
  String get restart;

  /// Demande de confirmation de redémarrage
  ///
  /// In fr, this message translates to:
  /// **'Souhaitez-vous redémarrer l\'application pour appliquer les modifications ?'**
  String get restartNowQuestion;

  /// Information sur la nécessité de redémarrer
  ///
  /// In fr, this message translates to:
  /// **'Vous devez redémarrer l\'application pour que cette modification prenne effet.'**
  String get restartRequired;

  /// Action de nouvelle tentative
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Indication d'économie d'espace disque
  ///
  /// In fr, this message translates to:
  /// **'économisés'**
  String get saved;

  /// Action d'affichage des erreurs détaillées
  ///
  /// In fr, this message translates to:
  /// **'Voir les erreurs'**
  String get seeErrors;

  /// Page/section de configuration
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// Information sur la taille de fichier
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get size;

  /// Instruction pour installer un outil spécifique
  ///
  /// In fr, this message translates to:
  /// **'• Pour installer {name}, cliquez '**
  String toInstall(String name);

  /// Infobulle explicative pour GhostScript
  ///
  /// In fr, this message translates to:
  /// **'GhostScript vous permet de compresser des fichiers PDF.'**
  String get tooltipGhostscript;

  /// Infobulle explicative pour ImageMagick
  ///
  /// In fr, this message translates to:
  /// **'ImageMagick vous permet de compresser des images.'**
  String get tooltipImageMagick;

  /// Erreur de format de fichier non pris en charge
  ///
  /// In fr, this message translates to:
  /// **'Format non supporté.'**
  String get unsupportedFileFormat;

  /// Catégorie de fichiers vidéo
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get videos;

  /// Statut d'attente de traitement
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get waiting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
