# Plano de execução — Echoes em Flutter

Plano definitivo da reconstrução. Execute as fases **em ordem**; cada uma termina com critérios de aceite verificáveis.
Marque `[x]` ao concluir cada tarefa e faça commit ao final de cada grupo coeso.

## Decisões fechadas

| # | Decisão | Escolha |
|---|---|---|
| 1 | Gerenciamento de estado | **Riverpod** |
| 2 | Dados da versão React Native | **Não migrar** — começar com biblioteca vazia |
| 3 | Repositório | **Mesmo repositório, branch `flutter-rewrite`**; `main` fica intacta como referência |
| 4 | Identidade visual | **Manter** (ver `docs/UI.md`) |
| 5 | Plataforma | Somente Android |
| 6 | `applicationId` | `dev.alexandre.echoes` (novo; o app antigo pode ser desinstalado) |

---

## Fase 0 — Preparação e spike de risco

Objetivo: provar que as três peças de plataforma funcionam juntas **antes** de construir qualquer coisa em cima.

### 0.1 Branch e limpeza
- [x] `git switch -c flutter-rewrite` a partir de `main` (os .md desta documentação vêm junto).
- [x] Remover todos os arquivos do projeto Expo: `app/`, `components/`, `contexts/`, `src/`, `types/`, `android/`, `.expo/`, `node_modules/`, `package.json`, `package-lock.json`, `app.json`, `babel.config.js`, `metro.config.js`, `tailwind.config.js`, `global.css`, `*.d.ts`, `eslint.config.js`, `tsconfig.json`, `.vscode/settings.json` (se for específico de RN).
- [x] **Manter:** `README.md`, `CLAUDE.md`, `docs/`, `.git/`, `assets/images/icon.png`, `assets/images/android-icon-*.png`, `assets/images/splash-icon.png`.
- [x] `flutter create --org dev.alexandre --project-name echoes --platforms android .`
- [x] Ajustar `.gitignore` para Flutter.
- [x] Commit: `chore: substituir projeto Expo por projeto Flutter`.

### 0.2 Spike (código descartável em `lib/spike/`, removido no fim da fase)
- [x] Adicionar `docman`, `metadata_audio`, `just_audio`.
- [x] Botão que escolhe uma pasta via SAF com permissão persistente.
- [x] Listar recursivamente os `.mp3/.m4a/.m4b` e imagens da pasta.
- [x] Ler metadados (título, álbum, artista, faixa, duração, capa embutida) de um `.mp3` e de um `.m4b` **a partir da URI `content://`**. *(245 arquivos, 0 falhas; M4B de 720 MB com título, autor, capa e 23 capítulos em 1,3 s)*
- [x] Tocar o primeiro arquivo com just_audio a partir da URI e fazer seek para 1:00. *(usa o maior arquivo, já que o primeiro tinha 18 s)*
- [x] Fechar e reabrir o app: a permissão da pasta continua válida e a listagem funciona sem escolher de novo.

**Se algo falhar:**
- `metadata_audio` não aceita URI/stream → testar `flutter_taglib`; se nenhum aceitar, ler via stream os primeiros ~512 KB (cabeçalhos ID3/MP4) e os últimos KB, ou copiar temporariamente para o cache, ler e apagar.
- `docman` não lista recursivamente ou não persiste → testar `saf`.
- Registrar a escolha final em "Registro de decisões" abaixo e atualizar `docs/ARCHITECTURE.md`.

**Aceite da Fase 0:** ✅ concluído em 2026-11-16 (aparelho: Android 15). Os 6 itens do spike funcionam num aparelho físico; decisões registradas; `lib/spike/` removido.

---

## Fase 1 — Fundação

