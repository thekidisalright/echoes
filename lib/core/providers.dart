import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'files/cover_store.dart';
import 'images/image_gateway.dart';
import 'images/image_picker_gateway.dart';
import 'metadata/metadata_audio_reader.dart';
import 'metadata/metadata_reader.dart';
import 'storage/saf_storage_gateway.dart';
import 'storage/storage_gateway.dart';

/// Infraestrutura compartilhada. Nos testes, substitua com `overrideWith`.

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final storageGatewayProvider = Provider<StorageGateway>(
  (ref) => SafStorageGateway(),
);

final metadataReaderProvider = Provider<MetadataReader>(
  (ref) => MetadataAudioReader(ref.watch(storageGatewayProvider)),
);

final coverStoreProvider = Provider<CoverStore>(
  (ref) => CoverStore.appSupport(),
);

final imageGatewayProvider = Provider<ImageGateway>(
  (ref) => ImagePickerGateway(),
);
