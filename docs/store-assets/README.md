# Store assets

Arquivos prontos para upload na Connect IQ Store.

## Icon

- [store-icon-500.png](store-icon-500.png) — 500×500, dark background, usado
  como ícone da listagem da loja.

Gerado com:

```bash
rsvg-convert -w 500 -h 500 \
  manual-de-marca/logo/toma_icon_dark_bg.svg \
  -o docs/store-assets/store-icon-500.png
```

## Screenshots

**Ainda precisam ser capturados.** O portal aceita até 5 por device family.

### Cobertura mínima recomendada (3 devices × 3 telas = 9 imagens)

| Bucket | Device sugerido | Tela |
| --- | --- | --- |
| MIP small | `fr255s` (218×218) | Home, Timer rodando, CycleComplete |
| MIP medium | `fenix7` (260×260) | Home, Timer rodando, CycleComplete |
| AMOLED large | `venu3` (454×454) | Home, Timer rodando, CycleComplete |

### Passo-a-passo (simulator)

1. Build primeiro (necessário porque o repo foi atualizado):

   ```bash
   ./scripts/build-all.sh
   ```

2. Abrir o simulator:

   ```bash
   open "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/ | head -1)/bin/ConnectIQ.app"
   ```

3. No simulator: **File → Simulate Device**, escolher o device desejado.

4. Subir o `.prg` correspondente:

   ```bash
   SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/$(ls ~/Library/Application\ Support/Garmin/ConnectIQ/Sdks/ | head -1)"
   "$SDK/bin/monkeydo" bin/toma_venu3.prg venu3
   ```

5. Capturar: no simulator, **File → Capture Screen Shot** (salva PNG do
   display do watch, sem bordas do chrome). Como fallback, `Cmd+Shift+4` do
   macOS apontando para a área do watch.

6. Salvar em `docs/store-assets/screenshots/<device>/<tela>.png`, ex.:

   ```text
   docs/store-assets/screenshots/venu3/01-home.png
   docs/store-assets/screenshots/venu3/02-timer-running.png
   docs/store-assets/screenshots/venu3/03-cycle-complete.png
   ```

### Roteiro de interação para cada device

Para manter consistência visual entre os screenshots:

1. **Home** — carousel no preset `25/5` (primeiro builtin).
2. **Timer rodando** — escolher `25/5`, deixar rodar até ~22:30 restantes
   (fica numa faixa legível, anel já com progresso visível).
3. **CycleComplete** — mais rápido: criar um custom preset `1min / 1min / 1 ciclo`
   e esperar completar, OU simplesmente pular com `Menu → Debug → Fast Forward`
   se disponível.

### Notas

- A Garmin exige screenshots com **resolução nativa do device** (não upscale).
  O "Capture Screen Shot" do simulator já faz isso corretamente.
- Evitar screenshots com conteúdo debug (`dev` label, console overlay).
- Preferir presets em inglês para a listagem global (trocar idioma em
  Settings → Language → English antes de capturar).
