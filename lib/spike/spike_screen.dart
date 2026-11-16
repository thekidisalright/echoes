// SPIKE — código descartável (Fase 0). Será removido no fim da fase.
import 'dart:async';
import 'dart:typed_data';

import 'package:docman/docman.dart';
import 'package:material_ui/material_ui.dart';
import 'package:just_audio/just_audio.dart';

import 'saf_metadata.dart';
import 'saf_native.dart';

const _audioExt = {'mp3', 'm4a', 'm4b'};
const _imageExt = {'jpg', 'jpeg', 'png', 'webp'};

String _ext(String name) {
  final i = name.lastIndexOf('.');
  return i < 0 ? '' : name.substring(i + 1).toLowerCase();
}

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _player = AudioPlayer();
  final _log = <String>[];
  List<PersistedPermission> _perms = [];
  List<SafNode> _audios = [];
  List<SafNode> _images = [];
  final List<(String, Uint8List)> _covers = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPerms());
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  void _add(String line) => setState(() => _log.insert(0, line));

  Future<void> _run(String label, Future<void> Function() task) async {
    setState(() => _busy = true);
    final sw = Stopwatch()..start();
    try {
      await task();
      _add('✔ $label (${sw.elapsedMilliseconds} ms)');
    } catch (e) {
      _add('✘ $label: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadPerms() => _run('Permissões persistidas', _refreshPerms);

  Future<void> _refreshPerms() async {
    final perms = await DocMan.perms.list(files: false);
    setState(() => _perms = perms);
    for (final p in perms) {
      _add('perm: ${p.uri} read=${p.read}');
    }
    if (perms.isEmpty) _add('Nenhuma permissão persistida');
  }

  Future<void> _pickDir() => _run('Escolher pasta', () async {
    final dir = await DocMan.pick.directory();
    if (dir == null) {
      _add('Seleção cancelada');
      return;
    }
    _add('Pasta: ${dir.name} → ${dir.uri}');
    await _refreshPerms();
    await _scan(dir.uri);
  });

  Future<void> _scanUri(String uri) =>
      _run('Abrir pasta salva', () => _scan(uri));

  Future<void> _scan(String treeUri) async {
    final sw = Stopwatch()..start();
    final nodes = await listTree(treeUri);
    final dirs = nodes.where((n) => n.isDirectory).length + 1;
    final audios = nodes
        .where((n) => !n.isDirectory && _audioExt.contains(_ext(n.name)))
        .toList();
    final images = nodes
        .where((n) => !n.isDirectory && _imageExt.contains(_ext(n.name)))
        .toList();
    setState(() {
      _audios = audios;
      _images = images;
    });
    _add(
      'Listagem nativa: $dirs pastas, ${audios.length} áudios, '
      '${images.length} imagens em ${sw.elapsedMilliseconds} ms',
    );
  }

  Future<void> _readAll() => _run('Metadados de todos os áudios', () async {
    var ok = 0;
    var failed = 0;
    var bytes = 0;
    var withDuration = 0;
    for (final a in _audios) {
      try {
        final r = await readSafMetadata(a);
        ok++;
        bytes += r.bytesRead;
        if (r.metadata.format.duration != null) withDuration++;
      } catch (_) {
        failed++;
      }
    }
    _add(
      '  $ok ok, $failed falhas, $withDuration com duração, '
      '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB lidos',
    );
  });

  Future<void> _readMetadata(SafNode file) => _run(
    'Metadados de ${file.name}',
    () async {
      final r = await readSafMetadata(file);
      final c = r.metadata.common;
      final f = r.metadata.format;
      _add(
        '  título=${c.title} | álbum=${c.album} | artista=${c.artist} '
        '| albumartist=${c.albumartist} | faixa=${c.track.no} '
        '| duração=${f.duration?.toStringAsFixed(1)} s '
        '| capítulos=${f.chapters?.length} '
        '| capa=${c.picture?.isNotEmpty ?? false} '
        '| tentativas=${r.attempts} '
        '| lidos=${(r.bytesRead / 1024).round()} KB de '
        '${(file.size / 1024).round()} KB',
      );
      final pic = c.picture?.firstOrNull;
      if (pic != null) {
        setState(() => _covers.add((file.name, Uint8List.fromList(pic.data))));
      }
    },
  );

  Future<void> _readFirstOf(Set<String> exts) async {
    final file = _audios.where((a) => exts.contains(_ext(a.name))).firstOrNull;
    if (file == null) {
      _add('Nenhum arquivo ${exts.join('/')} na pasta');
      return;
    }
    await _readMetadata(file);
  }

  Future<void> _playFirst() => _run('Tocar a partir de 1:00', () async {
    // O maior arquivo, para garantir que 1:00 cabe na duração.
    if (_audios.isEmpty) throw StateError('Nenhum áudio listado');
    final file = _audios.reduce((a, b) => a.size >= b.size ? a : b);
    final duration = await _player.setAudioSource(
      AudioSource.uri(Uri.parse(file.uri)),
      initialPosition: const Duration(minutes: 1),
    );
    _add('Carregado ${file.name}, duração do player: $duration');
    unawaited(_player.play());
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spike Fase 0')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _busy ? null : _pickDir,
                child: const Text('1. Escolher pasta'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _readFirstOf({'mp3'}),
                child: const Text('3a. Metadados MP3'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _readFirstOf({'m4b', 'm4a'}),
                child: const Text('3b. Metadados M4B'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _readAll,
                child: const Text('3c. Metadados de todos'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _playFirst,
                child: const Text('4. Tocar em 1:00'),
              ),
              OutlinedButton(
                onPressed: _player.pause,
                child: const Text('Pausar'),
              ),
            ],
          ),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snap) =>
                Text('Posição: ${snap.data ?? Duration.zero}'),
          ),
          const Divider(),
          Text('Pastas persistidas (${_perms.length}) — toque para listar:'),
          for (final p in _perms)
            ListTile(
              dense: true,
              title: Text(p.uri, maxLines: 2),
              onTap: _busy ? null : () => _scanUri(p.uri),
            ),
          Text('Áudios: ${_audios.length} · Imagens: ${_images.length}'),
          for (final a in _audios.take(30))
            ListTile(
              dense: true,
              title: Text(a.name),
              subtitle: Text('${(a.size / 1024 / 1024).toStringAsFixed(1)} MB'),
              onTap: _busy ? null : () => _readMetadata(a),
            ),
          for (final (name, bytes) in _covers)
            ListTile(
              leading: Image.memory(bytes, width: 56, height: 56),
              title: Text('Capa de $name'),
            ),
          const Divider(),
          for (final line in _log)
            Text(line, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
