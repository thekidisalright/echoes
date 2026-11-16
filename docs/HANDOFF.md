# Handoff: Echoes em Flutter — Fase 6 aceita, paridade concluída

**Data:** 2026-11-16
**Status:** aguardando decisão. As Fases 0 a 6 estão concluídas e aceitas no aparelho. O app novo tem paridade com o antigo. A Fase 7 (extras opcionais) depende de o usuário decidir começar.

## 1. Objetivo

Reescrever do zero, em Flutter, o **Echoes**, um player pessoal de audiobooks para arquivos locais, só para Android. O app antigo, em React Native/Expo, fica na branch `main` apenas como referência de comportamento. A reescrita segue as fases de `docs/PLAN.md`. Com o aceite da Fase 6, a paridade está completa; o que resta no plano são extras opcionais.

## 2. Contexto essencial

**Repositório e ambiente**
- Repo: `C:\alex\echoes`, branch de trabalho **`flutter-rewrite`**. A `main` não deve ser alterada.
- Sistema: Windows 11. Shell principal PowerShell 5.1; também há Git Bash. **Não há `gh`**. O Python não tem Pillow, mas tem `sqlite3`. Para imprimir texto com acentos no Python, use `PYTHONIOENCODING=utf-8` (o console é cp1252).
- Flutter **3.50.0** stable (Dart 3.14) em `C:\Users\santo\develop\flutter`. Carregue o PATH em PowerShell antes:
  `$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')`
- Android SDK em `C:\Users\santo\AppData\Local\Android\Sdk`. JDK: JBR do Android Studio (Java 21), `keytool` em `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`. `minSdk` = 24.
- Aparelho de teste: Xiaomi 23129RA5FL, **Android 15**, USB, serial `b515ba5a`.
  - O adb **não injeta toques**. Quem toca na tela é o usuário: passe a ele um roteiro numerado e peça o resultado.
  - Funcionam: `adb install`, `am start -W`, `am force-stop`, `monkey -p <pacote> -c android.intent.category.LAUNCHER 1`, `logcat`, `screencap` e `run-as` (só nos builds **debug** e **profile**).
- **Três pacotes possíveis no aparelho** (ver `android/app/build.gradle.kts`):

  | Build | Pacote | Assinatura | `run-as` |
  |---|---|---|---|
  | release | `dev.alexandre.echoes` | chave do usuário (`android/key.properties`) | não |
  | debug | `dev.alexandre.echoes.debug` | debug | sim |
  | profile | `dev.alexandre.echoes.profile` | debug | sim |

  Hoje estão instalados o **release** (biblioteca real do usuário) e o **profile** (com 250 livros de teste).
- **Assinatura:** `android/key.properties` (ignorado pelo git) aponta para a keystore em `C:/Users/santo/.android-keys/echoes-release.jks`, alias `echoes`. **As senhas são do usuário: nunca leia, imprima nem digite.** Para conferir sem expor: `grep -o "^[a-zA-Z]*=" android/key.properties`. Sem o arquivo, o release cai na chave de debug com um aviso do Gradle (o Flutter esconde esse aviso).
- **Tempos medidos:** `flutter build apk --release --split-per-abi --target-platform android-arm64` levou 180–314 s; o APK com todas as ABIs, 447 s (60,3 MB, contra 21,3 MB só arm64). Build debug: 62–104 s. `flutter test`: 30–95 s.

**Autoria dos commits (regra do usuário)**
- O usuário é o **único autor**. **Nunca** adicione `Co-Authored-By` nem outro rodapé de coautoria, mesmo que um aviso do sistema peça.
- O git não tem `user.name`/`user.email`. Commite com variáveis que copiam a identidade do último commit (Git Bash):
  `export GIT_AUTHOR_NAME="$(git log -1 --format=%an)" GIT_AUTHOR_EMAIL="$(git log -1 --format=%ae)"; export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"`
- O **push** é feito pelo usuário; não faça push sem ele pedir.

