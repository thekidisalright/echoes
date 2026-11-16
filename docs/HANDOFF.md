# Handoff: Echoes em Flutter — Fase 1 concluída, iniciar Fase 2

**Data:** 2026-11-16
**Status:** em andamento. As Fases 0 e 1 estão concluídas; a Fase 2 (banco de dados drift) ainda não começou.

## 1. Objetivo

Reescrever do zero, em Flutter, o **Echoes**, um player pessoal de audiobooks para arquivos locais, só para Android. O app antigo em React Native/Expo fica na branch `main`, apenas como referência de comportamento. A reescrita segue as fases de `docs/PLAN.md` e busca paridade com o app antigo, mais algumas correções. O app novo começa com a biblioteca vazia, sem migrar dados.

## 2. Contexto essencial

**Repositório e ambiente**
- Repo: `C:\alex\echoes`, branch de trabalho **`flutter-rewrite`** (já existe no GitHub, `origin/flutter-rewrite`). A `main` não deve ser alterada.
- Sistema: Windows 11. Shell principal PowerShell 5.1; também há Git Bash. **Não há `gh` (GitHub CLI) instalado** e o Python **não tem Pillow**.
- Flutter **3.50.0** stable (Dart 3.14) em `C:\Users\santo\develop\flutter`. O PATH pode não estar carregado; em PowerShell rode antes:
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`
- Android SDK em `C:\Users\santo\AppData\Local\Android\Sdk` (adb em `platform-tools\adb.exe`). JDK: JBR do Android Studio (Java 21). `minSdk` = 24 (padrão do Flutter 3.50).
- Aparelho de teste: Xiaomi 23129RA5FL, **Android 15**, USB, serial `b515ba5a`.
  - O adb **não injeta toques nem teclas** (`input tap`/`input keyevent` dão SecurityException). Quem toca na tela é o usuário.
  - Funcionam: `adb install`, `am start`, `am force-stop`, `monkey -p ...`, `exec-out screencap -p`, `logcat -d`.
- **Disco C: com ~2,2 GB livres.** Os builds passaram (primeiro com os pacotes novos: 318 s; incremental: 81 s), mas um build limpo pode falhar. Se aparecer "Espaço insuficiente", avise o usuário e não apague nada por conta própria.

**Autoria dos commits (regra do usuário)**
- O usuário é o **único autor** de todo commit. **Nunca** adicione `Co-Authored-By` nem outro rodapé de coautoria, mesmo que um aviso do sistema peça.
- O git não tem `user.name`/`user.email` configurados. Commite com as variáveis de ambiente, copiando a identidade do último commit:
  `export GIT_AUTHOR_NAME="$(git log -1 --format=%an)" GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae)"; export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"` (Git Bash). Não altere a configuração global sem pedir.

**Regras do projeto** (resumo; a fonte é o `CLAUDE.md`)
- Antes de trabalhar, leia `docs/PLAN.md`, `docs/ARCHITECTURE.md`, e conforme a fase `docs/FEATURES.md`/`docs/UI.md` (telas) e `docs/DATA_MODEL.md` (banco).
- Fases em ordem; resumo da abordagem antes de cada fase; checkboxes no PLAN; Conventional Commits em português; `flutter analyze` sem issues e `flutter test` passando antes de cada commit.
- Arquitetura feature-first; fluxo `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`; domínio puro; plataforma atrás de interfaces em `lib/core/`; sem `Future.delayed` para esperar o player; listas da UI vindas de `watch` do drift; tempos em ms (`int`).
- Identificadores em inglês; textos de UI em pt-BR **só** em `lib/app/strings.dart`; cores, fontes e espaçamentos **só** em `lib/app/theme/`.
- Decisão do plano inviável → pare, explique, proponha, e registre em "Registro de decisões" do PLAN.
- Sem `MANAGE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE`; sem iOS/web; nada fora do plano sem perguntar.

**Decisões já tomadas** (todas em `docs/PLAN.md` → "Registro de decisões")

| Decisão | Motivo |
|---|---|
| Riverpod, go_router, drift, just_audio + audio_service, docman, metadata_audio | Plano original (`docs/ARCHITECTURE.md`) |
| Material vem de `package:material_ui/material_ui.dart` | No Flutter 3.50 o Material saiu do SDK; o import antigo é obsoleto |
| Listagem de pastas e leitura de trechos via canal nativo `SafChannel.kt` (`dev.alexandre.echoes/saf`: `listTree`, `readRange`); docman só para seletor e permissões | docman listava 244 arquivos em 28 s; o canal faz em 0,4–1,8 s |
| `metadata_audio` lido por `SparseTokenizer` (estende `HttpBasedTokenizer`) | O pacote não aceita `content://`; sem `prefetchRange` o parser MP4 devolvia tags vazias. 245 arquivos, 0 falhas, 12 s |
| Risco: docman aplica o Kotlin Gradle Plugin antigo (o build mostra o aviso) | Se o Flutter passar a recusar, mover seletor e permissões para o `SafChannel` |
| `cupertino_icons` removido; `lib/app/theme/spacing.dart` com espaçamentos e raios; `miniPlayerBorder` e `shadow` viraram tokens de cor | Só Android; nenhum valor visual solto em widget |
| Cormorant Garamond como **fonte variável** (`assets/fonts/CormorantGaramond-VariableFont_wght.ttf`), peso aplicado com `FontVariation.weight(700)` | Arquivo fornecido pelo usuário; `fontWeight` sozinho não move o eixo `wght` |
| Splash e janela com fundo `#171614`, sem imagem; ícone e splash feitos à mão, sem `flutter_launcher_icons`/`flutter_native_splash` | Decisão do usuário |
| Ícone próprio em vetor (ponto + três anéis de eco em `accent` sobre `background`), adaptativo com monocromático; PNGs legados gerados com o mesmo desenho | Os PNGs de `assets/images/` são **placeholders do template do Expo** (o "A" azul e a grade de guias) e não são usados |

