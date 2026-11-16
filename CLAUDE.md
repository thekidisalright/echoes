# CLAUDE.md — Echoes (Flutter)

Instruções para o Claude Code trabalhar neste repositório.

## Contexto

Echoes é um player de audiobooks pessoal, **apenas Android**, para arquivos locais.
Esta branch (`flutter-rewrite`) recria do zero em Flutter o app que existia em React Native/Expo (branch `main`).
Não há migração de dados: o app novo começa com a biblioteca vazia.

Antes de qualquer trabalho, leia nesta ordem:
1. `docs/PLAN.md` — o que fazer e em que ordem
2. `docs/ARCHITECTURE.md` — onde cada coisa mora
3. `docs/FEATURES.md` e `docs/UI.md` — quando for mexer em tela
4. `docs/DATA_MODEL.md` — quando for mexer em banco

## Como trabalhar

- **Siga as fases de `docs/PLAN.md` em ordem.** Não pule para UI antes da fase de áudio estar funcionando.
- **Antes de começar uma fase, resuma em poucas linhas a abordagem** (arquivos que vai criar, decisões não óbvias) e só então implemente.
- Ao concluir uma tarefa, marque o checkbox correspondente em `docs/PLAN.md`.
- Um commit por tarefa ou grupo coeso de tarefas, mensagens no padrão Conventional Commits em português:
  `feat(player): retomar posição ao abrir livro`, `fix(import): ...`, `chore: ...`, `docs: ...`.
- Se uma decisão do plano se mostrar inviável (ex.: pacote não funciona com URIs `content://`), **pare, explique o problema e proponha alternativa** antes de trocar. Depois registre a decisão na seção "Registro de decisões" de `docs/PLAN.md`.
- Para lembrar como algo funcionava na versão antiga: `git show main:<caminho>` (ex.: `git show main:contexts/PlayerContext.tsx`). Use como referência de **comportamento**, nunca como modelo de estrutura.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze          # deve ficar sem issues
flutter test             # deve passar
flutter run              # dispositivo Android
```

Rode `flutter analyze` e `flutter test` antes de cada commit.

## Regras de arquitetura (não negociáveis)

1. **Feature-first.** Código de uma funcionalidade vive em `lib/features/<feature>/` com subpastas `data/`, `domain/`, `presentation/`.
2. **Widgets nunca acessam banco, SAF, metadados ou o player diretamente.** Fluxo obrigatório:
   `widget → provider (Riverpod) → repository/service → drift | SAF | metadata | AudioHandler`.
3. **Domínio puro.** Classes em `domain/` não importam Flutter, drift, nem pacotes de plataforma.
4. **Serviços de plataforma ficam atrás de uma interface em `lib/core/`** (`StorageGateway`, `MetadataReader`). Isso permite trocar o pacote e testar com fakes.
5. **Nada de `Future.delayed` / timers para "esperar o player".** Use os streams e o estado de processamento do just_audio.
6. **Diálogos e mensagens são responsabilidade da UI.** Serviços retornam resultados ou lançam exceções tipadas; nunca abrem diálogos.
7. **Banco reativo.** Listas da UI vêm de `watch` do drift (streams). Não existe "refresh manual" da biblioteca.
8. Tempos são sempre armazenados em **milissegundos (`int`)** e tratados como `Duration` no domínio.

## Convenções

- Identificadores de código em **inglês**; textos de UI em **português do Brasil**.
- Todos os textos de UI centralizados em `lib/app/strings.dart` (sem i18n na v1, mas sem strings soltas nos widgets).
- Cores, fontes e espaçamentos só via `lib/app/theme/` — nenhum `Color(0x...)` solto em widget.
- Lints: `flutter_lints` + regras extras definidas em `analysis_options.yaml`.
- Nomes de arquivos em `snake_case.dart`, um widget público principal por arquivo.
- Pacotes: adicione com `flutter pub add <pacote>` (pega a versão estável atual). Se adicionar um pacote que não está listado em `docs/ARCHITECTURE.md`, atualize o documento.

## O que NÃO fazer

- Não suportar iOS, web ou desktop nesta versão (não remova as pastas geradas, apenas não invista nelas).
- Não pedir permissões amplas de armazenamento (`MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`). Todo acesso a arquivos é via SAF.
- Não salvar imagens em base64 no banco. Capas são arquivos no diretório do app.
- Não adicionar funcionalidades fora do plano sem perguntar.
