class AttachmentModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String uploadedBy;
  final DateTime uploadedAt;

  AttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id']?.toString() ?? '',
      fileName: json['original_filename'] ?? 'Fichier',
      fileUrl: json['file'],
      fileSize: json['file_size'] ?? 0,
      uploadedBy: json['uploaded_by_details']?['full_name'] ?? 'Inconnu',
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  String get sizeReadable {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
