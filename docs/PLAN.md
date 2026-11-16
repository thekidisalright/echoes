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
- [ ] Botão que escolhe uma pasta via SAF com permissão persistente.
- [ ] Listar recursivamente os `.mp3/.m4a/.m4b` e imagens da pasta.
- [ ] Ler metadados (título, álbum, artista, faixa, duração, capa embutida) de um `.mp3` e de um `.m4b` **a partir da URI `content://`**.
- [ ] Tocar o primeiro arquivo com just_audio a partir da URI e fazer seek para 1:00.
- [ ] Fechar e reabrir o app: a permissão da pasta continua válida e a listagem funciona sem escolher de novo.

**Se algo falhar:**
- `metadata_audio` não aceita URI/stream → testar `flutter_taglib`; se nenhum aceitar, ler via stream os primeiros ~512 KB (cabeçalhos ID3/MP4) e os últimos KB, ou copiar temporariamente para o cache, ler e apagar.
- `docman` não lista recursivamente ou não persiste → testar `saf`.
- Registrar a escolha final em "Registro de decisões" abaixo e atualizar `docs/ARCHITECTURE.md`.

**Aceite da Fase 0:** os 6 itens do spike funcionam num aparelho físico; decisões registradas; `lib/spike/` removido.

---

## Fase 1 — Fundação

- [ ] Adicionar pacotes definitivos (ver `docs/ARCHITECTURE.md` → Pacotes).
- [ ] `analysis_options.yaml` com `flutter_lints` + regras extras: `prefer_const_constructors`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `require_trailing_commas`, `unawaited_futures`.
- [ ] Estrutura de pastas completa conforme `docs/ARCHITECTURE.md` (pastas vazias com `.gitkeep` quando necessário).
- [ ] Fontes Cormorant Garamond 400/500/700 em `assets/fonts/` e registradas no `pubspec.yaml`.
- [ ] `app/theme/` com todos os tokens de `docs/UI.md`; `ThemeData` escuro.
- [ ] `app/strings.dart` com todos os textos de `docs/FEATURES.md`.
- [ ] `app/router.dart` com as rotas: `/` (biblioteca), `/player` (modal de baixo), `/chapters`, `/manage`, `/settings` — telas placeholder.
- [ ] `core/utils/`: `natural_sort`, `file_names` (`cleanTitle`, `parseTrackNumber`, `isAudio`, `isImage`, `isPreferredCover`), `duration_format` — **com testes unitários** cobrindo os exemplos de `docs/FEATURES.md` 1.3.
- [ ] Ícone do app e splash a partir dos assets mantidos; nome "Echoes".

**Aceite:** app abre no tema escuro com o título "Echoes" em Cormorant; navegação entre placeholders funciona; `flutter analyze` limpo; testes de utils passando.

---

## Fase 2 — Banco de dados

- [ ] Tabelas drift conforme `docs/DATA_MODEL.md`, `schemaVersion = 1`, `foreign_keys = ON`.
- [ ] `LibraryRepository`: `saveScannedSource`, `removeSource`, `updateBookDetails`, `resetBookDetails`, `watchLibrary`, `watchContinueListening`, `watchSources`, `chaptersOf`, `getBook`.
- [ ] `ProgressRepository` (pode ficar dentro do player): `saveProgress`, `getProgress`, `touchLastPlayed`.
- [ ] `BookmarkRepository`: `add`, `remove`, `watchByBook`.
- [ ] `SettingsRepository`: `lastPlayedBookId`, `librarySort`.
- [ ] `CoverStore` (`core/files/`).
- [ ] Testes com banco em memória: reimportação preserva `custom*` e progresso; livros/capítulos ausentes no novo scan são removidos; progresso apontando para capítulo removido é reposicionado; remoção de origem faz cascade.

**Aceite:** todos os testes de repositório passam.

---

## Fase 3 — Importação

- [ ] Interface `StorageGateway` + implementação SAF definida na Fase 0.
- [ ] Interface `MetadataReader` + implementação definida na Fase 0.
- [ ] `LibraryScanner` puro (recebe gateway + reader): agrupamento por pasta, modos `oneBook`/`booksInFolders`, ordenação, regras de título/autor/capa, `skipUris`, stream de `ImportProgress`.
- [ ] `ImportService`: `importFolder(mode)`, `importFiles()`, `rescan(source)`, `remove(source)`, `refreshAvailability()`.
- [ ] Providers de importação (estado: ocioso / importando com mensagem / erro tipado).
- [ ] Testes do scanner com `FakeStorageGateway` + `FakeMetadataReader`: árvore aninhada nos dois modos, ordenação com e sem número, prioridade de capa, arquivo com metadado ilegível, arquivos já existentes em outra origem.

**Aceite:** testes do scanner passam; a partir de um botão temporário, importar uma pasta real popula o banco corretamente (conferir com o inspetor do drift ou logs).

---

## Fase 4 — Motor de áudio

- [ ] Configuração Android do audio_service (manifest, `AudioServiceActivity`, permissões, canal de notificação "Reprodução").
- [ ] `audio_session` com preset `speech`.
- [ ] `EchoesAudioHandler`: fila de `MediaItem` por capítulo; `play`, `pause`, `seek`, `skipToNext`, `skipToPrevious` (regra dos 3 s), `skipToQueueItem`, `fastForward`/`rewind` de 15 s; ações da notificação conforme `docs/FEATURES.md` §8; publica `playbackState` e `mediaItem`.
- [ ] Carregar livro com **índice e posição iniciais** no carregamento da fonte (sem timers).
- [ ] `PlaybackController` + providers: livro atual, capítulo atual, posição, duração, tocando, buffering.
- [ ] `ProgressSaver` com todas as regras de `docs/ARCHITECTURE.md` → "Salvar progresso", incluindo `AppLifecycleState`.
- [ ] Reabrir último livro (sem tocar) na inicialização.
- [ ] Fim do último capítulo: pausa e mantém o livro carregado.
- [ ] Testes do `ProgressSaver` e da regra de capítulo anterior com um player fake.

**Aceite (aparelho físico):** tocar, pausar e pular pela notificação e pela tela de bloqueio; bloquear a tela por 10 min e o áudio continua; remover o app do multitarefa e reabrir → volta no capítulo e posição certos (diferença ≤ 10 s); desconectar fone pausa.

---

## Fase 5 — Telas

Seguir `docs/FEATURES.md` e `docs/UI.md` à risca. Ordem:

- [ ] 5.1 Gerenciar biblioteca (botões, banner de progresso, lista de origens, atualizar, remover com confirmação, diálogo de modo).
- [ ] 5.2 Biblioteca: cabeçalho, banner, Continue ouvindo, busca, chips de ordenação, grade responsiva, estado vazio, origem indisponível.
- [ ] 5.3 MiniPlayer (com barra de progresso fina).
- [ ] 5.4 Player: capa, textos, SeekBar, controles, linha de ações, gesto de arrastar para fechar.
- [ ] 5.5 Capítulos e marcadores (com rolagem até o capítulo atual).
- [ ] 5.6 Diálogo de edição de livro (capa via `image_picker` + `CoverStore`, restaurar dados originais).
- [ ] 5.7 Configurações (ordenação + Sobre).

**Aceite:** todos os fluxos de `docs/FEATURES.md` §1–§7 executáveis no aparelho; sem textos fora de `strings.dart`; sem cores fora de `colors.dart`.

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
