# Especificação funcional — Echoes (Flutter)

Comportamento esperado de cada parte do app. Paridade com a versão React Native, com as correções indicadas como **(novo)**.
Textos entre aspas são os textos de UI exatos (vão para `lib/app/strings.dart`).

---

## 1. Importação

### 1.1 Adicionar pasta
1. Abre o seletor de pasta do sistema (SAF). Cancelar → nada acontece.
2. Diálogo **"Como organizar esta pasta?"** — "Escolha como os arquivos de áudio devem virar livros."
   - "A pasta inteira é um livro" → `oneBook`
   - "Cada pasta é um livro" → `booksInFolders`
   - "Cancelar"
3. Banner de progresso com spinner: "Preparando leitura da pasta…", "Lendo pasta X de Y…" ou "Lendo N arquivo(s) de áudio…", "Salvando livros na biblioteca…".
4. Nenhum livro novo → alerta "Nenhum arquivo novo encontrado" / "Esta pasta não contém áudio compatível que ainda não esteja na biblioteca."
5. Erro → "Não foi possível importar a pasta" / "Verifique o acesso à pasta e tente selecioná-la novamente."

### 1.2 Adicionar arquivos
- Seletor de múltiplos arquivos de áudio. Todos os arquivos selecionados viram **um** livro, origem `files:<epochMs>`. Em Gerenciar, a origem aparece com o título atual do livro **(novo — antes todas se chamavam "Arquivos selecionados", que continua como nome de reserva)**.
- Nenhum áudio → "Nenhum áudio selecionado" / "Escolha arquivos MP3, M4A ou M4B."
- Todos já existem → "Arquivos já adicionados" / "Todos os arquivos selecionados já estão na biblioteca."
- Erro → "Não foi possível adicionar os arquivos" / "Escolha novamente os arquivos de áudio."

### 1.3 Regras de leitura
- Formatos de áudio: `.mp3`, `.m4a`, `.m4b` (case-insensitive).
- Imagens consideradas: `.jpg`, `.jpeg`, `.png`, `.webp`.
- **Ordem das faixas:** se ambos os nomes começam com número de faixa (`^\s*(track\s*)?(\d{1,3})[\s._-]|$`), ordena pelo número, desempate natural; arquivos numerados antes dos não numerados; resto por ordenação natural.
- **Título do capítulo:** tag `title` → nome do arquivo sem extensão, sem número inicial, `._` trocados por espaço.
- **Número da faixa:** tag `track` → número no nome.
- **Título do livro:** tag `album` (primeiro arquivo que tiver album/artist/albumartist) → nome da pasta → título limpo do primeiro arquivo.
- **Autor:** `albumartist` → `artist` → vazio.
- **Capa, nesta prioridade:** imagem da pasta com nome `cover|folder|front|artwork|album` → capa embutida no primeiro arquivo que tiver → primeira imagem da pasta (ordem natural).
- **Duração:** dos metadados; a do livro é a soma.
- Arquivo com metadado ilegível não quebra a importação: usa os fallbacks de nome e fica sem duração.

### 1.4 Atualizar origem
- Disponível só para origens `folder`. Reescaneia com o `importMode` salvo.
- Permissão perdida → "Acesso à pasta expirou" / "Selecione novamente a pasta original para atualizar este audiobook."

### 1.5 Remover origem
- Confirmação: **"Remover origem?"** — "Remover “{nome}” e seus livros da biblioteca? Os arquivos originais não serão apagados." — "Cancelar" / "Remover" (destrutivo).
- Remove livros, capítulos, progresso, marcadores, capas e libera a permissão SAF **(novo)**.
- Se o livro removido estiver tocando: para o player e esconde o MiniPlayer **(novo)**.

---

## 2. Biblioteca (tela inicial)

- Cabeçalho: "Echoes" (Cormorant 700, grande) + dois botões quadrados com ícone: Gerenciar biblioteca (`library-outline`) e Configurações (`settings-outline`).
- Banner de importação (mesmo da tela de gerenciar) quando houver importação em andamento.
- **"Continue ouvindo"**: até 3 livros com `lastPlayedAt`, mais recentes primeiro. Cada item: capa 64px, título, autor ("Autor desconhecido"), barra de progresso do livro inteiro e, à direita, ícone `equalizer` dourado se for o livro tocando agora, senão ícone de relógio. Toque → abre o livro e vai para o Player.
  - Progresso = (soma das durações dos capítulos anteriores + posição) / duração total. Sem durações → índice do capítulo / quantidade de capítulos.
- Campo de busca: "Buscar título ou autor", filtra por título + autor.
- Título "Biblioteca" + chips de ordenação "Recentes" / "Título" (salvo em settings).
- **Grade:** 2 colunas (largura ≤ 620), 4 (≤ 900), 5 (> 900). Item: capa 3:4 com cantos 12, título (1 linha, "Sem título"), autor (1 linha), linha de detalhe: "{n} capítulos · 5h 03m" ou "Pasta indisponível".
  - Toque → abre o livro e vai para o Player. Se a origem estiver indisponível → leva para Gerenciar biblioteca com uma mensagem para atualizar a pasta **(novo — antes abria o seletor direto)**.
  - Toque longo → diálogo de edição.
- Estado vazio: ícone `headset-outline`; "Nenhum audiobook" + texto orientando a adicionar uma pasta, com botão que leva a Gerenciar biblioteca. Com busca sem resultado: "Nenhum resultado".
- MiniPlayer fixo no rodapé quando houver livro carregado; conteúdo ganha padding inferior para não ficar escondido.