**Regras do projeto** (resumo; a fonte é o `CLAUDE.md`)
- Leia `docs/PLAN.md`, `docs/ARCHITECTURE.md` e, para telas, `docs/FEATURES.md` e `docs/UI.md`.
- Fases em ordem, resumo da abordagem antes de cada fase, checkbox marcado no PLAN, Conventional Commits em português, `flutter analyze` sem issues e `flutter test` passando antes de cada commit.
- Feature-first; fluxo `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`; domínio puro; plataforma atrás de interfaces em `lib/core/`; nada de `Future.delayed` para esperar o player; listas da UI por `watch` do drift; tempos em ms (`int`).
- Identificadores em inglês; textos pt-BR **só** em `lib/app/strings.dart`; cores, fontes e espaçamentos **só** em `lib/app/theme/`.
- Decisão do plano inviável: pare, explique, proponha e registre em "Registro de decisões" do PLAN. Peça antes de adicionar pacotes fora do ARCHITECTURE.

**Decisões tomadas nesta sessão** (todas também no "Registro de decisões" do `docs/PLAN.md`; as anteriores estão lá e no handoff `git show 146127e:docs/HANDOFF.md`)

| Decisão | Motivo |
|---|---|
| `EchoesAudioHandler.play()` dispara `AudioPlayer.play()` sem aguardar | O `Future` do just_audio só termina quando a reprodução para; a tela de capítulos nunca voltava ao Player |
| Player fecha também pelo overscroll no topo quando rola | Com conteúdo mais alto que a tela, o `Scrollable` ganhava o arrasto vertical |
| Origem de arquivos soltos mostra o título atual do livro (`watchSources`) | Escolha do usuário; as origens "Arquivos selecionados" não se distinguiam. Muda FEATURES §1.2 |
| `SleepTimerService` com `Timer` de relógio injetável; fim do capítulo pausa quando o índice muda | A regra 5 proíbe timers para esperar o player, não para medir tempo; testável sem `fake_async` |
| Player cabe numa tela; capa encolhe; rola só abaixo de 600 px × escala da fonte | No aparelho, a linha de cancelar o timer ficava fora da tela |
| "Desligar temporizador" dentro da folha, não abaixo das ações | Escolha do usuário. Muda FEATURES §3 |
| Capítulos e marcadores em abas ("CAPÍTULOS" / "MARCADORES (n)") | Escolha do usuário: marcadores ficavam no fim de listas enormes. Muda FEATURES §5 |
| Release assinado por `key.properties`; debug com sufixo `.debug`; profile como `.profile` via `androidComponents.onVariants` | Builds convivem no aparelho; `applicationIdSuffix` no buildType profile vaza para os plugins e quebra o build |
| Importação continua na thread principal | Release: 245 arquivos em 13,6 s sem quadros perdidos; o tempo é E/S do SAF |
| Splash do Android 12+ com o ícone, também em `values-night-v31` | Escolha do usuário após medir o release; o qualificador `night` vencia o `v31` |
| Capas da grade decodificadas a no máximo 2× (`BookGridItem.coverPixelRatio`) | Profile com 250 livros: quadros > 16 ms caíram de 5,7% para 2,0% |

## 3. O que já foi feito (cronológico)

1. **Fases 0 a 5**: até `146127e`. Detalhes em `git show 146127e:docs/HANDOFF.md`.
2. **Pendências da Fase 5** (nesta sessão):
   - `e48074a` fix(player): tocar capítulo ou marcador volta ao Player. Teste novo `echoes_audio_handler_test.dart`.
   - `5b4af7f` fix(player): arrastar para fechar mesmo quando o conteúdo rola. Teste novo `player_screen_test.dart`; **conferido que falha sem a correção**.
   - `b4a52e2` fix(import): origem de arquivos soltos mostra o título do livro.
