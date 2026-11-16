import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/domain/sort_order.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// Ordem da biblioteca salva nas configurações.
final librarySortProvider = StreamProvider<SortOrder>(
  (ref) => ref.watch(settingsRepositoryProvider).watchLibrarySort(),
);
