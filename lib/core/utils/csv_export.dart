import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

Future<void> exportCsv({
  required List<Map<String, dynamic>> data,
  required String filename,
  required List<String> columns,
}) async {
  if (data.isEmpty) return;
  final header = columns.map((c) => _escapeCsv(c)).join(',');
  final rows = data.map((row) {
    return columns.map((col) => _escapeCsv(row[col]?.toString() ?? '')).join(',');
  }).join('\n');
  final csv = '$header\n$rows';

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename.csv');
  await file.writeAsString(csv);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: filename));
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
