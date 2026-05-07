# Toma — Workflow (SDD aplicado)

> Como a IA deve operar dentro deste projeto. Espelha [SDD/sdd_manual.md](../SDD/sdd_manual.md) com adaptações específicas ao Toma.

---

## 1. Princípio único

**Context Window é o recurso mais escasso.** Toda regra abaixo existe para preservar a inteligência da IA evitando passar de ~40% do context window por sessão.

---

## 2. Hierarquia de leitura

Ao iniciar **qualquer** task, ler nesta ordem:

1. **A própria task** em `tasks/<bloco>/<numero>-<nome>.md` — completa, sem `limit/offset`.
2. **`spec/spec.md`** — apenas as seções relevantes (página/behavior em escopo).
3. **`references/architecture.md`** — apenas seções referenciadas pela task.
4. **`references/design_system.md`** — apenas se a task toca UI.
5. **`references/garmin_platform.md`** — apenas seções de API que a task usa.
6. **Código existente** que a task vai modificar — completo.

**Nunca** leia tudo de tudo. A task lista o que ler.

---

## 3. Loop de execução por task

Para cada task em `tasks/`, repetir:

### 3.1 Pesquisa (FASE 2.1)

Comando do usuário:
```
Pesquise para a task tasks/01-prototipos-visuais/03-tela-pausa.md
```

A IA:
1. Lê a task completa.
2. Lê seções referenciadas das references.
3. Procura em `source/` por código reutilizável.
4. Se necessário, consulta documentação Garmin via WebFetch (preferir `developer.garmin.com`).
5. Gera arquivo `tasks/<bloco>/<numero>-<nome>/prd.md` com:
   - Resumo do que descobriu.
   - Componentes/arquivos existentes para reusar.
   - Decisões a tomar (alternativas + recomendação).
   - Riscos / unknowns.
   - Lista de arquivos prováveis a criar/modificar.

**Tamanho do PRD:** 200-500 linhas. Mais que isso = não está sendo cirúrgico.

### 3.2 Limpeza 1 (FASE 2.2)

Usuário executa `/clear`. Contexto vai a zero.

### 3.3 Plan (FASE 2.3)

Comando do usuário:
```
/plan tasks/01-prototipos-visuais/03-tela-pausa/prd.md
```

A IA:
1. Lê o PRD completo.
2. Lê as references mencionadas no PRD.
3. **Sem buscar nada novo** — o PRD já condensou tudo.
4. Gera `tasks/<bloco>/<numero>-<nome>/plan.md` (Spec Tática) com:
   - Cenários (caminho feliz, erros, edge cases).
   - **Lista exata de arquivos a criar** com path absoluto.
   - **Lista exata de arquivos a modificar** com snippets do que muda.
   - Estrutura de Storage/Properties tocadas (se aplicável).
   - Checklist de execução numerado.
   - Critérios de aceite (automated + manual).

**Regra:** plan.md **não** tem perguntas em aberto. Se há ambiguidade, IA pergunta ao usuário ANTES de fechar o plano.

### 3.4 Limpeza 2 (FASE 2.4)

Usuário executa `/clear`. Contexto vai a zero.

### 3.5 Execute (FASE 2.5)

Comando do usuário:
```
/execute tasks/01-prototipos-visuais/03-tela-pausa/plan.md
```

A IA:
1. Lê o plano completo.
2. Implementa **exatamente** o que está escrito. Sem adicionar features. Sem renomear.
3. Roda critérios automatizados quando possível (build, simulator, lint).
4. Marca checkboxes no plano como concluídas.
5. Reporta ao usuário com:
   - Lista de arquivos criados/modificados.
   - Resultado de cada critério automated.
   - Próximos passos manuais.

---

## 4. Regras de codificação durante execução

Ler primeiro `references/architecture.md` seção 4 ("Regras estritas de codificação"). Resumo aplicado:

- Naming: PascalCase para arquivos/classes, camelCase para métodos/vars.
- Imports: `using Toybox.X as X;`. Importar só o necessário.
- Tipos: declarar em toda função pública (`function foo(x as Number) as Boolean`).
- Strings/cores/dimensões: sempre via `Rez.*`. Nunca literal.
- `try/catch` só em fronteiras (I/O).
- Sem alocação em `onUpdate`.
- Sem mutação de Model em View.
- Sem acesso a Properties fora de Repository.

---

## 5. Estrutura dos artefatos por task

Cada task gera dentro do seu diretório:

```
tasks/01-prototipos-visuais/03-tela-pausa/
├── 03-tela-pausa.md       # task original (já existe)
├── prd.md                 # gerado na FASE 2.1
├── plan.md                # gerado na FASE 2.3
└── notes.md               # opcional, anotações pós-execução
```

