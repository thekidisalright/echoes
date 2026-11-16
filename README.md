# Echoes

Um player de audiobooks para Android, feito para os livros que você já tem no celular.

Escolha a pasta onde estão os seus audiobooks (MP3, M4A ou M4B) e o Echoes organiza a biblioteca, mostra as capas e lembra onde você parou em cada livro. Sem conta, sem assinatura e sem internet.

## O que ele faz

- **Monta a biblioteca sozinho** a partir das suas pastas, com título, autor, capa e capítulos.
- **Lembra onde você parou** em cada livro, até no meio de um capítulo.
- **Toca em segundo plano**, com controles na notificação e na tela de bloqueio.
- **Continue ouvindo:** os últimos livros que você ouviu ficam no topo da biblioteca.
- **Marcadores** para guardar trechos e voltar a eles depois.
- **Timer de sono** que pausa depois de 15, 30, 45 ou 60 minutos, ou no fim do capítulo.
- **Busca e ordenação** por título ou pelos mais recentes.
- **Edição** de título, autor e capa quando os dados do arquivo vierem errados.

## Instalação

Requer **Android 7.0 ou mais recente** (celular com processador de 64 bits, como quase todos os atuais).

1. Abra a página de [versões do Echoes](https://github.com/thekidisalright/echoes/releases/latest) no celular.
2. Baixe o arquivo `.apk` da versão mais recente.
3. Toque no arquivo baixado. Se o Android pedir, permita que o navegador ou o gerenciador de arquivos **instale apps desconhecidos**.
4. Toque em **Instalar**.

O Echoes não está na Play Store. Por isso o Android pode mostrar um aviso do Play Protect na instalação. Os arquivos de cada versão ficam publicados aqui no GitHub.

## Primeiros passos

### 1. Adicione seus audiobooks

Na tela inicial, toque no botão de **Gerenciar biblioteca** (o ícone de estante) e escolha uma das opções.

**Adicionar pasta.** Escolha a pasta onde estão os audiobooks. O Echoes pergunta como a pasta está organizada:

- **Cada pasta é um livro:** para quando cada audiobook tem a sua própria subpasta.
  ```
  Audiobooks/
  ├── Dom Casmurro/        → um livro
  │   ├── 01.mp3
  │   └── 02.mp3
  └── O Cortiço/           → outro livro
      └── ...
  ```
- **A pasta inteira é um livro:** para quando a pasta escolhida contém um único audiobook, com todos os arquivos dele.

**Adicionar arquivos.** Escolha um ou mais arquivos de áudio. Eles viram um único livro.

A leitura de uma pasta grande pode levar alguns segundos, e um aviso no topo da tela mostra o andamento.

### 2. Ouça

Toque num livro para abrir o player. O livro abre no ponto em que você parou, e você toca em ▶ para continuar.

- **Voltar ou avançar 15 segundos** pelos botões ao lado do play.
- **Capítulo anterior:** se você já passou dos 3 primeiros segundos, o botão volta ao início do capítulo atual.
- **Fechar o player:** arraste a tela para baixo ou toque na seta no topo. O livro continua tocando, com um mini player no rodapé da biblioteca.

Abaixo dos controles ficam três botões:

- **Temporizador:** escolha quando pausar. O botão mostra o tempo restante ("Timer · 12 min"). Para desligar, toque nele de novo e escolha **Desligar temporizador**.
- **Marcador:** guarda o ponto atual. Aparece "Salvo" por um instante.
- **Capítulos:** lista os capítulos (toque para ir a um deles) e, na outra aba, os seus marcadores (toque para voltar ao trecho ou na lixeira para apagar).

### 3. Organize

- **Buscar:** digite parte do título ou do autor no campo de busca.
- **Ordenar:** use **Recentes** ou **Título** acima da grade. A escolha fica salva.
- **Editar um livro:** toque e segure a capa na biblioteca para mudar o título, o autor ou a imagem da capa.
- **Atualizar uma pasta:** se você adicionou ou apagou arquivos, toque em atualizar ao lado da pasta em Gerenciar biblioteca. As suas edições e o seu progresso são mantidos.
- **Remover uma pasta:** toque na lixeira ao lado dela em Gerenciar biblioteca. Isso tira os livros do Echoes, mas **não apaga os seus arquivos**.

## Perguntas frequentes

**Quais formatos são aceitos?**
MP3, M4A e M4B.

**De onde vêm o título, o autor e a capa?**
Das informações gravadas nos próprios arquivos de áudio. Quando elas não existem, o título vem do nome da pasta ou do arquivo. A capa pode vir de uma imagem na pasta (como `cover.jpg` ou `folder.jpg`) ou da capa embutida no arquivo. Se algo vier errado, toque e segure o livro para corrigir.

**O Echoes copia, move ou apaga os meus arquivos?**
Não. Ele só lê as pastas que você escolhe, e os arquivos continuam onde estão.

**Por que um livro aparece como "Pasta indisponível" ou "acesso indisponível"?**
O Echoes perdeu o acesso à pasta, por exemplo porque ela foi renomeada, movida ou estava num cartão de memória removido. Volte a pasta para o lugar ou adicione-a de novo em Gerenciar biblioteca.

**Em que ordem os capítulos tocam?**
Pelo número da faixa: o gravado no arquivo ou, na falta dele, o número no início do nome (`01`, `02`…). Os demais arquivos vêm depois, em ordem alfabética.

**O meu progresso fica salvo se eu desinstalar o app?**
Não. A biblioteca, o progresso e os marcadores ficam guardados só dentro do app. Os arquivos de áudio não são afetados.

## Privacidade

O Echoes não pede permissão de internet, não tem conta e não coleta dados. Ele lê apenas as pastas e os arquivos que você escolhe, pelo seletor do próprio Android, sem acesso amplo ao armazenamento. A permissão de notificações serve só para mostrar os controles de reprodução.

---

## Para desenvolvedores

App Android em **Flutter**, com Riverpod, go_router, drift (SQLite) e just_audio + audio_service. Os arquivos são acessados pelo Storage Access Framework.

```bash
flutter pub get
dart run build_runner build      # gera o código do drift
flutter analyze
flutter test
flutter run
```

Para gerar o APK assinado, crie `android/key.properties` (fora do git) com `storeFile`, `storePassword`, `keyAlias` e `keyPassword`. Sem esse arquivo, o build release usa a chave de debug.

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64
```

| Documento | Conteúdo |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Arquitetura, camadas, pacotes e fluxos |
| [`docs/FEATURES.md`](docs/FEATURES.md) | Comportamento de cada tela |
| [`docs/UI.md`](docs/UI.md) | Cores, tipografia e componentes |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | Esquema do banco |
| [`docs/PLAN.md`](docs/PLAN.md) | Plano em fases e registro de decisões |
| [`CLAUDE.md`](CLAUDE.md) | Regras de trabalho para o Claude Code |

A versão anterior, em React Native/Expo, está na tag `rn-legacy`:

```bash
git show rn-legacy:contexts/LibraryContext.tsx
```