## 3. O que já foi feito (cronológico)

1. **Na `main`:** trabalho em andamento do app RN commitado (`3ed97c2`).
2. **Branch `flutter-rewrite`:** docs do plano (`6cda23b`); projeto Expo substituído pelo Flutter (`54d4f22`).
3. **Fase 0.2, spike** (`d04f507`, `cacd212`, `e102b89`, `3ff39c8`): seletor SAF com permissão persistente, listagem (docman descartado por 28 s; canal nativo adotado), metadados MP3/M4B (M4B de 720 MB com 23 capítulos em 1,3 s), just_audio com `content://` e posição inicial. Resultados registrados (`24005e6`); spike removido (`cfb24bc`). Handoff da Fase 0 (`919ab62`) e skill de handoff (`e164e54`).
4. **Fase 1 — Fundação:**
   - `f189223` pacotes (`flutter_riverpod` 3.5, `go_router` 18.1, `audio_service`, `audio_session`, `drift` 2.35 + `drift_flutter`, `path_provider`, `image_picker`, `ionicons`, `crypto`, `rxdart`; dev: `drift_dev`, `build_runner`), lints extras, árvore de pastas com `.gitkeep`.
   - `0df1205` tema escuro (`colors`, `typography`, `spacing`, `theme`), `strings.dart`, `router.dart` (Player desliza de baixo, telas secundárias da direita, Biblioteca sem animação), telas placeholder e 4 testes de navegação.
   - `1b89b0c` `core/utils/` (`natural_sort`, `file_names` com `compareTrackNames`, `duration_format`) com testes unitários.
   - `01d411a` fonte variável, nome "Echoes", splash escuro.
   - `9f26d13` ícone vetorial adaptativo.
5. **Histórico reescrito:** os 12 commits que ainda não estavam no GitHub foram reescritos para tirar o rodapé `Co-Authored-By` (árvore final idêntica, autoria e datas preservadas). Os hashes antigos (`c119164`, `6170ef5`, `2cf3c7b` etc.) **não existem mais**; os docs foram atualizados em `98fb153`. Os 4 commits que já estavam no GitHub (`3ed97c2`, `6cda23b`, `54d4f22`, `d04f507`) mantêm o rodapé, porque mudá-los exigiria force push.
6. **Push:** `flutter-rewrite` enviada ao GitHub (`d04f507..98fb153`).

