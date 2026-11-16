/// Audiobook da biblioteca.
///
/// Os campos `scanned*` vêm da importação e são sobrescritos a cada
/// reimportação; os `custom*` são edições do usuário e nunca são sobrescritos.
/// O valor exibido é `custom ?? scanned`.
class Book {
  const Book({
    required this.id,
    required this.sourceId,
    required this.scannedTitle,
    required this.scannedAuthor,
    required this.chapterCount,
    required this.createdAt,
    this.scannedCoverPath,
    this.customTitle,
    this.customAuthor,
    this.customCoverPath,
    this.totalDuration,
    this.lastPlayedAt,
  });

  final String id;
  final String sourceId;
  final String scannedTitle;
  final String scannedAuthor;
  final String? scannedCoverPath;
  final String? customTitle;
  final String? customAuthor;
  final String? customCoverPath;
  final Duration? totalDuration;
  final int chapterCount;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;

  String get title => customTitle ?? scannedTitle;
  String get author => customAuthor ?? scannedAuthor;
  String? get coverPath => customCoverPath ?? scannedCoverPath;

  bool get hasCustomDetails =>
      customTitle != null || customAuthor != null || customCoverPath != null;
}
