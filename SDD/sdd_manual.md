# Manual Definitivo: Spec Driven Development (SDD) com IA

Este manual descreve o fluxo de trabalho profissional para o desenvolvimento de software utilizando assistentes de IA (como Claude Code, Cursor, etc.). O objetivo do SDD é eliminar o caos do "Vibe Coding" (tentativa e erro desenfreada) através do isolamento de contexto, planejamento rigoroso e arquitetura modular.

---

## Princípios Fundamentais

1. **A Batalha do Context Window:** A memória de curto prazo da IA tem limites. Passar de 40%-50% da capacidade gera alucinações, amnésia e código "espaguete". A regra de ouro é: **Limpar o contexto a cada mudança de fase**.
2. **Input Limpo = Output Limpo:** Nunca envie documentação inútil ou código inteiro se apenas um trecho é necessário.
3. **Isolamento de Responsabilidades:** Funcionalidades diferentes vivem em pastas diferentes. O Front-end (Client) **nunca** guarda regras de negócio ou chaves de API; isso é trabalho exclusivo do Back-end (Server).

---

## FASE 0: A Fundação (Setup do Projeto)

Antes de gerar qualquer linha de código, a IA precisa de um "norte" arquitetural.

1. Crie uma pasta raiz chamada `/references`.
2. Dentro dela, crie documentos de diretrizes do seu projeto. Os mais importantes são:
   * **`architecture.md`**: Define como as pastas se estruturam (ex: separação por comportamentos), padrões de nomenclatura, e as regras estritas de segurança (ex: *Thin Client, Fat Server*).
   * **`design_system.md`**: Define paleta de cores, bibliotecas visuais (ex: Tailwind, Shadcn) e padrões de interface.
   * **`workflow.md`**: (Opcional) Instrui a própria IA sobre como ela deve operar.
3. **Objetivo:** Sempre que a IA for programar, ela deve consultar a pasta `/references` para não tomar decisões que quebrem a estrutura do projeto.

---

## 🗺️ FASE 1: O Escopo Macro (Planejamento Global)

Aqui você diz à IA o que o sistema é no nível macro, mas ainda não pede para ela programar.

### 1.1 Geração da Especificação Global (`/spec`)
* **Ação:** Descreva em linguagem natural a sua ideia de aplicativo/sistema e peça para a IA gerar uma Spec Macro.
* **Output esperado (Arquivo `spec.md` ou equivalente):**
  * Resumo do projeto.
  * Lista de todas as **Páginas** do app.
  * Lista de todos os **Componentes** (UI) em cada página.
  * Lista de todos os **Comportamentos/Behaviors** (O que o usuário pode fazer: ex: login, recuperar senha, enviar mensagem).

### 1.2 Fatiamento de Tarefas (`/break`)
* **Ação:** Entregue o arquivo gerado no passo anterior para a IA e ordene que ela o quebre em tarefas minúsculas (*issues*).
* **Regra:** Cada Página vira uma Tarefa. Cada Comportamento vira uma Tarefa isolada.
* **Ordem de Execução:** Sempre gere primeiro tarefas de **Protótipo Visual** (Front-end sem lógica). Após aprovadas, passe para as tarefas funcionais e de Back-end.

---

## ⚙️ FASE 2: O Loop de Execução Micro (O Motor do SDD)

Para **CADA TAREFA** gerada na Fase 1, você deve repetir rigorosamente o ciclo abaixo. É aqui que o gerenciamento de *Context Window* brilha.

### Passo 2.1: Pesquisa & Coleta
* **Ação:** Peça para a IA atuar como pesquisadora para a tarefa atual.
* **Instruções para a IA:**
  1. Busque na base de código atual por componentes reutilizáveis.
  2. Identifique os arquivos existentes que serão afetados.
  3. Leia documentações externas necessárias (ex: Link da doc do Stripe, NextAuth).
  4. Busque padrões de implementação comprovados (GitHub, StackOverflow).
* **Output esperado:** Um arquivo **`prd.md`** (Product Requirements Document) contendo um resumo cirúrgico e enxuto das descobertas, sem "lixo" de contexto.