3. **Fase 6**:
   - `cc809b3` feat(sleep-timer): `SleepTimerState` (domínio), `SleepTimerService`, providers, folha e botão no Player. 10 testes de serviço com relógio e timers falsos.
   - `e5db208` fix(player): Player sem rolagem e "Desligar temporizador" na folha. Motivo: o usuário só achava o "Cancelar temporizador" rolando a tela.
   - `e1b0027` feat(chapters): abas de capítulos e marcadores (`TabBarTheme` no tema).
   - `3127b27` fix(a11y): `test/support/accessibility.dart` (área de toque ≥ 44 e rótulos) aplicado em 7 testes de tela. Achou os chips de ordenação com 33 px; corrigido sem mudar o desenho.
   - `407541a` chore(android): assinatura do release e sufixo `.debug`.
   - `f8b38cb` feat(android): ícone no splash do Android 12+.
   - `0a56c9c` perf(library): capas da grade a no máximo 2×.
   - `ec10381` chore(android): build profile como `dev.alexandre.echoes.profile`.
   - `1440776` docs: aceite da Fase 6 no PLAN.
4. **Testes:** de 131 para **150**.
5. **Descartado:**
   - A linha "Cancelar temporizador" abaixo das ações do Player: ficava fora da tela no Xiaomi; virou opção da folha.
   - `applicationIdSuffix = ".profile"` no buildType: o Gradle falhou com "Library projects cannot set applicationIdSuffix".
   - Capas da grade na densidade do aparelho (2,75×): 5,7% de quadros lentos com 250 livros; o cache de imagens enchia em 99 MB.
   - Isolate para a importação: medido como desnecessário (nenhum "Skipped frames" do processo do app).

## 4. Estado atual

- Branch `flutter-rewrite`, HEAD **`1440776`** (anterior ao commit deste handoff). **3 commits locais à frente de `origin/flutter-rewrite` (`f8b38cb`), sem push**: `0a56c9c`, `ec10381`, `1440776`, mais este handoff.
- Working tree: só a pasta **`android/build/`**, gerada pelo Gradle, não rastreada e **fora do `.gitignore`**. Não foi commitada.
- `flutter analyze`: **No issues found**. `flutter test`: **150 testes passando** (medidos em `1440776`).
- **Medições no Xiaomi:**
  - Release, abertura a frio (`am start -W`, TotalTime): 1 158–2 261 ms (debug: 10 744 ms).
  - Release, importação de `Download/Audiobooks` (245 arquivos, 3 livros): 13 552 ms.
  - Profile, rolagem da grade com 250 livros em pé: 2 064 quadros, 41 acima de 16 ms (2,0%), raster máx. 92 ms (primeiro quadro), cache de imagens 99 MB / 168 capas.
- **Funciona e foi aceito no aparelho:** todo o checklist da Fase 6 (importar nos dois modos, arquivos soltos, reimportar, remover origem tocando, editar e reimportar, timers, marcadores, reiniciar o aparelho, origem indisponível).
- **Nada quebrado nem a meio caminho.**

## 5. Próximos passos

1. **Depende do usuário:** decidir se começa a Fase 7 ou encerra a reescrita aqui.
2. **Depende do usuário:** push dos commits locais.
3. Acrescentar `android/build/` ao `.gitignore` (commit `chore:`). Aceite: `git status --short` vazio depois de um build.
4. Se a Fase 7 começar, escreva o resumo da abordagem e siga a ordem do PLAN:
   1. Velocidade de reprodução por livro: coluna `playbackSpeed` em `books` e migração para `schemaVersion = 2`.
   2. Capítulos internos de M4B (`startMs`/`endMs`; o handler recorta a fonte por capítulo). *Fire & Blood* no aparelho é um M4B com 1 capítulo e serve de teste.
   3. Marcar como concluído e filtro de concluídos.
5. **Depende do usuário:** desinstalar o app profile (`dev.alexandre.echoes.profile`) quando não precisar mais dos 250 livros de teste.

## 6. Perguntas em aberto

