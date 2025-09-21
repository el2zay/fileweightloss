// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addFiles => 'or click to add files';

  @override
  String brewMessage(String bin, String name) {
    return 'Homebrew is already installed on your Mac, you can install $name by entering the command\n\nbrew install $bin\n\nin your terminal.\nWait for installation to complete, then click OK.';
  }

  @override
  String get browse => 'Browse';

  @override
  String get buyMeCoffee => 'Buy me a coffee';

  @override
  String get cancel => 'Cancel';

  @override
  String get changeCompressedName => 'Change compressed file name';

  @override
  String get checkUpdates => 'Check Updates';

  @override
  String get clickAdd => 'or click to add files';

  @override
  String get clickNew => 'Click here to compress new files';

  @override
  String get clickSelect => 'or click to select files';

  @override
  String get completed => 'Done';

  @override
  String get compress => 'Compress';

  @override
  String compressedMessage(int percent) {
    return 'In total, your files are $percent% smaller.';
  }

  @override
  String get compressing => 'Compressing...';

  @override
  String compressionError(String error) {
    return 'Error during compression - $error.';
  }

  @override
  String get compressionNotEffective =>
      'Compression not effective enough, keeping original file.';

  @override
  String get confirmQuit => 'Are you sure you want to quit?';

  @override
  String convertedMessage(String format) {
    return 'All your files have been converted to $format.';
  }

  @override
  String currentPath(String name) {
    return 'Current $name path';
  }

  @override
  String get custom => 'Custom';

  @override
  String get defaultOutputDirectory => 'Default output directory';

  @override
  String get deleteOriginals => 'Delete originals';

  @override
  String get dirPathError => 'The directory does not exist.';

  @override
  String doneMessage(String type) {
    return 'Your files have been successfully $type.';
  }

  @override
  String get download => 'Download';

  @override
  String get dropFiles => 'Drop your files here';

  @override
  String get dropNow => 'You can drop now!';

  @override
  String get emptyPath => 'Please enter a valid path.';

  @override
  String get endError => 'An error has occurred.';

  @override
  String get endErrorDescription0 => 'No files have been converted.';

  @override
  String get endErrorDescription1 => 'Some files could not be processed.';

  @override
  String get error => 'Error';

  @override
  String explanationMinCompression(int value) {
    return 'If compression is below $value%, the file will not be compressed.';
  }

  @override
  String get explore => 'Explore';

  @override
  String get feedback => 'Give me your feedback !';

  @override
  String get ffmpegRequired =>
      'A module (ffmpeg) is required to continue. Would you like to install it? An internet connection is required for installation.';

  @override
  String get ffmpegTooltip =>
      'FFmpeg lets you compress\nand convert audio and video files.';

  @override
  String get fileNotFoundAfterCompression =>
      'File not found after compression.';

  @override
  String get filePathError => 'The file does not exist.';

  @override
  String get filesReady => 'Your files are ready!';

  @override
  String get githubRepository => 'GitHub repository';

  @override
  String get giveFeedback => 'Give us your feedback';

  @override
  String get good => 'Good';

  @override
  String get gsRequired => 'GhostScript is required to compress PDFs.';

  @override
  String get gsSuccess => 'You can now compress your PDF files.';

  @override
  String get helpUsWithAttachments =>
      'To help us find the cause of this error more easily, please send us the problem files as attachments.';

  @override
  String get here => 'here';

  @override
  String get high => 'High';

  @override
  String get includeFiles => 'Include files (recommended)';

  @override
  String get includeFilesDescription =>
      'This can help us find the error more quickly.';

  @override
  String get install => 'Install';

  @override
  String get installGs0 => '• To install GhostScript, click ';

  @override
  String get installGs1MagickWindows =>
      'to download the installation file.\n\n• Execute the downloaded file, then follow the instructions given by the installer\n\n•  Once installation is complete, click on the \'OK\' button to continue.\n\n• Installation requires an Internet connection.';

  @override
  String get installMagickLinux =>
      'To download the AppImage file.\n\n• In the terminal, run the following commands:\n\nchmod +x <file>\nsudo mv <file> /usr/local/bin\n\n• The installation requires an Internet connection.';

  @override
  String get installMagickMacos =>
      'Unfortunately, we have not found a solution for installing ImageMagick on macOS without HomeBrew.\n\nTo install ImageMagick, you need to install HomeBrew by following the instructions on the official website https://brew.sh then install ImageMagick by typing the following command in a terminal.\n\nbrew install imagemagick\n\nOnce the installation is complete, click the \'OK\' button to continue.';

  @override
  String installationError(String name) {
    return 'An error occurred while checking $name.';
  }

  @override
  String get installationErrorGeneric =>
      'Sorry, but an error has occurred.\nPlease make sure you are connected to the Internet.';

  @override
  String get installationErrorMessage =>
      'Check that you have followed the instructions correctly.';

  @override
  String installationSuccess(String name) {
    return '$name has been successfully installed.';
  }

  @override
  String get installing => 'Installation in progress';

  @override
  String get keepMetadata => 'Keep metadata';

  @override
  String get language => 'Language';

  @override
  String get locate => 'Locate';

  @override
  String get locateFfmpeg => 'Locate ffmpeg';

  @override
  String get low => 'Low';

  @override
  String get magickRequired => 'ImageMagick is required to compress images.';

  @override
  String get magickSuccess => 'You can now compress your images.';

  @override
  String get medium => 'Medium';

  @override
  String get minimumCompressionRequired =>
      'Minimum compression efficiency required:';

  @override
  String get newVersionAvailable => 'A new version is available !';

  @override
  String get noAudioTrackFound =>
      'No audio track found in the file for MP3 conversion.';

  @override
  String get openExplorer => 'Open in Explorer';

  @override
  String get openFinder => 'Open in Finder';

  @override
  String get outputDirectory => 'Output directory';

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get processedFiles => 'files processed';

  @override
  String get quality => 'Quality';

  @override
  String get quit => 'Quit';

  @override
  String get quitWarning =>
      'A compression/conversion process is underway, do you really want to quit?';

  @override
  String get reportError => 'Report by mail';

  @override
  String get requiredModule => 'Module required';

  @override
  String get reset => 'Reset';

  @override
  String get restart => 'Restart';

  @override
  String get restartNowQuestion =>
      'Do you want to restart the application to apply the changes?';

  @override
  String get restartRequired =>
      'You must restart the application for this change to take effect.';

  @override
  String get retry => 'Retry';

  @override
  String get saved => 'economized';

  @override
  String get seeErrors => 'See the errors';

  @override
  String get settings => 'Settings';

  @override
  String get size => 'Size';

  @override
  String toInstall(String name) {
    return '• To install $name, click ';
  }

  @override
  String get tooltipGhostscript => 'GhostScript lets you compress PDF files.';

  @override
  String get tooltipImageMagick => 'ImageMagick lets you compress images.';

  @override
  String get unsupportedFileFormat => 'Unsupported file format.';

  @override
  String get videos => 'Videos';

  @override
  String get waiting => 'Waiting';
}
