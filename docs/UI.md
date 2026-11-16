# Identidade visual — Echoes

A identidade da versão anterior é **mantida**. Este documento consolida os valores que estavam espalhados em classes Tailwind e unifica as inconsistências (dois dourados diferentes, vários cinzas quase iguais).

Tema único **escuro**. Sem tema claro na v1.

## Cores (`lib/app/theme/colors.dart`)

| Token | Hex | Uso |
|---|---|---|
| `background` | `#171614` | Fundo de todas as telas |
| `surface` | `#24221E` | Campo de busca, banners, chips inativos, botões secundários |
| `surfaceAlt` | `#262521` | Placeholder de capa na grade |
| `surfaceDialog` | `#201F1B` | Fundo de diálogos e folhas inferiores |
| `coverPlaceholder` | `#292720` | Placeholder da capa grande do Player |
| `border` | `#393833` | Bordas e divisores padrão |
| `borderStrong` | `#46443E` | Botões de ícone do cabeçalho, borda de diálogo |
| `borderAccent` | `#514731` | Botões de importação |
| `textPrimary` | `#D5D4CF` | Títulos e texto principal |
| `textHeading` | `#C9C8C2` | Títulos de seção ("Biblioteca", "Continue ouvindo") |
| `textSecondary` | `#AAA9A3` | Subtítulos, ícones de navegação |
| `textMuted` | `#85857F` | Metadados, numeração, tempos |
| `textPlaceholder` | `#8E8E87` | Placeholder de inputs |
| `accent` | `#D1AA65` | Dourado: ícones de destaque, item atual, spinners, slider, barras de progresso |
| `accentFill` | `#80683F` | Fundo de botão primário e chip ativo |
| `onAccent` | `#F0EEE7` | Texto sobre `accentFill` |
| `iconOnDark` | `#FAFAFA` | Controles do Player e play/pause do MiniPlayer |
| `track` | `#3A3935` | Trilho inativo de slider e barras de progresso |
| `miniPlayerBg` | `#0A0A0A` @ 85% | Fundo do MiniPlayer |
| `scrim` | `#000000` @ 75% | Fundo atrás de diálogos |

**Unificações em relação à versão antiga:** o dourado `#D4A017` do slider e da barra de progresso passa a ser `accent` (`#D1AA65`); o trilho cinza-claro `#D4D4D4` passa a ser `track` (escuro), mais coerente com o tema.

## Tipografia (`lib/app/theme/typography.dart`)

- **Cormorant Garamond** (serifada) para títulos: 400, 500, 700 — empacotada em `assets/fonts/`.
- **Fonte do sistema** (Roboto) para todo o resto.

| Estilo | Fonte | Tamanho | Peso | Uso |
|---|---|---|---|---|
| `display` | Cormorant | 48 | 700 | "Echoes" no cabeçalho |
| `screenTitle` | Cormorant | 30 | 700 | Títulos de tela, título do livro no Player |
| `sectionTitle` | Cormorant | 24 | 700 | "Continue ouvindo", "Biblioteca", título de diálogo |
| `subsectionTitle` | Cormorant | 20 | 700 | Títulos de grupo em Configurações |
| `overline` | Sistema | 13 | 500, caixa alta, letter-spacing 2 | "CAPÍTULOS", "MARCADORES SALVOS" |
| `body` | Sistema | 16 | 400 | Texto padrão, itens de lista |
| `bodySmall` | Sistema | 14 | 400/500 | Título de livro na grade, subtítulos |
| `caption` | Sistema | 12 | 400 | Metadados, tempos |

## Forma e espaçamento

- Padding horizontal das telas: 20 (36 quando largura > 700).
- Raios: capa na grade 12 · capa grande 12 · campos e botões 12 · chips 999 · diálogo 16 · MiniPlayer 16 · capa pequena 6.
- Divisores: 1px `border` entre itens de lista.
- Botão de ícone do cabeçalho: 44×44, borda `borderStrong`, raio 12, ícone 20 `accent`.

## Ícones (`ionicons`)

| Onde | Ícone |
|---|---|
| Gerenciar biblioteca | `library-outline` |
| Configurações | `settings-outline` |
| Busca | `search` |
| Estado vazio | `headset-outline` |
| Sem capa (grade/Player) | `book-outline` |
| Sem capa (MiniPlayer/Continue ouvindo) | `image-outline` |
| Fechar Player | `chevron-down` |
| Voltar | `arrow-back` |
| Capítulo anterior / próximo | `play-skip-back` / `play-skip-forward` |
| Voltar / avançar 15 s | `play-back` / `play-forward` |
| Play / pause | `play-circle` / `pause-circle` (72 no Player, 48 no MiniPlayer) |
| Timer | `moon-outline` |
| Marcador | `bookmark-outline` → `bookmark` quando salvo |
| Capítulos | `list-outline` |
| Adicionar pasta / arquivos | `folder-open-outline` / `musical-notes-outline` |
| Origem pasta / arquivos | `folder-outline` / `musical-notes-outline` |
| Atualizar / remover | `refresh-outline` / `trash-outline` |
| Tocando agora | `stats-chart` (substitui o `equalizer` do Material) |
| Ouvido recentemente | `time` |
| Radio | `radio-button-on` / `radio-button-off` |

## Componentes

- **BookGridItem:** capa 3:4 → título → autor → detalhe. Opacidade 0.75 ao pressionar.
- **ContinueListeningItem:** linha de 80 de altura, capa 64, texto + barra de progresso de 4px (`accent` sobre `track`), ícone de status à direita, divisor inferior.
- **SeekBar:** trilho 5px, thumb 16px `accent`; tempos `caption` `textMuted`.
- **MiniPlayer:** posição absoluta, margem 16 laterais e 24 inferior, sombra difusa preta 60%, borda 1px `#404040` @ 50%.
- **ImportStatusBanner:** fundo `surface`, borda `border`, raio 8, spinner pequeno `accent`, texto 14 `textSecondary`.
- **Chips de ordenação:** ativo `accentFill`/`onAccent`, inativo `surface`/`textSecondary`.
- **Diálogos:** `surfaceDialog`, borda `borderStrong`, raio 16, padding 20; botão primário `accentFill`, secundário só texto `textSecondary`.

## Movimento

- Player entra deslizando de baixo; sai deslizando para baixo (mesma animação no gesto de arrastar).
- Telas secundárias (Gerenciar, Configurações, Capítulos) entram da direita.
- Biblioteca não anima ao abrir.