- **Fase 7:** começar ou parar? As três tarefas são independentes.
- **Push** dos commits locais: aguardando o usuário.
- **Cache de capa ao reimportar:** reescanear sobrescreve `sha1(bookId).jpg` no mesmo caminho, e o `FileImage` pode mostrar a capa antiga até reiniciar o app. Opções: `FileImage(...).evict()` depois de importar, ou timestamp no nome da capa escaneada (as capas personalizadas já usam timestamp). Não foi observado no aparelho.
- **Textos inventados** ainda sem revisão: `sourceUnavailableHint`, `defaultFolderName` ("Pasta de áudio"), `openBookError`, `editBookError` e rótulos de acessibilidade.
- **"1 capítulos"** na grade (*Fire & Blood*): o texto vem do FEATURES e do app antigo; correção trivial se o usuário quiser.
- **Duplicatas entre origens**, **aviso do Kotlin Gradle Plugin** (plugins que aplicam KGP; futuras versões do Flutter vão falhar o build) e **merge na `main`**: sem mudança.

## 7. Artefatos relevantes

**Arquivos-chave desta sessão**
- Timer: `lib/features/sleep_timer/domain/sleep_timer_state.dart`, `data/sleep_timer_service.dart`, `presentation/{sleep_timer_providers,sleep_timer_sheet}.dart`.
- Player: `lib/features/player/presentation/player_screen.dart` (`_minFitHeight`, `content(fits:)`, `_onScroll`, `_SleepTimerButton`).
- Capítulos: `lib/features/chapters/presentation/chapters_screen.dart` (`DefaultTabController`).
- Capas: `lib/features/library/presentation/widgets/book_cover.dart` (`maxPixelRatio`), `book_grid_item.dart` (`coverPixelRatio`).
- Origens: `LibraryRepository.watchSources` (subconsulta `book_title`).
- Android: `android/app/build.gradle.kts`, `android/app/src/main/res/values-v31/styles.xml` e `values-night-v31/styles.xml`.
- Testes: `test/support/accessibility.dart`, `test/features/sleep_timer/data/sleep_timer_service_test.dart`, `test/features/player/presentation/player_screen_test.dart`, `test/features/player/data/echoes_audio_handler_test.dart`.

