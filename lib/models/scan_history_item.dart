class ScanHistoryItem {
  final String scanId;
  final String className;
  final String infoFileUri;
  final List<String> imagePaths;
  final String? localImagePath;
  final String processingStatus;

  ScanHistoryItem({
    required this.scanId,
    required this.className,
    required this.infoFileUri,
    required this.imagePaths,
    this.localImagePath,
    required this.processingStatus,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      scanId: json['scanId'] ?? '',
      className: json['class'] ?? 'Không xác định',
      infoFileUri: json['infoFileUri'] ?? '',
      imagePaths: json['imagePaths'] is List
          ? List<String>.from(json['imagePaths'])
          : [json['imagePaths'] ?? ''],
      localImagePath: json['localImagePath']?.toString(),
      processingStatus: json['processingStatus'] ?? 'pending',
    );
  }
}
