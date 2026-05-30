import 'dart:html' as html;

Future<void> downloadCsv(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'text/csv');
  final blobUrl = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: blobUrl)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(blobUrl);
}