- [x] Adicionar pacotes definitivos (ver `docs/ARCHITECTURE.md` → Pacotes).
- [x] `analysis_options.yaml` com `flutter_lints` + regras extras: `prefer_const_constructors`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `require_trailing_commas`, `unawaited_futures`.
- [x] Estrutura de pastas completa conforme `docs/ARCHITECTURE.md` (pastas vazias com `.gitkeep` quando necessário).
- [x] Fontes Cormorant Garamond 400/500/700 em `assets/fonts/` e registradas no `pubspec.yaml`.
- [x] `app/theme/` com todos os tokens de `docs/UI.md`; `ThemeData` escuro.
- [x] `app/strings.dart` com todos os textos de `docs/FEATURES.md`.
- [x] `app/router.dart` com as rotas: `/` (biblioteca), `/player` (modal de baixo), `/chapters`, `/manage`, `/settings` — telas placeholder.
- [x] `core/utils/`: `natural_sort`, `file_names` (`cleanTitle`, `parseTrackNumber`, `isAudio`, `isImage`, `isPreferredCover`), `duration_format` — **com testes unitários** cobrindo os exemplos de `docs/FEATURES.md` 1.3.
- [x] Ícone do app e splash a partir dos assets mantidos; nome "Echoes".

**Aceite:** ✅ concluído em 2026-11-16 (Android 15; ícone na home a conferir pelo usuário). App abre no tema escuro com o título "Echoes" em Cormorant; navegação entre placeholders funciona; `flutter analyze` limpo; testes de utils passando.

---

## Fase 2 — Banco de dados

- [x] Tabelas drift conforme `docs/DATA_MODEL.md`, `schemaVersion = 1`, `foreign_keys = ON`.
- [x] `LibraryRepository`: `saveScannedSource`, `removeSource`, `updateBookDetails`, `resetBookDetails`, `watchLibrary`, `watchContinueListening`, `watchSources`, `chaptersOf`, `getBook`.
- [x] `ProgressRepository` (pode ficar dentro do player): `saveProgress`, `getProgress`, `touchLastPlayed`.
- [x] `BookmarkRepository`: `add`, `remove`, `watchByBook`.
- [x] `SettingsRepository`: `lastPlayedBookId`, `librarySort`.
- [x] `CoverStore` (`core/files/`).
- [x] Testes com banco em memória: reimportação preserva `custom*` e progresso; livros/capítulos ausentes no novo scan são removidos; progresso apontando para capítulo removido é reposicionado; remoção de origem faz cascade.

**Aceite:** ✅ concluído em 2026-11-16. 32 testes novos de repositório e `CoverStore` passando (61 no total); `flutter analyze` limpo.

---

## Fase 3 — Importação

- [x] Interface `StorageGateway` + implementação SAF definida na Fase 0.
- [x] Interface `MetadataReader` + implementação definida na Fase 0.
- [x] `LibraryScanner` puro (recebe gateway + reader): agrupamento por pasta, modos `oneBook`/`booksInFolders`, ordenação, regras de título/autor/capa, `skipUris`, stream de `ImportProgress`.
- [x] `ImportService`: `importFolder(mode)`, `importFiles()`, `rescan(source)`, `remove(source)`, `refreshAvailability()`.
- [x] Providers de importação (estado: ocioso / importando com mensagem / erro tipado).
- [x] Testes do scanner com `FakeStorageGateway` + `FakeMetadataReader`: árvore aninhada nos dois modos, ordenação com e sem número, prioridade de capa, arquivo com metadado ilegível, arquivos já existentes em outra origem.

**Aceite:** ✅ concluído em 2026-11-16 (Android 15). 31 testes novos de scanner, `ImportService` e URIs SAF (92 no total). No aparelho, pela tela provisória de Gerenciar: `Download/Audiobooks` em "Cada pasta é um livro" → 3 livros, 245 capítulos (todos com duração), 2 capas, em 16,4 s; atualizar a origem: 11,2 s. Banco conferido copiando o `echoes.sqlite` com `run-as`.

---

## Fase 4 — Motor de áudio

- [x] Configuração Android do audio_service (manifest, `AudioServiceActivity`, permissões, canal de notificação "Reprodução").
- [x] `audio_session` com preset `speech`.
- [x] `EchoesAudioHandler`: fila de `MediaItem` por capítulo; `play`, `pause`, `seek`, `skipToNext`, `skipToPrevious` (regra dos 3 s), `skipToQueueItem`, `fastForward`/`rewind` de 15 s; ações da notificação conforme `docs/FEATURES.md` §8; publica `playbackState` e `mediaItem`.
- [x] Carregar livro com **índice e posição iniciais** no carregamento da fonte (sem timers).
- [x] `PlaybackController` + providers: livro atual, capítulo atual, posição, duração, tocando, buffering.
- [x] `ProgressSaver` com todas as regras de `docs/ARCHITECTURE.md` → "Salvar progresso", incluindo `AppLifecycleState`.
- [x] Reabrir último livro (sem tocar) na inicialização.
- [x] Fim do último capítulo: pausa e mantém o livro carregado.
- [x] Testes do `ProgressSaver` e da regra de capítulo anterior com um player fake.