**Nota:** o "diretório" da task pode não existir até o primeiro PRD ser gerado. A IA cria.

Atualização: a task em si (`03-tela-pausa.md`) renomeia para `tasks/01-prototipos-visuais/03-tela-pausa/README.md` quando o diretório é criado, OU permanece como arquivo `.md` no nível superior. Decidir na primeira execução real e padronizar dali em diante.

---

## 6. Decisões fora de escopo

Se durante uma task a IA identifica algo que **deveria** mudar mas não está na task:

- ❌ Não muda silenciosamente.
- ❌ Não cria task nova sozinha.
- ✅ Reporta ao usuário em uma seção "Out of scope notes" no plan.md ou notes.md.

Exemplo:
```
Out of scope notes:
- Notei que TimerService.start ignora vibrationEnabled. Provavelmente deveria checar.
  Não corrigi porque não está nesta task. Sugiro nova task em 02-comportamentos.
```

---

## 7. Quando consultar documentação externa

**Permitido:**
- `developer.garmin.com/connect-iq/api-docs/` para checar assinatura de API exata.
- `developer.garmin.com/connect-iq/core-topics/` para guides oficiais.
- Forum Garmin para casos de borda específicos (citar URL no PRD).

**Proibido sem aprovação:**
- Tutoriais aleatórios (Medium, blogs pessoais).
- Repositórios GitHub não-Garmin para "copiar approach".
- StackOverflow.

**Por quê:** alucinações vêm de fontes baixa-qualidade e desatualizadas. Documentação oficial é o ground truth.

---

## 8. Testes

### 8.1 Estratégia

- **Unit tests obrigatórios** para `model/` (state machine) e `utils/`.
- **Unit tests opcionais** para Services (mockar Toybox é trabalhoso, custo > benefício).
- **Sem testes** para Views/Delegates (UI testing não vale o esforço para esta V1).

### 8.2 Setup

Connect IQ suporta `monkeyc --unit-test`. Tests vão em `tests/`.

```monkeyc
using Toybox.Test;

(:test)
function testPomodoroStateTransition(logger as Test.Logger) as Boolean {
    var model = new PomodoroModel(testPreset, mockServices());
    model.start();
    model.tick(); // 24:59
    Test.assertEqual(model.getState(), :running_work);
    return true;
}
```

### 8.3 CI

Não há CI na V1. Build é local. Quando publicar V1.1, considerar GitHub Actions.

---

## 9. Versionamento

- Versão do app no `manifest.xml` segue SemVer: `1.0.0` para primeira release.
- Toda release Store incrementa o `versionCode` (number) e `versionName` (string).
- Mudanças que quebram dados persistidos (mudou schema de Storage) **devem** versionar e migrar — escrever migration em `StorageService`.

---

## 10. Quando pular o loop

O loop completo (research → clear → plan → clear → execute) pode parecer pesado. Quando pular?

**Regra:** pular **somente** para tasks triviais (< 30min, sem decisões arquiteturais).

Exemplos:
- Adicionar uma string nova em `strings.xml`.
- Corrigir um typo.
- Bumpar versão.

**Não pular** para:
- Qualquer mudança em `model/`.
- Qualquer mudança em `services/`.
- Adição de nova View ou Delegate.
- Qualquer task em `tasks/02-comportamentos/`.

---

## 11. Exemplo concreto: task `01-tela-home`

Sequência ideal:

```
[Sessão 1]
Usuário: "Pesquise para tasks/01-prototipos-visuais/01-tela-home.md"
IA: lê task, lê spec.md (P1), lê design_system.md (seções 4, 5, 6.2),
    lê architecture.md (seção 2, 3), procura em source/ (vazio inicialmente).
IA: gera tasks/01-prototipos-visuais/01-tela-home/prd.md.
Usuário: revisa PRD, ajusta, confirma.

[Sessão 2 — após /clear]
Usuário: "/plan tasks/01-prototipos-visuais/01-tela-home/prd.md"
IA: lê PRD, lê design_system.md (seções referenciadas).
IA: gera plan.md com lista exata: HomeView.mc, HomeDelegate.mc,
    layouts/home.xml, strings adicionais, dimensions.xml updates.

[Sessão 3 — após /clear]
Usuário: "/execute tasks/01-prototipos-visuais/01-tela-home/plan.md"
IA: lê plan.md, cria/edita os arquivos listados, roda monkeyc para FR255,
    valida no simulador, marca checkboxes do plan, reporta.
```

Total: 3 sessões, cada uma com contexto < 30% utilizado. Code output: zero alucinação.