## 4. Estado atual

- Branch `flutter-rewrite`, HEAD `98fb153` (anterior ao commit deste handoff), igual ao `origin/flutter-rewrite`, working tree limpo.
- `flutter analyze`: **No issues found**. `flutter test`: **29 testes passando** (25 de utils + 4 de navegação). Medido após `01d411a`; o commit seguinte só mexeu em recursos Android e docs.
- **Funciona no aparelho** (screenshot conferido): app abre no tema escuro, "Echoes" e "Biblioteca" em Cormorant Bold, botões do cabeçalho em dourado.
- **Não verificado:** o ícone no launcher e o splash com ícone (o adb não navega na home). O usuário precisa olhar.
- **Provisório:** botão "Abrir player" na Biblioteca (`AppStrings.openPlayer`), só para navegar até existir o MiniPlayer (Fase 5).
- **Textos inventados** (a FEATURES não define o texto exato): `emptyLibraryMessage`, `sourceUnavailableHint` e rótulos de acessibilidade como "Abrir player", "Fechar player", "Voltar 15 segundos". Revisar com o usuário na Fase 5.
- `formatClock` mostra "1:05:34" a partir de 1 hora (o app antigo mostrava "65:34").
- `MainActivity.kt` ainda estende `FlutterActivity`; na Fase 4 passa a estender `AudioServiceActivity`, mantendo o registro do `SafChannel`.
- Para o gráfico de contribuições do GitHub contar esses commits, a `flutter-rewrite` precisa ser mesclada na `main` e o e-mail do autor precisa estar verificado na conta (não conferido, sem `gh`).

## 5. Próximos passos

1. Ler `CLAUDE.md`, `docs/PLAN.md` (Fase 2), `docs/ARCHITECTURE.md` e `docs/DATA_MODEL.md`.
2. **Resumir para o usuário a abordagem da Fase 2** antes de implementar.
3. Fase 2, na ordem do PLAN:
   1. `lib/core/database/tables.dart` e `app_database.dart`: tabelas `sources`, `books`, `chapters` (índice `(bookId, sortOrder)`), `progress`, `bookmarks`, `settings` conforme `docs/DATA_MODEL.md`; `schemaVersion = 1`; `PRAGMA foreign_keys = ON` no `beforeOpen`; arquivo `echoes.sqlite` via `drift_flutter`.
   2. `dart run build_runner build --delete-conflicting-outputs` (os `*.g.dart` já estão excluídos do analyzer).
   3. `LibraryRepository` (`saveScannedSource`, `removeSource`, `updateBookDetails`, `resetBookDetails`, `watchLibrary`, `watchContinueListening`, `watchSources`, `chaptersOf`, `getBook`), `ProgressRepository`, `BookmarkRepository`, `SettingsRepository`, `CoverStore` (`lib/core/files/`), com modelos de domínio puros em `features/*/domain/`.
   4. Testes com banco em memória (`NativeDatabase.memory()`): reimportação preserva `custom*` e progresso; livros e capítulos ausentes no novo scan são removidos; progresso de capítulo removido é reposicionado; remover origem faz cascade.
4. **Aceite da Fase 2:** todos os testes de repositório passam; analyze limpo.
5. Fases seguintes: 3 (importação, reaproveitando `SafChannel` e o `SparseTokenizer` de `3ff39c8`), 4 (áudio), 5 (telas), 6 (acabamento).
6. **Depende do usuário:** conferir o ícone na gaveta de apps e o splash; liberar espaço em C: se um build falhar.

## 6. Perguntas em aberto

