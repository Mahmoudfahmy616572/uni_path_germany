import 'package:logger/logger.dart' as pkg;

final log = pkg.Logger(
  printer: pkg.PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 3,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);
