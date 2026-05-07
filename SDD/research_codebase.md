# SDD — FASE 2.1: Pesquisa (Research)

> Documentação de referência do passo de pesquisa. O slash command `/research` automatiza este fluxo.

---

## Objetivo

Investigar tudo necessário para uma task e condensar em um PRD (Product Requirements Document) que caiba em ~30% do context window. A pesquisa produz input limpo para o planejamento.

---

## Trigger

```
/research tasks/01-prototipos-visuais/02-tela-timer-rodando.md
```

Ou manualmente:
```
Pesquise para a task tasks/01-prototipos-visuais/02-tela-timer-rodando.md
```

---

## O que a IA faz

1. **Lê a task completa** (sem limit/offset).
2. **Lê references relevantes** — apenas seções citadas pela task:
   - `references/architecture.md` — estrutura, regras.
   - `references/design_system.md` — se toca UI (paleta, buckets, componentes).
   - `references/garmin_platform.md` — se usa APIs Toybox.
   - `spec/spec.md` — a página/behavior em escopo.
3. **Busca em `source/`** por código reutilizável (módulos, componentes, patterns).
4. **Consulta docs Garmin** (se necessário) — apenas `developer.garmin.com/connect-iq/api-docs/`.
5. **Gera o PRD** em `tasks/<bloco>/<nome-task>/prd.md`.

---

## Estrutura do PRD

```
tasks/<bloco>/<nome-task>/prd.md
```

Seções obrigatórias:
1. **Resumo** — 1-3 frases.
2. **O que descobri** — código reutilizável, assets, approach, APIs, cores/strings.
3. **Decisões a tomar** — alternativas + recomendação + justificativa.
4. **Riscos / Unknowns** — tabela com mitigação.
5. **Lista de arquivos** — criar e modificar, com responsabilidade.
6. **Arquitetura do fluxo** — diagrama textual.
7. **Referências para o plan.md** — o que o próximo passo precisa ler.
8. **Checklist pré-plan** — validação de completude.

---

## Regras

- **Tamanho:** 200-500 linhas. Mais = verbose, menos = incompleto.
- **Não implementa nada.** Só documenta.
- **Não sugere melhorias** fora do escopo.
- **Cita fontes** (seção de API docs, paths de código).
- **Pergunta ao usuário** se encontra ambiguidade bloqueante.

---

## Fontes permitidas

| Fonte | Permitido | Motivo |
|---|---|---|
| `developer.garmin.com/connect-iq/api-docs/` | ✅ | Ground truth |
| `developer.garmin.com/connect-iq/core-topics/` | ✅ | Guides oficiais |
| Forum Garmin | ⚠️ Sob aprovação | Casos de borda |
| Tutoriais/blogs | ❌ | Risco de info desatualizada |
| StackOverflow | ❌ | Base pequena, respostas velhas |

---

## Após a pesquisa

O usuário deve:
1. Revisar o PRD.
2. Ajustar se necessário.
3. Executar `/clear` para limpar contexto.
4. Iniciar FASE 2.3 com `/plan tasks/<bloco>/<nome-task>/prd.md`.
