# Handoff: Echoes em Flutter — Fase 0 concluída, iniciar Fase 1

**Data:** 2026-11-16
**Status:** em andamento. A Fase 0 está concluída e a Fase 1 (Fundação) ainda não começou.

---

## 1. Objetivo

Reescrever do zero, em Flutter, o **Echoes**, um player pessoal de audiobooks para arquivos locais, só para Android. O app antigo em React Native/Expo fica na branch `main`, apenas como referência de comportamento. A reescrita segue um plano por fases em `docs/PLAN.md` e busca paridade de funcionalidades com o app antigo, mais algumas correções. O app novo começa com a biblioteca vazia, sem migrar dados.

## 2. Contexto essencial

**Repositório e ambiente**
- Repo: `C:\alex\echoes`, branch de trabalho **`flutter-rewrite`**. A `main` não deve ser alterada.
- Sistema: Windows 11. O shell principal é o PowerShell 5.1 e também há Git Bash.
- Flutter **3.50.0** stable (Dart 3.14) em `C:\Users\santo\develop\flutter`.
  - O PATH pode não estar carregado no shell. Em PowerShell, rode antes:
    `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`
- Android SDK em `C:\Users\santo\AppData\Local\Android\Sdk`. O adb fica em `...\Sdk\platform-tools\adb.exe`.
- JDK: o JBR do Android Studio (Java 21).
- Aparelho de teste: Xiaomi 23129RA5FL, **Android 15**, conectado por USB (serial `b515ba5a`).
  - **O adb não consegue injetar toques** (`input tap` dá SecurityException). Quem toca na tela é o usuário.
  - Dá para ler a tela com `adb exec-out screencap -p` e o log com `adb logcat`.
- O git não tem `user.name`/`user.email` configurados. Os commits foram feitos com as variáveis de ambiente `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL`/`GIT_COMMITTER_*`, usando a identidade "Alexandre Silva" e o e-mail dos commits anteriores (veja `git log -1 --format='%an <%ae>'`). Não altere a configuração global sem pedir.
- O disco C: já ficou **sem espaço** durante um build. O usuário liberou cerca de 12 GB. Se o build falhar com "Espaço insuficiente", avise o usuário e não apague nada por conta própria.

**Regras do projeto** (resumo; a fonte é o `CLAUDE.md`, leia antes)
- Antes de trabalhar, leia nesta ordem: `docs/PLAN.md`, `docs/ARCHITECTURE.md`, `docs/FEATURES.md`/`docs/UI.md` (para telas) e `docs/DATA_MODEL.md` (para banco).
- Siga as fases do PLAN **em ordem**. Antes de cada fase, resuma a abordagem em poucas linhas.
- Marque os checkboxes no PLAN. Faça um commit por tarefa ou grupo, com mensagem em Conventional Commits **em português**.
- Rode `flutter analyze` (sem issues) e `flutter test` antes de cada commit.
- Arquitetura feature-first:
  - fluxo `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`;
  - domínio puro;
  - serviços de plataforma atrás de interfaces em `lib/core/`;
  - nada de `Future.delayed` para esperar o player;
  - listas da UI vindas de streams do drift;
  - tempos sempre em ms (`int`).
- Identificadores em inglês e textos de UI em pt-BR, centralizados em `lib/app/strings.dart`. Cores só via `lib/app/theme/`.
- Se uma decisão do plano se mostrar inviável: **pare, explique e proponha**, e depois registre em "Registro de decisões" no PLAN.
- Não pedir `MANAGE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE`, não suportar iOS/web e não adicionar funcionalidades fora do plano.

**Decisões já tomadas** (todas registradas em `docs/PLAN.md` → "Registro de decisões")

