# Echoes

Player de audiobooks pessoal para Android, focado em arquivos locais (MP3, M4A, M4B).
Esta branch (`flutter-rewrite`) é a **reconstrução completa do app em Flutter**, substituindo a versão React Native/Expo que vive na branch `main`.

## Status

🚧 Em reconstrução. Acompanhe o progresso em [`docs/PLAN.md`](docs/PLAN.md).

## O que o Echoes faz

- Importa audiobooks a partir de **pastas** (cada pasta é um livro, ou a pasta inteira é um livro) ou de **arquivos soltos**.
- Lê metadados (título, autor, faixa, duração) e capa — embutida no arquivo ou `cover.jpg` / `folder.jpg` da pasta.
- Toca em segundo plano com controles na notificação e na tela de bloqueio.
- Salva o progresso automaticamente e retoma de onde parou.
- "Continue ouvindo", busca, ordenação, edição de título/autor/capa.
- Marcadores, lista de capítulos e timer de sono.

## Stack

| Camada | Tecnologia |
|---|---|
| UI | Flutter (Material 3, tema escuro próprio) |
| Estado | Riverpod |
| Navegação | go_router |
| Áudio | just_audio + audio_service + audio_session |
| Arquivos | Storage Access Framework (docman) |
| Metadados | metadata_audio (fallback: flutter_taglib) |
| Banco | drift (SQLite) |

Detalhes e justificativas em [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Documentação

| Documento | Conteúdo |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Regras de trabalho para o Claude Code neste repositório |
| [`docs/PLAN.md`](docs/PLAN.md) | Plano de execução em fases, com critérios de aceite |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Arquitetura, camadas, pacotes e fluxos principais |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | Schema do banco, IDs, regras de persistência |
| [`docs/FEATURES.md`](docs/FEATURES.md) | Especificação funcional de cada tela e comportamento |
| [`docs/UI.md`](docs/UI.md) | Identidade visual: cores, tipografia, componentes |

## Rodando o projeto

Pré-requisitos: Flutter SDK estável, Android SDK, um dispositivo ou emulador Android.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # gera código do drift
flutter run
```

Verificações:

```bash
flutter analyze
flutter test
```

## Versão anterior

A versão React Native/Expo continua na branch `main` como referência de comportamento. Para consultar um arquivo antigo sem trocar de branch:

```bash
git show main:contexts/LibraryContext.tsx
```
