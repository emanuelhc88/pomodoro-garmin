# SDD — FASE 2.3: Planejamento Tático (Plan)

> Documentação de referência do passo de planejamento. O slash command `/plan` automatiza este fluxo.

---

## Objetivo

Transformar o PRD em um plano de implementação preciso e sem ambiguidades. O plan.md deve ser suficiente para uma sessão de IA com contexto 100% limpo implementar tudo sem perguntas.

---

## Trigger

```
/plan tasks/01-prototipos-visuais/02-tela-timer-rodando/prd.md
```

---

## O que a IA faz

1. **Lê o PRD completo.**
2. **Lê as references mencionadas** na seção "Referências para o plan.md" do PRD.
3. **Lê código existente** que será modificado (paths do PRD seção 5).
4. **NÃO busca nada novo** — o PRD já condensou toda pesquisa.
5. **Gera o plan.md** em `tasks/<bloco>/<nome-task>/plan.md`.

---

## Estrutura do plan.md

```
tasks/<bloco>/<nome-task>/plan.md
```

Seções obrigatórias:

1. **Resumo** — 1-2 frases.
2. **Cenários** — caminho feliz, edge cases, erros.
3. **Arquivos a CRIAR** — tabela com path exato e responsabilidade.
4. **Arquivos a MODIFICAR** — tabela + snippets antes/depois.
5. **Storage/Properties** — se aplicável, keys com tipo e default.
6. **Checklist de execução** — numerado, sequencial, cada ação atômica.
7. **Critérios de aceite** — separados em Automated (build, tests) e Manual (simulador).
8. **Out of scope** — o que não fazer.

---

## Regras rígidas

| Regra | Motivo |
|---|---|
| Zero perguntas em aberto | Se há ambiguidade, pergunte ANTES de fechar |
| Paths relativos ao root | Quem executa precisa saber onde criar |
| Snippets exatos para modificações | "Adicione algo parecido" causa alucinação |
| Não implementa | Só planeja |
| Não adiciona scope | Se não está no PRD, não está no plan |
| Checklist sequencial | Executor segue na ordem sem decisões |
| Build como critério | Se não compila, não está pronto |

---

## Critérios de aceite padrão (Toma)

### Automated (sempre incluir)
```
- [ ] `monkeyc -d fr255` compila sem erros
- [ ] `monkeyc -d fr255s` compila sem erros
- [ ] `monkeyc -d fr265` compila sem erros
```

### Manual (por task)
```
- [ ] [Cenário visual específico no simulador]
- [ ] [Navegação funciona]
- [ ] [Sem regressão visual em telas anteriores]
```

---

## Após o planejamento

O usuário deve:
1. Revisar o plan.md.
2. Ajustar se necessário.
3. Executar `/clear` para limpar contexto.
4. Iniciar FASE 2.5 com `/execute tasks/<bloco>/<nome-task>/plan.md`.