### Passo 2.2: A Primeira Limpeza (Amnésia Estratégica)
* **Ação:** Execute o comando de limpeza de contexto (ex: `/clear` no Claude Code ou inicie um Chat Novo).
* **Motivo:** A fase de pesquisa consumiu muitos tokens lendo arquivos grandes e buscando na web. Limpar o chat devolve 100% da inteligência do modelo.

### Passo 2.3: Planejamento Tático (`/plan`)
* **Ação:** No chat novo, anexe o **`prd.md`** gerado no Passo 2.1 e peça para a IA gerar o plano de implementação (Spec Tática) da tarefa.
* **Output esperado (A Spec Tática):**
  * Descrição de Cenários (Caminho Feliz, Erros, Edge Cases).
  * Estrutura de Banco de Dados (Tabelas e colunas a criar/alterar).
  * **Lista Estrita de Arquivos:** Caminhos exatos dos arquivos a serem criados.
  * **Lista Estrita de Modificações:** Caminhos exatos dos arquivos a serem alterados e o que será alterado neles (inclusive com trechos de código já definidos).
  * Checklist de passos.
* *Nota: Se a IA não for instruída a listar exatamente os arquivos, ela poderá alterar lugares indevidos. Amarre-a a esta lista.*

### Passo 2.4: A Segunda Limpeza
* **Ação:** Execute novamente a limpeza de contexto (`/clear` ou Chat Novo).
* **Motivo:** O debate para montar o plano consumiu tokens. Zeramos a memória novamente para a fase crítica de programação.

### Passo 2.5: Execução Modular (`/execute`)
* **Ação:** No chat 100% limpo, envie **apenas** o Planejamento Tático (Spec Tática) e ordene: *"Implemente este plano exatamente como descrito."*
* **Uso de Agentes (Opcional, mas recomendado):** Se a sua ferramenta suportar agentes especializados, invoque-os. (ex: `@DatabaseAgent implemente a parte do banco`, `@FrontendAgent implemente os componentes`).
* **Resultado:** A IA lerá um plano perfeito, com memória 100% livre, e escreverá um código com zero alucinações, reaproveitando componentes, respeitando sua arquitetura e com segurança.

---

## 🚀 Resumo do Fluxo do Dia a Dia (Cheatsheet)

1. Selecionou uma Issue/Tarefa?
2. **Pesquise** o que precisa (Docs, base local, padrões) -> Gera `prd.md`
3. 🧹 **LIMPA CONTEXTO (`/clear`)**
4. **Planeje** a execução baseado no PRD -> Gera `Spec Tática` (arquivos exatos)
5. 🧹 **LIMPA CONTEXTO (`/clear`)**
6. **Execute** o código.
7. Teste. Funciona? Repita o processo para a próxima Issue.

---

## 🤖 Automação com Claude Code (Slash Commands)

Este projeto possui 3 slash commands que automatizam o loop SDD:

| Comando | Fase | Input | Output |
|---|---|---|---|
| `/research <task-path>` | 2.1 | Path da task (.md) | `prd.md` no diretório da task |
| `/plan <prd-path>` | 2.3 | Path do prd.md | `plan.md` no diretório da task |
| `/execute <plan-path>` | 2.5 | Path do plan.md | Código implementado + build |

### Fluxo automatizado completo

```bash
# Sessão 1: Pesquisa
/research tasks/01-prototipos-visuais/02-tela-timer-rodando.md
# → Revise o PRD gerado, ajuste se necessário

/clear

# Sessão 2: Planejamento
/plan tasks/01-prototipos-visuais/02-tela-timer-rodando/prd.md
# → Revise o plan.md, ajuste se necessário

/clear

# Sessão 3: Execução
/execute tasks/01-prototipos-visuais/02-tela-timer-rodando/plan.md
# → Código implementado, build validado
# → Teste manual no simulador
```

Os comandos estão em `.claude/commands/` e seguem a documentação detalhada em `SDD/`.