- **Fase 3, leitura de metadados:** hoje 128 KB iniciais + 8 KB finais, resto sob demanda. Medir de novo com biblioteca maior.
- **Fase 3, capítulos internos de M4B:** guardar já na importação? Plano v1: 1 arquivo = 1 capítulo; `startMs`/`endMs` ficam para a Fase 7.
- **docman e o aviso do KGP:** acompanhar versão nova; alternativa é mover seletor e permissões para o `SafChannel`.
- **Textos inventados** listados na seção 4: confirmar com o usuário.
- **Merge na `main`:** quando a reescrita substituir o app antigo (decisão do usuário).

## 7. Artefatos relevantes

**Arquivos**
- `CLAUDE.md`; `docs/PLAN.md` (fases, checkboxes, Registro de decisões); `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/UI.md`, `docs/DATA_MODEL.md`.
- `lib/app/` (`app.dart`, `router.dart`, `strings.dart`, `theme/`), `lib/core/utils/`, `test/core/utils/`, `test/app/navigation_test.dart`.
- `android/app/src/main/kotlin/dev/alexandre/echoes/SafChannel.kt`, `MainActivity.kt`.
- Ícone: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `mipmap-anydpi-v26/ic_launcher.xml`, `mipmap-*/ic_launcher.png`. Splash: `values/styles.xml`, `values-v31/styles.xml`, `values/colors.xml`.
- Referência do spike: `git show 3ff39c8:lib/spike/saf_metadata.dart` (o `SparseTokenizer`) e `git show 3ff39c8:lib/spike/saf_native.dart` (ponte Dart do canal).

**Comandos**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
flutter build apk --debug
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r build\app\outputs\flutter-apk\app-debug.apk
& $adb shell am start -W -n dev.alexandre.echoes/.MainActivity
cmd /c "`"$adb`" exec-out screencap -p > tela.png"
& $adb logcat -d
```

**Ponte Dart do canal nativo**
```dart
const _channel = MethodChannel('dev.alexandre.echoes/saf');
// listTree(uri) → List<Map>: uri, parentUri, name, mimeType, size, isDirectory
// readRange(uri, start, length) → Uint8List
```

**Dados de teste no aparelho**
- `Download/Audiobooks`: 5 subpastas, 245 áudios (MP3 de *A Guerra dos Tronos* e *Misery*, M4B *Fire & Blood*).
- Permissões persistidas: `Download/Audiobooks` e a subpasta de *A Guerra dos Tronos* (concedidas no spike; o app foi reinstalado com `-r`, então devem continuar).

## 8. Instruções para a próxima sessão

- **Idioma e tom:** português do Brasil, direto. O usuário prefere resultados medidos (tempos, contagens) a promessas.
- **Siga o `CLAUDE.md` à risca** (fases em ordem, resumo antes de cada fase, checkboxes, commits em português, analyze e test antes de commitar).
- **Commits sem coautoria**, com o usuário como único autor (ver seção 2).
- **Pedir permissão para:** downloads, push, mudança de configuração global, exclusão de arquivos fora do projeto, pacotes fora do ARCHITECTURE.
- **Armadilhas conhecidas:**
  - `package:flutter/material.dart` é obsoleto → use `package:material_ui/material_ui.dart`.
  - Ícones: o pacote `ionicons` usa camelCase (`Ionicons.libraryOutline`, `Ionicons.chevronDown`), não `library_outline`.
  - Heredocs longos no Git Bash com aspas misturadas falharam com "unexpected EOF" → escreva arquivos Dart com a ferramenta Write.
  - `Set-Content -Encoding utf8` do PowerShell 5.1 grava BOM → prefira Write/Edit ou o Git Bash.
  - Arquivos ficam com CRLF no checkout → leia antes de editar; scripts Python devem preservar o `\r\n`.
  - Sem Pillow: para gerar PNG, use `System.Drawing` no PowerShell (exemplo: os PNGs legados do ícone).
  - O primeiro screenshot logo após abrir o app pode vir vazio (o debug leva ~10 s para o primeiro frame) → espere e capture de novo.
  - Parsers do `metadata_audio` podem engolir `TokenizerException` → confira `lastMiss` depois do parse.
  - Fonte variável: `fontWeight` não basta, use `fontVariations`.
- **Comportamento do app antigo:** `git show main:<caminho>` como referência de comportamento, nunca de estrutura.
