import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/colors.dart';

/// Capa de livro a partir do arquivo em disco, com ícone quando não há capa
/// ou o arquivo não abre.
///
/// A imagem é decodificada na largura exibida (`cacheWidth`), para a grade
/// não guardar capas em resolução cheia na memória.
class BookCover extends StatelessWidget {
  const BookCover({
    required this.path,
    required this.placeholderIcon,
    required this.radius,
    this.iconSize = 48,
    this.background = AppColors.surfaceAlt,
    this.iconColor = AppColors.textMuted,
    super.key,
  });

  final String? path;
  final IconData placeholderIcon;
  final double iconSize;
  final double radius;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final placeholder = Center(
      child: Icon(placeholderIcon, size: iconSize, color: iconColor),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: background,
        child: path == null
            ? placeholder
            : LayoutBuilder(
                builder: (context, constraints) {
                  final ratio = MediaQuery.devicePixelRatioOf(context);
                  final width = constraints.maxWidth.isFinite
                      ? (constraints.maxWidth * ratio).round()
                      : null;
                  return Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    cacheWidth: width,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => placeholder,
                  );
                },
              ),
      ),
    );
  }
}