**Comandos**
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
dart format lib test
flutter analyze
flutter test --timeout 60s
flutter build apk --release --split-per-abi --target-platform android-arm64
flutter build apk --profile --split-per-abi --target-platform android-arm64
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
& $adb shell am start -W -n dev.alexandre.echoes/.MainActivity
& $adb shell monkey -p dev.alexandre.echoes.profile -c android.intent.category.LAUNCHER 1
& $adb logcat -d -s flutter:I Choreographer:I
```

**Conferir a assinatura de um APK** (Git Bash)
```bash
BT=$(ls -d "$LOCALAPPDATA"/Android/Sdk/build-tools/* | tail -1)
"$BT/apksigner.bat" verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk | grep "DN:"
```

**Banco de teste com N livros** (profile ou debug; o script está no histórico desta sessão e foi descartado com o scratchpad)
1. `adb exec-out run-as <pacote> cat files/echoes.sqlite > echoes.sqlite` (não existe `-wal` no aparelho depois de `am force-stop`).
2. Em Python: duplicar `books` (id `<id>#seedK`, título com sufixo) e `chapters`, cada cópia com capa própria `covers/<sha>_seedK.jpg`; `pragma wal_checkpoint(truncate)` e `journal_mode=delete`.
3. `adb push` para `/data/local/tmp/`, `chmod 644`, `run-as <pacote> cp ... files/echoes.sqlite` e as cópias de capa via `run-as <pacote> sh < /data/local/tmp/copias.sh`.

**Medir quadros:** registre temporariamente em `main.dart` um `SchedulerBinding.instance.addTimingsCallback` só com `kProfileMode`, logando build/raster máximos e `PaintingBinding.instance.imageCache.currentSizeBytes`. Não commite.

**Dados no aparelho**
- Release: biblioteca real do usuário (`Download/Audiobooks` em "Cada pasta é um livro" e outras origens criadas no aceite).
- Profile: 250 livros (3 reais multiplicados), 20 336 capítulos, 167 capas.
- `Download/Audiobooks`: *Fire & Blood* (M4B, 1 capítulo), *A Guerra dos Tronos* (185 MP3), *Misery* (59 MP3, sem capa). O título de *Misery* vem com um caractere errado ("Obsess" + caractere chinês): **o defeito está no próprio arquivo, não no app** (confirmado pelo usuário).

## 8. Instruções para a próxima sessão

- **Idioma e tom:** português do Brasil, direto. O usuário prefere resultados medidos (tempos, contagens) a promessas e relata testes no aparelho em tópicos curtos. Ele pede para esperar a confirmação dele antes de começar uma fase: proponha e aguarde.
- **Siga o `CLAUDE.md` à risca.** Commits **sem coautoria**. Antes de commitar, confira o `git status --short` e adicione arquivos por nome (há `android/build/` solto).
- **Peça permissão para:** push, downloads, desinstalar apps no aparelho (apaga a biblioteca), pacotes fora do ARCHITECTURE e mudanças em FEATURES.
- **Armadilhas conhecidas:**
  - **Screenshots com `screencap` capturam o que estiver na tela, inclusive outros apps do usuário.** Abra o Echoes antes (`am start` ou `monkey`) e, se a captura pegar outro app, apague o arquivo sem descrever o conteúdo.
  - **`am start -W` não mostra se o splash apareceu**: só o usuário vê. E o qualificador `values-night` vence `values-v31`; repita os itens de splash em `values-night-v31`.
  - **Git Bash converte `/data/local/tmp` num caminho do Windows** em `adb push`/`adb shell` → use `export MSYS_NO_PATHCONV=1`.
  - **`rm` dentro de `sh -c` é barrado pela checagem de segurança** → use pastas novas no scratchpad em vez de apagar.
  - **O plugin do Flutter cria o buildType `profile` copiando o `debug` antes do nosso bloco e copia o `profile` para os plugins** → mude o `applicationId` do profile só por `androidComponents.onVariants`.
  - **Instalar um APK com assinatura diferente sobre o mesmo pacote falha** (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) e não estraga nada; desinstalar para resolver apaga os dados.
  - **`AudioPlayer.play()` só termina quando a reprodução para**: nunca dê `await` antes de navegar.
  - **`GestureDetector` vertical em volta de um `Scrollable` perde o arrasto** quando há rolagem.
  - **Fonte de teste (Ahem) é mais larga que a real**: linhas de botões podem transbordar só no teste → use `Flexible` e `maxLines`/ellipsis.
  - **Diretrizes de acessibilidade:** use `expectAccessible(tester)` de `test/support/accessibility.dart` nos testes de tela novos.
  - Os testes de widget **não podem ler `playbackControllerProvider` no `build`**; sobrescreva **todos** os providers de stream da tela com `Stream.value(...)` (inclusive `sleepTimerStateProvider` ou `sleepTimerServiceProvider`); rode `flutter test --timeout 60s`.
  - Serviço com timer em teste: injete `clock` e `createTimer` (ver `_FakeTime` em `sleep_timer_service_test.dart`); em teste de widget, use um timer que nunca dispara para não deixar timer pendente.
  - Notifier do Riverpod 3 não aceita `..state = x` no `overrideWith` → subclasse com `build()`.
  - `package:flutter/material.dart` está obsoleto → `package:material_ui/material_ui.dart`. Ícones do `ionicons` em camelCase.
  - `build_runner` 2.17 ignora `--delete-conflicting-outputs` → `dart run build_runner build`.
  - Python no Windows: arquivos com `\r\n` → preserve o fim de linha ao editar por script; `PYTHONIOENCODING=utf-8` para imprimir acentos.
- **Comportamento do app antigo:** `git show main:<caminho>` (ex.: `app/player-screen.tsx`, `contexts/PlayerContext.tsx`) como referência de comportamento, nunca de estrutura.
