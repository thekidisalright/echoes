# Modelo de dados — Echoes (Flutter)

Banco SQLite via **drift**, arquivo `echoes.sqlite` no diretório de suporte do app.
Schema começa na **versão 1** (sem migração da versão React Native). Toda mudança futura incrementa `schemaVersion` e ganha um passo de migração no drift.

## Convenções

- Tempos: `int` em **milissegundos** (`durationMs`, `positionMs`) e timestamps em **epoch ms** (`createdAt`, `lastPlayedAt`).
- IDs são `TEXT` estáveis derivados da origem (ver abaixo), para que reimportar a mesma pasta atualize em vez de duplicar.
- `ON DELETE CASCADE` em todas as chaves estrangeiras; `PRAGMA foreign_keys = ON` na abertura.

## Tabelas

### `sources` — origens importadas
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | TEXT PK | URI da árvore SAF (pasta) ou `files:<epochMs>` (arquivos soltos) |
| `uri` | TEXT | URI SAF da pasta; para `files:` é igual ao id |
| `name` | TEXT | nome exibido da pasta / "Arquivos selecionados" |
| `kind` | TEXT | `folder` \| `files` |
| `importMode` | TEXT NULL | `oneBook` \| `booksInFolders` (só para `folder`) |
| `available` | BOOL | permissão SAF ainda válida |
| `lastScannedAt` | INT | epoch ms |

### `books`
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | TEXT PK | URI do diretório do livro; em `oneBook` e em `files`, igual ao `sources.id` |
| `sourceId` | TEXT FK → sources | cascade |
| `scannedTitle` | TEXT | vindo de tags/pasta, sobrescrito a cada reimportação |
| `scannedAuthor` | TEXT | idem, pode ser vazio |
| `scannedCoverPath` | TEXT NULL | caminho local da capa extraída |
| `customTitle` | TEXT NULL | edição do usuário — **nunca** sobrescrita por reimportação |
| `customAuthor` | TEXT NULL | idem |
| `customCoverPath` | TEXT NULL | idem |
| `totalDurationMs` | INT NULL | soma das durações dos capítulos |
| `chapterCount` | INT | denormalizado para a grade não precisar de JOIN em capítulos |
| `lastPlayedAt` | INT NULL | |
| `createdAt` | INT | |

Valor exibido = `custom* ?? scanned*`. Isso substitui o antigo `coverCustomized` + `*Override`.

### `chapters`
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | TEXT PK | URI do arquivo; para capítulos internos de M4B (Fase 7): `<uri>#<índice>` |
| `bookId` | TEXT FK → books | cascade |
| `title` | TEXT | tag `title` → nome do arquivo limpo |
| `uri` | TEXT | URI SAF do arquivo |
| `sortOrder` | INT | posição na fila |
| `trackNumber` | INT NULL | |
| `durationMs` | INT NULL | |
| `startMs` | INT NULL | reservado para capítulos internos de M4B |
| `endMs` | INT NULL | idem |

Índice: `(bookId, sortOrder)`.

### `progress` — uma linha por livro
| Coluna | Tipo | Notas |
|---|---|---|
| `bookId` | TEXT PK FK → books | cascade |
| `chapterId` | TEXT | capítulo atual |
| `positionMs` | INT | posição dentro do capítulo |
| `updatedAt` | INT | |

### `bookmarks`
| Coluna | Tipo | Notas |
|---|---|---|
| `id` | INT PK autoincrement | |
| `bookId` | TEXT FK → books | cascade |
| `chapterId` | TEXT | |
| `positionMs` | INT | |
| `createdAt` | INT | |

### `settings` — chave/valor
| Chave | Valor |
|---|---|
| `lastPlayedBookId` | id do último livro aberto |
| `librarySort` | `recent` \| `title` |

## Regras de persistência

### Reimportar uma origem (`saveScannedSource`) — numa única transação
1. Upsert em `sources`.
2. Para cada livro escaneado: upsert atualizando **apenas** campos `scanned*`, `totalDurationMs`, `chapterCount`. Campos `custom*`, `lastPlayedAt` e `createdAt` são preservados.
3. Para cada livro: upsert dos capítulos; apaga capítulos daquele livro que não vieram no scan.
4. Apaga livros da origem que não vieram no scan (cascade leva capítulos, progresso e marcadores).
5. Se o `progress.chapterId` de um livro não existe mais, reposiciona no primeiro capítulo, posição 0.

### Evitar duplicatas
Ao importar, URIs de arquivos que já pertencem a **outra** origem são ignoradas (mesma regra da versão antiga).

### Remover origem
`DELETE FROM sources WHERE id = ?` → cascade. Depois: liberar a permissão SAF persistida e apagar arquivos de capa órfãos via `CoverStore`.

## Consultas que a UI observa (streams)

| Consulta | Usada em | Forma |
|---|---|---|
| `watchLibrary(query, sort)` | Grade da biblioteca | `books` + `progress` + `sources.available`, **sem** capítulos |
| `watchContinueListening()` | "Continue ouvindo" | top 3 por `lastPlayedAt` não nulo, com progresso + soma das durações dos capítulos anteriores ao atual (para a barra) |
| `watchSources()` | Gerenciar biblioteca | `sources` + contagem de livros |
| `chaptersOf(bookId)` | Player, capítulos | lista ordenada |
| `watchBookmarks(bookId)` | Capítulos/marcadores | mais recentes primeiro |

Busca: `LIKE` case-insensitive em título e autor exibidos. Ordenação por título: feita em Dart com natural sort (o `COLLATE NOCASE` do SQLite não faz ordenação natural de números).

## Capas (`CoverStore`)

- Diretório: `<applicationSupportDirectory>/covers/`.
- Nome: `sha1(bookId).<ext>` para capas escaneadas; `custom_<sha1(bookId)>_<epochMs>.<ext>` para capas escolhidas pelo usuário (o timestamp invalida o cache de imagem).
- Capa escaneada é sempre **copiada** para o diretório do app (mesmo quando vem de `cover.jpg` da pasta), para não depender de permissão SAF para exibir.
- Ao trocar ou remover, o arquivo anterior é apagado.
