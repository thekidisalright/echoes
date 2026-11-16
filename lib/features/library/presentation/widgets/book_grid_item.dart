import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/duration_format.dart';
import '../../domain/book_summary.dart';
import 'book_cover.dart';

/// Item da grade: capa 3:4, título, autor e detalhe.
class BookGridItem extends StatefulWidget {
  /// Densidade máxima da capa na grade (2× basta para miniaturas).
  static const coverPixelRatio = 2.0;

  const BookGridItem({
    required this.summary,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final BookSummary summary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Proporção do item inteiro (capa 3:4 + três linhas de texto), usada
  /// pela grade para calcular a altura.
  static double aspectRatioFor(double itemWidth) {
    const textHeight = 66.0;
    return itemWidth / (itemWidth * 4 / 3 + textHeight);
  }

  @override
  State<BookGridItem> createState() => _BookGridItemState();
}

class _BookGridItemState extends State<BookGridItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.summary.book;
    final title = book.title.isEmpty ? AppStrings.untitled : book.title;
    final author = book.author.isEmpty ? AppStrings.unknownAuthor : book.author;
    final total = book.totalDuration;
    final detail = !widget.summary.sourceAvailable
        ? AppStrings.sourceUnavailable
        : [
            AppStrings.chapterCount(book.chapterCount),
            if (total != null && total > Duration.zero)
              formatBookDuration(total),
          ].join(' · ');

    return Semantics(
      button: true,
      label: AppStrings.listenTo(title),
      onLongPressHint: AppStrings.editBook,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.75 : 1,
          duration: const Duration(milliseconds: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: BookCover(
                  path: book.coverPath,
                  placeholderIcon: Ionicons.bookOutline,
                  radius: AppRadii.cover,
                  maxPixelRatio: BookGridItem.coverPixelRatio,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                author,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                detail,
                style: AppTypography.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
