# SDD — FASE 2.5: Execução (Execute)

> Documentação de referência do passo de implementação. O slash command `/execute` automatiza este fluxo.

---

## Objetivo

Implementar EXATAMENTE o que o plan.md descreve. Sem features extras, sem refatorações não-autorizadas, sem decisões criativas. A IA age como executor disciplinado.

---

## Trigger

```
/execute tasks/01-prototipos-visuais/02-tela-timer-rodando/plan.md
```

---

## O que a IA faz

1. **Lê o plan.md completo.**
2. **Verifica checkboxes existentes** — se há trabalho parcial, retoma do primeiro `[ ]`.
3. **Executa o checklist na ordem**, marcando `[x]` a cada item concluído.
4. **Aplica as regras de codificação** de `references/architecture.md` §4.
5. **Builda para os 3 devices** ao final.
6. **Reporta resultado** com lista de arquivos e status de build.

---

## Regras de codificação (resumo)

| Regra | Exemplo |
|---|---|
| PascalCase para arquivos/classes | `HomeView.mc`, `class HomeView` |
| camelCase para métodos/vars | `navigateDown()`, `selectedIndex` |
| UPPER_SNAKE para constantes | `Colors.TEXT_PRIMARY` |
| Imports explícitos | `using Toybox.Graphics as Gfx;` |
| Tipos em funções públicas | `function foo(x as Lang.Number) as Void` |
| Cores via `Colors` module | Nunca `0xE8432D` hardcoded em View |
| Dimensões via `Dimensions` module | Nunca `180` hardcoded em View |
| Strings via `Rez.Strings` | Nunca string literal em UI |
| Sem alocação em `onUpdate` | Pré-criar em `initialize` |
| Sem mutação de Model em View | View é read-only |

---

## Build de validação

```bash
SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/" | head -1)"
KEYPATH="$HOME/.connect-iq/developer_key.der"

"$SDKPATH/bin/monkeyc" -d fr255 -f monkey.jungle -o bin/toma_fr255.prg -y "$KEYPATH" -w
"$SDKPATH/bin/monkeyc" -d fr255s -f monkey.jungle -o bin/toma_fr255s.prg -y "$KEYPATH" -w
"$SDKPATH/bin/monkeyc" -d fr265 -f monkey.jungle -o bin/toma_fr265.prg -y "$KEYPATH" -w
```

Se falhar: corrigir e rebuildar até sucesso. Não prosseguir com erros.

---

## Tratamento de divergências

Se o código real diverge do que o plan assume:

```
Divergência no item N:
Plan diz: [X]
Encontrei: [Y]
Como proceder?
```

**PARE e pergunte.** Não improvise.

---

## Report final

```
Execução completa.

Arquivos criados:
- source/views/FooView.mc
- source/delegates/FooDelegate.mc

Arquivos modificados:
- source/TomaApp.mc (adicionado import + view registration)

Build:
- fr255: ✅
- fr255s: ✅
- fr265: ✅

Critérios automated: 3/3 passaram.

Próximos passos (manual):
- Abrir simulador FR255 e verificar [cenário]
- Navegar com Up/Down e verificar [cenário]
```

---

## O que NÃO fazer

- ❌ Adicionar features não listadas no plan.
- ❌ Renomear variáveis/arquivos por "preferência".
- ❌ Refatorar código fora do scope.
- ❌ Pular itens do checklist.
- ❌ Commitar (o usuário decide quando).
- ❌ Deixar binários em `bin/` (limpar ao final).
