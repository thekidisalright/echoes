import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/providers.dart';
import '../../../player/presentation/player_providers.dart';
import '../../domain/book.dart';
import '../library_providers.dart';
import 'book_cover.dart';

/// Abre "Editar audiobook" para [book].
Future<void> showBookEditDialog(BuildContext context, Book book) =>
    showDialog<void>(
      context: context,
      builder: (context) => BookEditDialog(book: book),
    );

/// Capa, título e autor editáveis; "Restaurar dados originais" quando o
/// livro tem edições.
class BookEditDialog extends ConsumerStatefulWidget {
  const BookEditDialog({required this.book, super.key});

  static const coverWidth = 112.0;
  static const coverHeight = 144.0;

  final Book book;

  @override
  ConsumerState<BookEditDialog> createState() => _BookEditDialogState();
}

class _BookEditDialogState extends ConsumerState<BookEditDialog> {
  late final _title = TextEditingController(text: widget.book.title);
  late final _author = TextEditingController(text: widget.book.author);

  /// Imagem escolhida e ainda não salva.
  String? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await ref.read(imageGatewayProvider).pickImage();
    if (path != null && mounted) setState(() => _pickedImage = path);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
      await ref.read(playbackControllerProvider).refreshBook(widget.book.id);
      if (mounted) Navigator.pop(context);
    } on Exception catch (e) {
      debugPrint('Falha ao editar o livro ${widget.book.id}: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.editBookError)));
    }
  }

  Future<void> _save() => _run(
    () => ref
        .read(bookEditorProvider)
        .save(
          widget.book.id,
          title: _title.text,
          author: _author.text,
          imagePath: _pickedImage,
        ),
  );

  Future<void> _restore() =>
      _run(() => ref.read(bookEditorProvider).reset(widget.book.id));

  @override
  Widget build(BuildContext context) {
    final canSave = !_saving && _title.text.trim().isNotEmpty;
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AppStrings.editBook, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _CoverPicker(
                path: _pickedImage ?? widget.book.coverPath,
                onTap: _saving ? null : _pickImage,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Field(label: AppStrings.titleLabel, controller: _title),
            const SizedBox(height: AppSpacing.md),
            _Field(label: AppStrings.authorLabel, controller: _author),
            if (widget.book.hasCustomDetails) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saving ? null : _restore,
                  icon: const Icon(
                    Ionicons.refreshOutline,
                    size: AppSpacing.actionIcon,
                  ),
                  label: const Text(AppStrings.restoreOriginal),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: canSave ? _save : null,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: AppSpacing.lg,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onAccent,
                          ),
                        )
                      : const Text(AppStrings.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Capa 112×144 com a faixa "Alterar capa".
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.changeCover,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: BookEditDialog.coverWidth,
          height: BookEditDialog.coverHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.cover),
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(
                  // Chave pelo caminho: a prévia troca assim que a imagem é
                  // escolhida.
                  key: ValueKey(path),
                  path: path,
                  placeholderIcon: Ionicons.bookOutline,
                  radius: AppRadii.cover,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.scrim,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      AppStrings.changeCover,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.body,
      cursorColor: AppColors.accent,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall,
        floatingLabelStyle: AppTypography.caption.copyWith(
          color: AppColors.accent,
        ),
      ),
    );
  }
}
