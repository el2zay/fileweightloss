// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get addFiles => 'ou cliquez pour en ajouter';

  @override
  String brewMessage(String bin, String name) {
    return 'Homebrew est déjà installé sur votre Mac, vous pouvez installer $name en tapant la commande\n\nbrew install $bin\n\ndans votre terminal.\nAttendez la fin de l\'installation puis cliquez sur OK.';
  }

  @override
  String get browse => 'Parcourir';

  @override
  String get buyMeCoffee => 'Achète-moi un café';

  @override
  String get cancel => 'Annuler';

  @override
  String get changeCompressedName => 'Modifier le nom du fichier compressé';

  @override
  String get checkUpdates => 'Vérifier les mises à jour';

  @override
  String get clickAdd => 'ou cliquez pour en ajouter';

  @override
  String get clickNew => 'Cliquez ici pour compresser de nouveaux fichiers';

  @override
  String get clickSelect => 'ou cliquez pour sélectionner vos fichiers';

  @override
  String get completed => 'Terminé';

  @override
  String get compress => 'Compresser';

  @override
  String compressedMessage(int percent) {
    return 'Au total vos fichiers sont $percent% plus légers.';
  }

  @override
  String get compressing => 'Compression en cours...';

  @override
  String compressionError(String error) {
    return 'Erreur lors de la compression - $error.';
  }

  @override
  String get compressionNotEffective =>
      'La compression n\'est pas assez efficace, le fichier original est conservé.';

  @override
  String get confirmQuit => 'Êtes-vous sûr de vouloir quitter ?';

  @override
  String convertedMessage(String format) {
    return 'Tous vos fichiers ont été convertis en $format.';
  }

  @override
  String currentPath(String name) {
    return 'Chemin actuel de $name';
  }

  @override
  String get custom => 'Personnalisée';

  @override
  String get defaultOutputDirectory => 'Dossier de sortie par défaut';

  @override
  String get deleteOriginals => 'Supprimer les originaux';

  @override
  String get dirPathError => 'Le dossier n\'existe pas.';

  @override
  String doneMessage(String type) {
    return 'Vos fichiers ont été $type avec succès.';
  }

  @override
  String get download => 'Télécharger';

  @override
  String get dropFiles => 'Déposez vos fichiers ici';

  @override
  String get dropNow => 'Vous pouvez lâcher !';

  @override
  String get emptyPath => 'Veuillez entrer un chemin valide.';

  @override
  String get endError => 'Une erreur s\'est produite.';

  @override
  String get endErrorDescription0 => 'Aucun fichier n\'a été converti.';

  @override
  String get endErrorDescription1 =>
      'Certains fichiers n\'ont pas pu être traité.';

  @override
  String get error => 'Erreur';

  @override
  String explanationMinCompression(int value) {
    return 'Si la compression est inférieure à $value%, le fichier ne sera pas compressé.';
  }

  @override
  String get explore => 'Explorer';

  @override
  String get feedback => 'Donnez-moi votre avis ! ';

  @override
  String get ffmpegRequired =>
      'Un module (ffmpeg) est nécessaire pour continuer. Voulez-vous l\'installer ? Une connexion internet est requise pour l\'installation.';

  @override
  String get ffmpegTooltip =>
      'FFmpeg vous permet de compresser\net convertir des fichiers audios et vidéos.';

  @override
  String get fileNotFoundAfterCompression =>
      'Fichier introuvable après la compression.';

  @override
  String get filePathError => 'Le fichier n\'existe pas.';

  @override
  String get filesReady => 'Vos fichiers sont prêts !';

  @override
  String get githubRepository => 'Dépôt GitHub';

  @override
  String get giveFeedback => 'Donnez-nous votre avis';

  @override
  String get good => 'Bonne';

  @override
  String get gsRequired => 'GhostScript est requis pour compresser des PDFs.';

  @override
  String get gsSuccess => 'Vous pouvez maintenant compresser vos fichiers PDF.';

  @override
  String get helpUsWithAttachments =>
      'Pour nous aider à trouver plus simplement la cause de cette erreur, merci de nous envoyer les fichiers posants problèmes en pièce jointe.';

  @override
  String get here => 'ici';

  @override
  String get high => 'Haute';

  @override
  String get includeFiles => 'Inclure les fichiers (recommandé)';

  @override
  String get includeFilesDescription =>
      'Cela peut nous permettre de trouver l\'erreur plus rapidement.';

  @override
  String get install => 'Installer';

  @override
  String get installGs0 => '• Pour installer GhostScript, cliquez ';

  @override
  String get installGs1MagickWindows =>
      'pour télécharger le fichier d\'installation.\n\n• Exécutez le fichier téléchargé puis suivez les instructions données par l\'installeur.\n\n• Une fois l\'installation terminée, cliquez sur le bouton \'OK\' pour continuer.\n\n• L\'installation nécessite une connexion à Internet.';

  @override
  String get installMagickLinux =>
      'pour télécharger le fichier AppImage.\n\n• Dans le terminal faites les commandes\n\nchmod +x <fichier>\nsudo mv <fichier> /usr/local/bin\n\n• L\'installation nécessite une connexion à Internet.';

  @override
  String get installMagickMacos =>
      'Malheureusement nous n\'avons pas trouvé de solution pour installer ImageMagick sur macOS sans HomeBrew.\n\nPour installer ImageMagick, vous devez installer HomeBrew en suivant les instructions sur le site officiel https://brew.sh/fr puis installer ImageMagick en tapant la commande suivante dans un terminal.\n\nbrew install imagemagick\n\nUne fois l\'installation terminée, cliquez sur le bouton \'OK\' pour continuer.';

  @override
  String installationError(String name) {
    return 'Une erreur s\'est produite lors de la vérification de $name.';
  }

  @override
  String get installationErrorGeneric =>
      'Désolé mais une erreur s\'est produite.\nAssurez-vous d\'être connecté à Internet.';

  @override
  String get installationErrorMessage =>
      'Vérifiez que vous avez bien suivi les instructions.';

  @override
  String installationSuccess(String name) {
    return '$name a été installé avec succès.';
  }

  @override
  String get installing => 'Installation en cours';

  @override
  String get keepMetadata => 'Garder les métadonnées';

  @override
  String get language => 'Langue';

  @override
  String get locate => 'Localiser';

  @override
  String get locateFfmpeg => 'Localiser ffmpeg';

  @override
  String get low => 'Faible';

  @override
  String get magickRequired =>
      'ImageMagick est requis pour compresser des images.';

  @override
  String get magickSuccess => 'Vous pouvez maintenant compresser vos images.';

  @override
  String get medium => 'Moyenne';

  @override
  String get minimumCompressionRequired =>
      'Efficacité de compression minimale requise :';

  @override
  String get newVersionAvailable => 'Une nouvelle version est disponible !';

  @override
  String get noAudioTrackFound =>
      'Aucune piste audio n\'a été trouvée dans le fichier pour la conversion MP3.';

  @override
  String get openExplorer => 'Ouvrir dans l\'explorateur';

  @override
  String get openFinder => 'Ouvrir dans Finder';

  @override
  String get outputDirectory => 'Dossier de sortie';

  @override
  String get pleaseWait => 'Veuillez patienter';

  @override
  String get processedFiles => 'fichiers traités';

  @override
  String get quality => 'Qualité';

  @override
  String get quit => 'Quitter';

  @override
  String get quitWarning =>
      'Un processus de compression/conversion est en cours, voulez-vous vraiment quitter ?';

  @override
  String get reportError => 'Signaler par mail';

  @override
  String get requiredModule => 'Module requis';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get restart => 'Redémarrer';

  @override
  String get restartNowQuestion =>
      'Souhaitez-vous redémarrer l\'application pour appliquer les modifications ?';

  @override
  String get restartRequired =>
      'Vous devez redémarrer l\'application pour que cette modification prenne effet.';

  @override
  String get retry => 'Réessayer';

  @override
  String get saved => 'économisés';

  @override
  String get seeErrors => 'Voir les erreurs';

  @override
  String get settings => 'Paramètres';

  @override
  String get size => 'Taille';

  @override
  String toInstall(String name) {
    return '• Pour installer $name, cliquez ';
  }

  @override
  String get tooltipGhostscript =>
      'GhostScript vous permet de compresser des fichiers PDF.';

  @override
  String get tooltipImageMagick =>
      'ImageMagick vous permet de compresser des images.';

  @override
  String get unsupportedFileFormat => 'Format non supporté.';

  @override
  String get videos => 'Vidéos';

  @override
  String get waiting => 'En attente';
}