| Decisão | Motivo |
|---|---|
| Riverpod, go_router, drift, just_audio + audio_service, docman, metadata_audio (o plano original) | Ver `docs/ARCHITECTURE.md` |
| **Material vem de `package:material_ui/material_ui.dart`**, não de `package:flutter/material.dart` | No Flutter 3.50 o Material saiu do SDK e o import antigo gera aviso de obsoleto. O template já usa `material_ui` |
| **Listagem de pastas e leitura de trechos via canal nativo próprio** `SafChannel.kt` (canal `dev.alexandre.echoes/saf`, métodos `listTree` e `readRange`). O docman fica **só** para o seletor e as permissões persistidas | O `listDocuments` do docman fazia cerca de 8 consultas por arquivo: 244 arquivos em 28 s. O canal faz 1 consulta por pasta: 0,4–1,8 s. O `readAsBytes` do docman usa `skip` e não para de ler ao cancelar |
| **metadata_audio lido por um `SparseTokenizer`** que estende `HttpBasedTokenizer` | O pacote não aceita `content://` e o `Tokenizer` dele é síncrono. Estender `HttpBasedTokenizer` faz o parser MP4 chamar `prefetchRange` para o `moov` inteiro. Sem isso, ele engolia a falta de bytes e devolvia tags vazias |
| Risco anotado: o docman aplica o Kotlin Gradle Plugin no formato antigo, e o Flutter avisa que versões futuras vão recusar o build | Se quebrar, mover o seletor e as permissões para o `SafChannel` |
| As alterações não commitadas do app RN foram commitadas na `main` (`3ed97c2`) antes de criar a branch | Manter a `main` como referência completa |

## 3. O que já foi feito (cronológico)

1. **Na `main`:** commitado o trabalho em andamento do app RN (`3ed97c2`).
2. **Branch `flutter-rewrite`:** criada com os docs (`6cda23b`).
3. **Fase 0.1:**
   - removido todo o projeto Expo. Foram mantidos README, CLAUDE.md, docs/ e os ícones `assets/images/icon.png`, `android-icon-*.png` e `splash-icon.png`;
   - rodado `flutter create --org dev.alexandre --project-name echoes --platforms android .`;
   - `.gitignore` trocado pelo padrão do Flutter (`54d4f22`).
4. **Fase 0.2, spike em `lib/spike/`** (`d04f507` até `3ff39c8`). O que foi testado no aparelho:
   - **Seletor de pasta com permissão persistente:** OK. As permissões sobrevivem à morte do processo e à reinstalação com `-r`.
   - **Listagem recursiva:** primeiro com o docman (28 s, **descartado** por lentidão), depois com o canal nativo (OK).
   - **Metadados de MP3:** OK. Um MP3 deu tags `null`, mas foi confirmado por `adb` que o arquivo não tem ID3v2 e o ID3v1 está vazio.
   - **Metadados de M4B:** a primeira tentativa (512 KB iniciais + 256 KB finais fixos) devolveu tags vazias, porque o `moov` tem 8 MB e o parser engolia o erro. Foi **corrigido** com `HttpBasedTokenizer` + `prefetchRange` + nova tentativa quando há `lastMiss`.
     - Resultado: *Fire & Blood*, 720 MB, com título, autor, capa, 23 capítulos e duração de 95.087,5 s, em 1,3 s lendo 8 MB.
     - Biblioteca toda: 245 arquivos, 0 falhas, 40 MB lidos, 12 s.
   - **just_audio com `content://` e `initialPosition` de 1:00:** OK. A duração do player bate com a dos metadados.
5. **Resultados registrados** no PLAN e no ARCHITECTURE (`24005e6`).
6. **Fase 0 fechada:** `lib/spike/` removido e `main.dart` reduzido a um placeholder (`cfb24bc`).
   - O **código de referência do leitor de metadados** está no commit `3ff39c8`, em `lib/spike/saf_metadata.dart` e `lib/spike/saf_native.dart`. Use `git show 3ff39c8:lib/spike/saf_metadata.dart` para reaproveitar na Fase 3.

## 4. Estado atual

