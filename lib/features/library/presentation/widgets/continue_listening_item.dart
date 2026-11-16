import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/book_summary.dart';
import 'book_cover.dart';

/// Linha de "Continue ouvindo": capa, título, autor, progresso do livro e
/// ícone de status.
class ContinueListeningItem extends StatelessWidget {
  const ContinueListeningItem({
    required this.summary,
    required this.playing,
    required this.onTap,
    super.key,
  });

  static const height = 80.0;
  static const coverSize = 64.0;

  final BookSummary summary;

  /// É o livro tocando agora.
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final book = summary.book;
    final title = book.title.isEmpty ? AppStrings.untitled : book.title;
    return Semantics(
      button: true,
      label:
          '${AppStrings.listenTo(title)}, '
          '${playing ? AppStrings.nowPlaying : AppStrings.recentlyPlayed}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: coverSize,
                child: BookCover(
                  path: book.coverPath,
                  placeholderIcon: Ionicons.imageOutline,
                  iconSize: AppSpacing.xl,
                  radius: AppRadii.coverSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      book.author.isEmpty
                          ? AppStrings.unknownAuthor
                          : book.author,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                      child: LinearProgressIndicator(
                        value: summary.fractionListened,
                        minHeight: AppSpacing.progressBar,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: AppSpacing.minTouch + AppSpacing.md,
                child: Icon(
                  playing ? Ionicons.statsChart : Ionicons.time,
                  size: AppSpacing.statusIcon,
                  color: playing ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
