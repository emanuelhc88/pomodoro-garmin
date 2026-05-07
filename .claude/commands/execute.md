---
description: "FASE 2.5 — Implementa exatamente o plan.md. Cria/modifica arquivos, builda, marca checkboxes"
model: opus
---

# Execute (FASE 2.5 do SDD)

Você é um implementador. Sua missão é executar o plan.md EXATAMENTE como descrito, sem adicionar features, sem renomear, sem refatorar fora do escopo.

## Input esperado

O usuário vai fornecer o path do plan, ex: `tasks/01-prototipos-visuais/02-tela-timer-rodando/plan.md`

Se $ARGUMENTS contém um path, use-o. Caso contrário, pergunte qual plan executar.

## Passos obrigatórios

### 1. Ler o plan.md completo
- Leia SEM limit/offset.
- Verifique se há checkboxes já marcados (trabalho parcial anterior).
- Se sim, retome do primeiro item não-marcado.

### 2. Seguir o checklist na ordem

Para cada item do checklist:
1. Execute a ação descrita.
2. Marque o checkbox no plan.md como `[x]`.
3. Se encontrar divergência com a realidade do código, PARE e informe ao usuário:
   ```
   Divergência no item N:
   Plan diz: [X]
   Encontrei: [Y]
   Como proceder?
   ```

### 3. Regras de codificação (de references/architecture.md §4)

- PascalCase para arquivos/classes, camelCase para métodos/vars.
- `using Toybox.X as X;` nos imports.
- Tipos declarados em funções públicas.
- Cores via módulo `Colors`, dimensões via `Dimensions`, strings via `Rez.Strings`.
- Sem alocação em `onUpdate`.
- Sem mutação de Model em View.
- Sem `try/catch` fora de fronteiras I/O.

### 4. Build de validação

Após implementar, rodar o build para os 3 devices:

```bash
SDKPATH="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/" | head -1)"
KEYPATH="$HOME/.connect-iq/developer_key.der"

"$SDKPATH/bin/monkeyc" -d fr255 -f monkey.jungle -o bin/toma_fr255.prg -y "$KEYPATH" -w
"$SDKPATH/bin/monkeyc" -d fr255s -f monkey.jungle -o bin/toma_fr255s.prg -y "$KEYPATH" -w
"$SDKPATH/bin/monkeyc" -d fr265 -f monkey.jungle -o bin/toma_fr265.prg -y "$KEYPATH" -w
```

Se falhar, corrija e rebuilde até sucesso.

### 5. Marcar critérios automated

No plan.md, marque `[x]` nos critérios automated que passaram.

### 6. Report final

Informe ao usuário:
```
Execução completa.

Arquivos criados:
- [lista]

Arquivos modificados:
- [lista]

Build:
- fr255: ✅
- fr255s: ✅
- fr265: ✅

Critérios automated: [N/N] passaram.

Próximos passos (manual):
- [lista de verificações manuais do plan]
```

## Regras RÍGIDAS

- **Não adicione features** que não estão no plan.
- **Não renomeie** variáveis/funções/arquivos sem que o plan diga.
- **Não refatore** código existente fora do scope.
- **Não pule itens** do checklist.
- **Se um item não faz sentido**, pergunte — não improvise.
- **Limpe bin/** ao final (não commite binários).
- **Não faça commit** — deixe para o usuário decidir quando commitar.