- Branch `flutter-rewrite`, HEAD `cfb24bc`, working tree limpo.
- `flutter analyze` sem issues e `flutter test` passando (só um teste placeholder em `test/widget_test.dart`).
- `lib/main.dart` é um `MaterialApp` mínimo que mostra "Echoes".
- **Já existem no projeto:**
  - `android/app/src/main/kotlin/dev/alexandre/echoes/SafChannel.kt`, um código definitivo que será usado na Fase 3;
  - `MainActivity.kt`, que registra o canal. Hoje ela estende `FlutterActivity`; na Fase 4 deve passar a estender `AudioServiceActivity`, mantendo o registro do canal.
- Dependências já no pubspec: `material_ui`, `cupertino_icons`, `docman`, `metadata_audio`, `just_audio` (que traz `audio_session` e `rxdart` como transitivas).
- Nada está quebrado. A Fase 1 não começou.

## 5. Próximos passos

1. Ler `CLAUDE.md` e `docs/PLAN.md` (Fase 1), e depois `docs/ARCHITECTURE.md` e `docs/UI.md`.
2. **Resumir para o usuário a abordagem da Fase 1** antes de implementar, como o `CLAUDE.md` exige.
3. Fase 1, na ordem do PLAN:
   1. **Pacotes definitivos** com `flutter pub add`: `flutter_riverpod`, `go_router`, `audio_service`, `audio_session`, `drift`, `drift_flutter`, `path_provider`, `image_picker`, `ionicons`, `crypto` e `rxdart`, mais `drift_dev` e `build_runner` como dev.
      - Remover `cupertino_icons` (só Android).
      - Se algum pacote novo não estiver no ARCHITECTURE, atualizar o documento.
   2. **`analysis_options.yaml`** com `flutter_lints` e as regras extras listadas no PLAN.
   3. **Estrutura de pastas** de `docs/ARCHITECTURE.md`, com `.gitkeep`.
   4. **Fontes Cormorant Garamond** 400/500/700 em `assets/fonts/`, registradas no pubspec.
      - É preciso obter os `.ttf`. A fonte tem licença OFL e está no Google Fonts/GitHub. **Download exige permissão do usuário**: peça antes ou peça que ele coloque os arquivos na pasta.
   5. **`lib/app/theme/`** (`colors.dart`, `typography.dart`, `theme.dart`) com os tokens de `docs/UI.md`.
   6. **`lib/app/strings.dart`** com todos os textos de `docs/FEATURES.md`.
   7. **`lib/app/router.dart`** com as rotas `/`, `/player` (modal de baixo), `/chapters`, `/manage` e `/settings`, todas com telas placeholder.
   8. **`lib/core/utils/`:** `natural_sort`, `file_names` (`cleanTitle`, `parseTrackNumber`, `isAudio`, `isImage`, `isPreferredCover`) e `duration_format`, **com testes unitários** cobrindo os exemplos de FEATURES §1.3.
      - Regex do número de faixa: `^\s*(track\s*)?(\d{1,3})[\s._-]|$`.
      - Para lembrar o comportamento antigo: `git show main:contexts/LibraryContext.tsx` e `git show main:src/storage.ts`.
   9. **Ícone e splash** a partir de `assets/images/`, com nome "Echoes".
      - Pode exigir `flutter_launcher_icons`/`flutter_native_splash`. São pacotes fora da lista do ARCHITECTURE: perguntar antes ou fazer na mão em `android/app/src/main/res`.
4. Aceite da Fase 1: o app abre no tema escuro com "Echoes" em Cormorant, a navegação entre placeholders funciona, o analyze está limpo e os testes de utils passam.
   - Instalar no aparelho: `flutter build apk --debug` e depois `adb install -r build\app\outputs\flutter-apk\app-debug.apk`. A primeira compilação leva cerca de 7 min.
5. Fases seguintes: 2 (banco drift), 3 (importação, reaproveitando o `SafChannel` e o `SparseTokenizer` do commit `3ff39c8`), 4 (áudio), 5 (telas), 6 (acabamento).

## 6. Perguntas em aberto