**Aceite (aparelho físico):** tocar, pausar e pular pela notificação e pela tela de bloqueio; bloquear a tela por 10 min e o áudio continua; remover o app do multitarefa e reabrir → volta no capítulo e posição certos (diferença ≤ 10 s); desconectar fone pausa.

✅ concluído em 2026-11-16 (Android 15, Xiaomi), com telas provisórias de lista e de player: os quatro itens conferidos pelo usuário. No banco, depois de reabrir: Misery no 6º capítulo, 837 s, `lastPlayedBookId` correto. 105 testes passando (13 novos: regras de navegação e `ProgressSaver`).

---

## Fase 5 — Telas

Seguir `docs/FEATURES.md` e `docs/UI.md` à risca. Ordem:

- [x] 5.1 Gerenciar biblioteca (botões, banner de progresso, lista de origens, atualizar, remover com confirmação, diálogo de modo).
- [x] 5.2 Biblioteca: cabeçalho, banner, Continue ouvindo, busca, chips de ordenação, grade responsiva, estado vazio, origem indisponível.
- [x] 5.3 MiniPlayer (com barra de progresso fina).
- [x] 5.4 Player: capa, textos, SeekBar, controles, linha de ações, gesto de arrastar para fechar.
- [x] 5.5 Capítulos e marcadores (com rolagem até o capítulo atual).
- [x] 5.6 Diálogo de edição de livro (capa via `image_picker` + `CoverStore`, restaurar dados originais).
- [x] 5.7 Configurações (ordenação + Sobre).

**Aceite:** todos os fluxos de `docs/FEATURES.md` §1–§7 executáveis no aparelho; sem textos fora de `strings.dart`; sem cores fora de `colors.dart`.

✅ aceito pelo usuário em 2026-11-16 (Android 15, Xiaomi), com quatro pendências registradas para corrigir antes da Fase 6 (ver `docs/HANDOFF.md` → Estado atual): tocar num marcador não volta ao Player; arrastar o Player para baixo falha na maioria dos livros; origens "Arquivos selecionados" não se distinguem em Gerenciar; não há splash/tela de carregamento enquanto o app abre. 131 testes passando; nenhuma cor fora do tema nem texto fora de `strings.dart`.

---

## Fase 6 — Timer de sono, marcadores e acabamento

- [ ] `SleepTimerService`: por minutos (com tempo restante exposto) e fim de capítulo; folha inferior; cancelar.
- [ ] Marcadores no Player (feedback "Salvo") e na tela de capítulos (ir para, remover).
- [ ] Animações de rota conforme `docs/UI.md` → Movimento.
- [ ] Acessibilidade: `Semantics` com rótulos em todos os botões de ícone; ação de toque longo anunciada como "Editar audiobook"; áreas de toque ≥ 44.
- [ ] Revisão de desempenho: biblioteca com 200+ livros rolando sem travar (capas com `cacheWidth`); importação de pasta grande não congela a UI (leitura de metadados fora da thread de UI se necessário).
- [ ] Build release assinado (`flutter build apk --release`) instalado e testado.

**Aceite (checklist manual final):**
- [ ] Importar pasta nos dois modos
- [ ] Importar arquivos soltos
- [ ] Reimportar após adicionar e remover arquivos na pasta
- [ ] Remover origem enquanto um livro dela toca
- [ ] Editar título/autor/capa e reimportar — edição preservada
- [ ] Timer de 15 min e timer de fim de capítulo
- [ ] Criar, usar e remover marcador
- [ ] Reiniciar o aparelho → biblioteca disponível sem escolher pastas de novo
- [ ] Revogar a permissão da pasta nas configurações do Android → origem aparece como indisponível

---

## Fase 7 — Extras (opcionais, só após a paridade)

