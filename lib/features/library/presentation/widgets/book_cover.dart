import 'dart:io';
import 'dart:math' as math;

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
    this.maxPixelRatio,
    super.key,
  });

  final String? path;
  final IconData placeholderIcon;
  final double iconSize;
  final double radius;
  final Color background;
  final Color iconColor;

  /// Teto da densidade usada para decodificar. Nas listas, capas menores
  /// cabem todas no cache de imagens e não são decodificadas de novo ao rolar.
  final double? maxPixelRatio;

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
                  final device = MediaQuery.devicePixelRatioOf(context);
                  final cap = maxPixelRatio;
                  final ratio = cap == null ? device : math.min(device, cap);
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