- **Fontes Cormorant:** baixar (com permissão) ou o usuário fornece os `.ttf`?
- **Ícone e splash:** usar `flutter_launcher_icons`/`flutter_native_splash` (pacotes fora do plano, perguntar) ou gerar os recursos à mão?
- **Fase 3, otimização da leitura de metadados:** hoje busca 128 KB iniciais + 8 KB finais e o resto sob demanda. Funciona bem. Vale medir de novo com uma biblioteca maior.
- **Fase 3:** guardar os capítulos internos do M4B já na importação? As colunas `startMs`/`endMs` existem, mas o uso é da Fase 7. Na v1, seguir o plano: 1 arquivo = 1 capítulo.
- **docman e o aviso do Kotlin Gradle Plugin:** acompanhar se sai uma versão nova. Alternativa: mover o seletor e as permissões para o `SafChannel`.
- **Este `HANDOFF.md`:** está commitado em `docs/`. Atualize-o ao fim de cada sessão longa.

## 7. Artefatos relevantes

**Arquivos**
- `CLAUDE.md`: regras do projeto.
- `docs/PLAN.md`: fases, checkboxes e Registro de decisões.
- `docs/ARCHITECTURE.md`, `docs/FEATURES.md`, `docs/UI.md`, `docs/DATA_MODEL.md`.
- `android/app/src/main/kotlin/dev/alexandre/echoes/SafChannel.kt`, `MainActivity.kt`.
- Referência do spike: `git show 3ff39c8:lib/spike/saf_metadata.dart` (o `SparseTokenizer`) e `git show 3ff39c8:lib/spike/saf_native.dart` (a ponte Dart do canal).

**Comandos**
```powershell
# PATH do Flutter no PowerShell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
flutter analyze
flutter test
flutter build apk --debug
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell monkey -p dev.alexandre.echoes -c android.intent.category.LAUNCHER 1
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" exec-out screencap -p > tela.png
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" logcat -d
```

**Ponte Dart do canal nativo** (resumo do spike)
```dart
const _channel = MethodChannel('dev.alexandre.echoes/saf');
// listTree(uri) → List<Map>: uri, parentUri, name, mimeType, size, isDirectory
// readRange(uri, start, length) → Uint8List
```

**Dados de teste no aparelho**
- A pasta `Download/Audiobooks` tem 5 subpastas e 245 áudios: MP3 de *A Guerra dos Tronos* e *Misery*, e o M4B *Fire & Blood*.
- As permissões persistidas já concedidas são `Download/Audiobooks` e a subpasta de *A Guerra dos Tronos*.

## 8. Instruções para a próxima sessão

- **Idioma e tom:** responder em português do Brasil, direto e objetivo. O usuário prefere ver resultados medidos (tempos, contagens), não promessas.
- **Siga o `CLAUDE.md` à risca:**
  - fases em ordem;
  - resumo da abordagem antes de cada fase;
  - checkboxes no PLAN;
  - commits em Conventional Commits em português;
  - analyze e test antes de cada commit.
- **Decisões que mudam o plano:** pare e proponha antes de trocar pacote ou abordagem. O usuário já aprovou uma vez esse fluxo (o canal nativo).
- **Downloads, mudanças de configuração global e exclusão de arquivos fora do projeto:** pedir permissão.
- **Armadilhas conhecidas:**
  - `package:flutter/material.dart` está obsoleto: use `package:material_ui/material_ui.dart`;
  - o `Set-Content -Encoding utf8` do PowerShell 5.1 grava BOM; prefira as ferramentas de edição ou o Git Bash;
  - os arquivos ficam com CRLF no checkout, o que pode quebrar substituições exatas de texto: leia o arquivo antes de editar;
  - o build do Gradle precisa de alguns GB livres em C:;
  - o adb não injeta toques nesse Xiaomi: para testes sem interação, faça o app rodar o fluxo sozinho e grave no logcat com `debugPrint`;
  - parsers do `metadata_audio` podem engolir `TokenizerException` em silêncio: sempre confira `lastMiss` depois do parse.
- **Comportamento do app antigo:** use `git show main:<caminho>` como referência de **comportamento**, nunca de estrutura.