- [ ] Velocidade de reprodução por livro (adicionar coluna `playbackSpeed` em `books` → migração para `schemaVersion = 2`).
- [ ] Capítulos internos de M4B (usar `startMs`/`endMs`; o handler recorta a fonte por capítulo).
- [ ] Marcar como concluído e filtro de concluídos.

---

## Registro de decisões

Anote aqui toda decisão tomada durante a implementação que mude ou detalhe este plano.

| Data | Fase | Decisão | Motivo |
|---|---|---|---|
| 2026-11-15 | — | Plano inicial aprovado | — |
| 2026-11-15 | 0.1 | Alterações locais não commitadas do app RN foram commitadas na `main` (3ed97c2) antes de criar a branch | Manter a `main` como referência completa do comportamento antigo |
| 2026-11-15 | 0.1 | Material importado de `package:material_ui` (não mais `package:flutter/material.dart`) | No Flutter 3.50 o Material saiu do SDK; o import antigo é obsoleto e o template já usa `material_ui` |
| 2026-11-15 | 0 | Listagem de pastas e leitura de trechos de arquivo via **canal nativo próprio** (`SafChannel.kt`, canal `dev.alexandre.echoes/saf`: `listTree`, `readRange`); `docman` fica só para seletor e permissões persistidas | `docman.listDocuments` faz ~8 consultas ao ContentResolver por arquivo: 244 arquivos em 28 s. O canal faz 1 consulta por pasta: 0,4–0,9 s. O `readAsBytes` do docman usa `skip` e não para de ler ao cancelar |
| 2026-11-15 | 0 | `metadata_audio` lido por um **tokenizer esparso** (`SparseTokenizer`, que estende `HttpBasedTokenizer`): 128 KB iniciais + 8 KB finais via `readRange`, `prefetchRange` atendido sob demanda e nova tentativa sempre que faltar um trecho. Código de referência no commit `3ff39c8` (`lib/spike/saf_metadata.dart`) | O pacote não aceita `content://` e o `Tokenizer` dele é síncrono. Estender `HttpBasedTokenizer` faz o parser MP4 pedir o `moov` inteiro (8 MB no M4B testado); sem isso ele engolia a falta de bytes e devolvia tags vazias. Resultado: 245 arquivos, 0 falhas, 40 MB lidos, 12 s |
| 2026-11-15 | 0 | Risco anotado: `docman` aplica o Kotlin Gradle Plugin no formato antigo | O Flutter avisa que versões futuras vão recusar o build. Como o uso agora é pequeno (seletor + permissões), dá para trocar por código no próprio `SafChannel` se for preciso |
| 2026-11-16 | 1 | `cupertino_icons` removido; tokens de espaçamento e raios em `lib/app/theme/spacing.dart`; cores derivadas (`miniPlayerBorder`, `shadow`) viraram tokens | Só Android; nenhum valor visual solto em widget, conforme o CLAUDE.md |
| 2026-11-16 | 1 | Cormorant Garamond empacotada como **fonte variável** (`CormorantGaramond-VariableFont_wght.ttf`), com o peso aplicado via `FontVariation.weight` | Arquivo fornecido pelo usuário; um único `.ttf` cobre 400/500/700 |
| 2026-11-16 | 1 | Splash e janela com fundo `#171614` (sem imagem); ícone e splash gerados à mão, sem `flutter_launcher_icons`/`flutter_native_splash` | Decisão do usuário. Os PNGs de `assets/images/` são os placeholders do template do Expo, por isso não foram usados |
| 2026-11-16 | 1 | Ícone próprio desenhado em vetor (`drawable/ic_launcher_foreground.xml` e `ic_launcher_monochrome.xml`: ponto e três anéis de eco em `accent` sobre `background`), adaptativo com variante monocromática; PNGs legados (API 24–25) gerados com o mesmo desenho | Os PNGs de `assets/images/` eram placeholders do Expo; o usuário pediu um ícone vetorial |
| 2026-11-16 | 2 | Busca da biblioteca feita em Dart (`toLowerCase` + `contains` sobre título e autor exibidos), não com `LIKE` | O `LIKE`/`lower()` do SQLite só ignoram maiúsculas em ASCII ("É" ≠ "é"); a ordenação por título já é em Dart, e o app antigo filtrava assim |
| 2026-11-16 | 2 | Na reimportação, marcadores que apontam para um capítulo removido são apagados | O DATA_MODEL não define o caso; um marcador de capítulo inexistente não tem para onde levar |
| 2026-11-16 | 2 | Capas órfãs são limpas por `CoverStore.deleteOrphans(LibraryRepository.coverPathsInUse())`, chamado pelo `ImportService` (Fase 3) depois de salvar ou remover origem | Um único caminho cobre remoção de origem, livros sumidos no reescaneamento e troca de extensão da capa |
| 2026-11-16 | 2 | `LibraryRepository` ganhou `getSource`, `setSourceAvailability` e `chapterUrisOutside` (para o `skipUris`); `ProgressRepository` fica em `features/player/data/` e ignora livro inexistente em vez de falhar | Necessários para `rescan`, `refreshAvailability` e a regra de duplicatas da Fase 3; o player pode salvar progresso logo após a origem ser removida |
| 2026-11-16 | 2 | `app_database.g.dart` é versionado | Build e testes funcionam sem rodar o `build_runner`; ele continua sendo regenerado após mudar tabelas |
| 2026-11-16 | 3 | O URI da pasta escolhida é convertido para o formato de árvore (`treeUriOf`: `…/tree/X/document/X` → `…/tree/X`) antes de virar id da origem | O docman devolve a pasta no formato de documento, mas a permissão persistida fica no formato de árvore; sem a conversão, "Atualizar" achava que a permissão tinha expirado (visto no aparelho) |
| 2026-11-16 | 3 | Modo "pasta inteira": faixas ordenadas por pasta (ordem natural do caminho) e depois pela regra de faixas; imagens de todas as pastas da árvore valem como capa | O app antigo ordenava só pelo nome do arquivo (intercalava `CD1/01` e `CD2/01`) e descartava as imagens nesse modo |
| 2026-11-16 | 3 | O `LibraryScanner` não grava capas: devolve uma candidata (imagem da pasta ou capa embutida) e o `ImportService` a grava com o `CoverStore`; capa embutida só é pedida ao leitor enquanto nenhuma foi achada e não há imagem preferida na pasta | Mantém o scanner puro e testável, e evita extrair a capa de cada arquivo |
| 2026-11-16 | 3 | Progresso da importação por callback (`onProgress`), não por stream; o `ImportController` (Riverpod) o converte em estado | Uma importação por vez, sem assinatura para gerenciar; os testes ficam diretos |
| 2026-11-16 | 3 | Pasta nova sem áudio novo não é salva e a permissão é liberada; arquivos soltos repetidos não têm a permissão liberada (ela ainda serve à origem antiga) | Não deixar origens vazias nem permissões órfãs, sem quebrar origens existentes |
| 2026-11-16 | 3 | `StorageGateway` ficou com `pickDirectory`, `pickAudioFiles`, `listTree`, `readRange`, `persistedUris` e `releasePermission` (em vez de `openRead`/`hasPermission`) | O leitor de metadados precisa de leitura por trecho, e a checagem de disponibilidade compara todas as origens com uma única listagem de permissões |
| 2026-11-16 | 4 | `ProgressSaver` guiado pelas atualizações do player: grava quando a posição anda 10 s desde a última gravação, ao pausar, ao trocar de capítulo e em `flush()`; sem `Timer` periódico. O primeiro estado de cada livro é só referência | Testável com um stream fake e sem gravações redundantes; cumpre as mesmas regras do ARCHITECTURE |
| 2026-11-16 | 4 | Regras de navegação (3 s, saltos de 15 s, próximo no último) são funções puras em `player/domain/skip_rules.dart` e testadas como tal; o `EchoesAudioHandler` só as aplica ao just_audio e foi validado no aparelho | Evita abstrair o just_audio só para testes; a lógica que pode errar fica coberta |
| 2026-11-16 | 4 | Enquanto um livro novo carrega, o `PlaybackController` suprime estado e snapshots | Os streams do just_audio misturam o livro anterior com o novo no meio da troca; sem isso o saver gravaria o capítulo errado |
| 2026-11-16 | 4 | `lastPlayedAt` é atualizado ao abrir com `autoplay` e a cada gravação de progresso; abrir sem tocar (início do app) não mexe | A reabertura automática não deve reordenar "Recentes" |
| 2026-11-16 | 4 | Notificação usa `drawable/ic_launcher_monochrome` como ícone pequeno (mantido no release por `res/raw/keep.xml`); fechar pelo multitarefa salva e encerra o serviço só se estiver pausado | Ícone do próprio app; continuar tocando ao remover do multitarefa é o comportamento esperado de player |
| 2026-11-16 | 4 | Teste de navegação substitui os providers de lista por streams fixos | Streams do drift não terminam dentro do `FakeAsync` dos testes de widget e o `pumpAndSettle` trava (até o timeout de 10 min) |
| 2026-11-16 | 5 | Falhas de importação viram alerta no `EchoesApp` (navigator raiz), não na tela de Gerenciar | A importação pode terminar depois de o usuário sair da tela; os resultados ("nada novo" etc.) continuam com quem chamou |
| 2026-11-16 | 5 | Remover origem: o `ImportController` chama `PlaybackController.close()` antes, se o livro carregado é dela | O MiniPlayer some e o progresso é salvo antes de a origem ser apagada |
| 2026-11-16 | 5 | Livro com origem indisponível leva a Gerenciar com `ManageLibraryArgs(notice)` na rota | FEATURES §2 pede "uma mensagem para atualizar a pasta" |
| 2026-11-16 | 5 | Tocar num livro abre **sem tocar** (`autoplay: false`) e mostra o Player | Paridade com o app antigo (`openBook(book, false)` em `BookItem`/`ContinueListeningItem`) |
| 2026-11-16 | 5 | Botão de Temporizador do Player fica para a Fase 6, junto com o `SleepTimerService`; Marcador e Capítulos já entram na 5.4 | Não exibir botão sem função |
| 2026-11-16 | 5 | Rota do Player não opaca e arrasto com `Transform` próprio; ao soltar além de 120 px (ou > 900 px/s) faz `pop` e a transição de saída continua do ponto do dedo | A biblioteca aparece por baixo durante o gesto, sem animação extra |
| 2026-11-16 | 5 | Novo token `AppColors.danger` (`#8C3F35`) para o botão "Remover"; escala de espaçamento (`xs`…`xxl`) e tamanhos de ícone em `AppSpacing` | O UI.md não definia cor destrutiva; nenhum valor solto em widget |
| 2026-11-16 | 5 | `image_picker` atrás de `ImageGateway` e versão via `package_info_plus` atrás de `AppInfo` (`lib/core/`) | Regra 4 do CLAUDE.md; `package_info_plus` aprovado pelo usuário |
| 2026-11-16 | 5 | Edição de livro passa por `BookEditor` (data); o `PlaybackController.refreshBook` atualiza título/capa do livro carregado e a notificação sem recarregar o áudio | Widget não fala com `CoverStore`/banco; o Player não fica com dados velhos |
| 2026-11-16 | 5 | Texto de biblioteca vazia trocado pelo do app antigo ("Toque em Gerenciar biblioteca para adicionar uma pasta ou arquivos.") e o botão leva a Gerenciar; "Tente outro título ou autor." na busca vazia | Textos reais do app antigo em vez de inventados |
| 2026-11-16 | 5 | `EchoesAudioHandler.play()` dispara `AudioPlayer.play()` sem aguardar | O `Future` do just_audio só termina quando a reprodução para; a tela de capítulos nunca voltava ao Player |
| 2026-11-16 | 5 | O Player também fecha pelo overscroll no topo do `SingleChildScrollView` (o `GestureDetector` continua valendo quando nada rola) | Com conteúdo mais alto que a tela, o `Scrollable` ganhava o arrasto vertical |
| 2026-11-16 | 5 | Origem de arquivos soltos aparece em Gerenciar com o título atual do livro (`watchSources`); "Arquivos selecionados" fica como reserva | Escolha do usuário (opção a): as origens de arquivos não se distinguiam. Muda FEATURES §1.2 |
| 2026-11-16 | 6 | Splash: medir a abertura no build release antes de decidir | Escolha do usuário; o debug (10,7 s) inclui JIT e não é representativo |