### 2.1 Editar audiobook (diálogo)
- "Editar audiobook"; capa 112×144 clicável com faixa "Alterar capa"; campos "Título" e "Autor"; "Cancelar" / "Salvar" (dourado, com spinner).
- Salvar desabilitado com título vazio.
- **(novo)** Opção "Restaurar dados originais" que limpa os campos `custom*`.

---

## 3. Player

- Abre de baixo para cima; fecha com o chevron para baixo ou **arrastando para baixo** (> 120px ou velocidade alta), com a tela acompanhando o dedo.
- Topo: chevron-down, autor centralizado (ou "Audiobook").
- Capa grande quadrada (min(largura − 64, 45% da altura), máx 480), cantos 12; sem capa → ícone `book-outline`.
- Título do livro (Cormorant 700, até 2 linhas), nome do capítulo, "Capítulo X de Y".
- **Barra de progresso do capítulo:** arrastar não move o áudio até soltar; tempo decorrido à esquerda e restante ("-03:21") à direita.
- **Controles:** capítulo anterior · voltar 15 s · play/pause grande · avançar 15 s · próximo capítulo.
  - Capítulo anterior: se posição > 3 s, volta ao início do capítulo; senão vai para o anterior; no primeiro capítulo volta ao início **(novo — regra dos 3 s)**.
  - Próximo capítulo: desabilitado no último.
- **Linha de ações:** Temporizador (`moon-outline`, dourado quando ativo, texto "Timer ativo"), Marcador (feedback "Salvo" por 1,5 s), Capítulos (abre a tela de capítulos).
- Com timer ativo, a folha do Temporizador ganha "Desligar temporizador" **(novo — antes era uma linha "Cancelar temporizador" abaixo das ações, fora da tela sem rolar)**.
- O Player cabe numa tela, sem rolagem: a capa encolhe para o espaço que sobrar **(novo)**. Só rola em telas baixas (paisagem, fonte grande).
- Fim do último capítulo: pausa, mantém o livro carregado no fim **(novo — comportamento explícito)**.

### 3.1 Timer de sono
Folha inferior "Temporizador" — "Quando deseja pausar?": 15, 30, 45, 60 minutos, "Ao fim do capítulo", "Cancelar".
- Por minutos: pausa quando o tempo acaba. **(novo)** Mostra o tempo restante no botão ("Timer · 12 min").
- Fim do capítulo: pausa quando o capítulo em que foi ativado termina.
- Pausar manualmente **não** cancela o timer; ele só é zerado ao disparar ou ao ser cancelado.

---

## 4. MiniPlayer

- Flutuante no rodapé (margem 16, cantos 16, borda sutil, sombra), fundo quase preto translúcido.
- Capa 56px, título do livro, nome do capítulo, botão play/pause grande.
- Toque no corpo → abre o Player; toque no botão → só alterna play/pause.
- **(novo)** Barra fina de progresso do capítulo na base do MiniPlayer.

---

## 5. Capítulos e marcadores

- Cabeçalho com voltar, título do livro e subtítulo "Capítulos e marcadores".
- Seção "CAPÍTULOS" (dourado, caixa alta, espaçado): número com 2 dígitos, nome (dourado se for o atual), duração à direita. Toque → toca esse capítulo do início e volta ao Player.
- **(novo)** A lista rola automaticamente até o capítulo atual ao abrir.
- Seção "MARCADORES SALVOS": vazio → "Os marcadores aparecem aqui." Cada item: nome do capítulo ("Capítulo removido" se não existir mais), tempo e data; toque → vai ao capítulo e posição e volta ao Player; ícone de lixeira remove.

---

## 6. Gerenciar biblioteca

- Voltar + "Gerenciar biblioteca".
- Dois botões lado a lado: "Adicionar pasta" (`folder-open-outline`) e "Adicionar arquivos" (`musical-notes-outline`), desabilitados durante importação.
- Banner de progresso da importação.
- "Pastas e arquivos adicionados": vazio → "Nenhuma origem adicionada. Escolha uma pasta ou arquivos acima."
- Cada origem: ícone (pasta ou notas), nome, "{n} livro(s) · disponível|acesso indisponível", botão atualizar (só pastas) e remover.

---

## 7. Configurações

- "Ordem da biblioteca" — "Escolha como os audiobooks aparecem ao abrir o app." — radios "Mais recentes" / "Título".
- **(novo)** Seção "Sobre": versão do app.

---

## 8. Comportamentos de sistema

- Notificação / tela de bloqueio: capa, nome do capítulo (título), autor (artista), título do livro (álbum); ações: anterior, voltar 15 s, play/pause, avançar 15 s, próximo; no modo compacto: voltar 15 s, play/pause, avançar 15 s.
- Botões de fone: play/pause; duplo/triplo toque → próximo/anterior (padrão do audio_service).
- Fone desconectado → pausa. Ligação → pausa e retoma ao fim se o sistema permitir (audio_session `speech`).
- Ao abrir o app: reabre o último livro sem tocar.
- Progresso nunca é perdido ao fechar o app pelo multitarefa (salva em `paused`/`detached` e a cada 10 s).

---

## 9. Fora do escopo da paridade (Fase 7 — opcionais, só depois de tudo acima)

1. Velocidade de reprodução (0,8× a 2,0×), salva por livro.
2. Capítulos internos de arquivos M4B (um arquivo → vários capítulos via `startMs`/`endMs`).
3. Marcar livro como concluído / filtrar concluídos.
