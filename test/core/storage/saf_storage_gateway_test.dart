import 'package:echoes/core/storage/saf_storage_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tree =
      'content://com.android.externalstorage.documents/tree/'
      'primary%3ADownload%2FAudiobooks';

  test('URI de documento dentro da árvore vira URI de árvore', () {
    expect(treeUriOf('$tree/document/primary%3ADownload%2FAudiobooks'), tree);
  });

  test('URI de árvore fica igual', () {
    expect(treeUriOf(tree), tree);
  });

  test('URI de documento solto fica igual', () {
    const doc =
        'content://com.android.providers.media.documents/document/audio%3A12';
    expect(treeUriOf(doc), doc);
  });
}
