---
name: handoff
description: Gera ou atualiza docs/HANDOFF.md, o documento que deixa outra sessão retomar o trabalho exatamente de onde parou, e também retoma uma sessão a partir dele. Use quando o usuário pedir "handoff", "encerrar a sessão", "salvar contexto para outra conversa", "documento de passagem", ou quando pedir para "retomar", "continuar de onde paramos" ou "ler o handoff".
---

# Handoff de sessão

Esta skill tem dois modos. Escolha pelo pedido do usuário:

- **Gerar**: encerrar a sessão, salvar o contexto, criar ou atualizar o handoff.
- **Retomar**: continuar o trabalho, começar uma sessão nova a partir do handoff.

O arquivo é sempre `docs/HANDOFF.md`, escrito em português do Brasil.

---

## Modo Gerar

### 1. Colete os fatos antes de escrever

Não escreva de memória o que dá para verificar. Rode e leia:

```bash
git branch --show-current
git log --oneline -15
git status --short
```

Leia também:
- `docs/PLAN.md`: quais checkboxes estão marcados, qual é a próxima fase e o "Registro de decisões".
- `docs/HANDOFF.md`, se já existir: atualize o documento em vez de começar do zero, e mantenha o que continua verdadeiro.
- `pubspec.yaml`: as dependências atuais.

Rode `flutter analyze` e `flutter test` (com o PATH do Flutter carregado, ver o handoff atual) e registre o resultado real. Se não puder rodar, diga isso no documento.

### 2. Escreva `docs/HANDOFF.md` com esta estrutura exata

```markdown
# Handoff: <título curto e descritivo>

**Data:** <data de hoje, AAAA-MM-DD>
**Status:** <em andamento | bloqueado | aguardando decisão>, mais uma frase sobre a fase atual

## 1. Objetivo
O que está sendo feito e por quê, em 2 a 4 frases.

## 2. Contexto essencial
Stack, ambiente (caminhos do SDK, aparelho de teste, limitações do shell), regras do CLAUDE.md resumidas e uma tabela de decisões já tomadas com seus motivos.

## 3. O que já foi feito
Lista cronológica com o hash de cada commit. Para cada coisa descartada, diga por que foi descartada, com números medidos quando houver.

## 4. Estado atual
Branch, HEAD, working tree, resultado do analyze e do test, o que funciona, o que está quebrado e o que está a meio caminho.

## 5. Próximos passos
Lista ordenada e acionável: arquivos a criar, comandos a rodar e critério de aceite. Marque os passos que dependem do usuário (permissão, download, decisão).

## 6. Perguntas em aberto
Decisões ou investigações pendentes, cada uma com as opções conhecidas.

## 7. Artefatos relevantes
Arquivos-chave, comandos prontos para copiar, snippets, commits de referência (`git show <hash>:<caminho>`) e dados de teste no aparelho.

## 8. Instruções para a próxima sessão
Tom esperado, nível de detalhe e armadilhas conhecidas (cada uma com a forma de evitar).
```

### 3. Regras de conteúdo

- **Fatos verificáveis:** hashes de commit, caminhos absolutos, números medidos (tempos, contagens). Evite "funciona bem" sem um dado.
- **Autossuficiente:** quem lê não viu a conversa. Não escreva "como discutido" nem "o problema de antes"; diga qual problema.
- **Sem dados sensíveis:** não copie e-mail, tokens ou senhas. Para a identidade do git, aponte o comando que a mostra (`git log -1 --format='%an <%ae>'`).
- **Armadilhas:** inclua toda surpresa que custou tempo na sessão, com sintoma e solução.
- **Decisões:** confira se toda decisão que mudou o plano também está no "Registro de decisões" do `docs/PLAN.md`. Se faltar alguma, registre lá também.
- **HEAD:** o handoff descreve o estado do código. Escreva o HEAD anterior ao commit do próprio handoff e diga isso.

### 4. Feche

1. Releia o arquivo e confira os hashes contra `git log`.
2. Faça o commit seguindo o `CLAUDE.md`: `docs: atualizar handoff da sessão (<resumo do estado>)`, com o rodapé de coautoria exigido pela sessão.
3. Diga ao usuário, em poucas linhas, o que o documento cobre e o que depende dele para continuar.

---

## Modo Retomar

1. Leia `docs/HANDOFF.md` inteiro e depois o `CLAUDE.md`.
2. **Confira o handoff contra o repositório.** Rode `git log --oneline -10` e `git status --short`. Se houver commits depois do handoff ou mudanças não commitadas, avise o usuário e leve isso em conta.
3. Leia os documentos que o `CLAUDE.md` manda ler para a fase atual.
4. Responda ao usuário com:
   - onde paramos, em 2 ou 3 linhas;
   - o próximo passo e, se for o início de uma fase, o resumo da abordagem que o `CLAUDE.md` exige;
   - as perguntas em aberto que bloqueiam esse passo.
5. Só comece a implementar depois disso. Se o usuário já pediu para seguir, siga sem pedir confirmação de novo, a menos que haja uma pergunta em aberto que bloqueie o passo.
