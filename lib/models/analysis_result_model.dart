class AnalysisResult {
  final String analysisStatus;
  final int maliciousStatus;
  final List<Map<String, String>> engines;

  AnalysisResult({
    required this.analysisStatus,
    required this.maliciousStatus,
    required this.engines,
  });
}
