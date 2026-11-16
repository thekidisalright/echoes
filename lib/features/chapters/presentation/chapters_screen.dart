import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/typography.dart';

/// Capítulos e marcadores do livro atual. Placeholder da Fase 1.
class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          icon: const Icon(Ionicons.arrowBack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.chaptersAndBookmarks,
          style: AppTypography.sectionTitle,
        ),
      ),
    );
  }
}
