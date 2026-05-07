# Bloco 00 — Setup

> **Não é uma task no sentido SDD.** É um pré-requisito que precisa ser feito **uma vez**, presencialmente, antes de qualquer task do Bloco 01 ou 02 ser executada.

---

## Objetivo

Deixar o ambiente local pronto para desenvolver, compilar, simular e side-loadar o app Toma.

---

## Pré-requisitos

- macOS 10.15+ (você está em darwin 24.6.0 ✅).
- VS Code instalado.
- ~5 GB de disco livre (SDK + simuladores de devices).
- Conta Garmin Developer ([cadastrar](https://developer.garmin.com)).

---

## Checklist de setup

### 1. Instalar Java JRE 11+

```bash
# Verificar versão
java -version
```

Se não tem, instalar via Homebrew:
```bash
brew install --cask temurin
```

### 2. Baixar SDK Manager

Acessar: <https://developer.garmin.com/connect-iq/sdk/>

- Login com Garmin Developer account.
- Baixar **SDK Manager** para macOS.
- Mover `Connect IQ SDK Manager.app` para `/Applications/`.
- Abrir e aceitar EULA.

### 3. Instalar SDK 7.x ou superior

Dentro do SDK Manager:
- Tab **SDKs**: baixar SDK mais recente que suporte System 7 (4.2.x ou superior).
- Tab **Devices**: baixar packages para:
  - Forerunner 255 + 255S (+ Music versions se quiser testar)
  - Forerunner 265 + 265S
  - Forerunner 955
  - Forerunner 965
  - Fenix 7 + 7 Pro
  - Fenix 8 (todos SKUs)
  - Epix Gen 2
  - Venu 3 + 3S
  - Vivoactive 5

### 4. Instalar VS Code Monkey C extension

VS Code → Extensions → procurar "Monkey C" (publisher: garmin).

Instalar.

### 5. Verificar instalação

VS Code Command Palette (`Cmd+Shift+P`):
- `Monkey C: Verify Installation` → deve passar tudo verde.

### 6. Gerar developer key

VS Code Command Palette:
- `Monkey C: Generate a Developer Key`
- Salvar em `~/.connect-iq/developer_key.der`.
- **Backup imediato**: copiar para outro local seguro (ex: 1Password attachment, drive externo).

```bash
mkdir -p ~/.connect-iq
chmod 600 ~/.connect-iq/developer_key.der
ls -l ~/.connect-iq/developer_key.der
```

**ATENÇÃO:** sem essa chave, não dá pra publicar updates do app na Connect IQ Store. Perdê-la = ter que publicar como app novo (perde reviews, downloads).

### 7. Conferir IDs de devices instalados

```bash
ls "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/"
# Listar device IDs disponíveis para a jungle
```

Anotar os IDs reais (ex: `fr255`, `fr255s`, `fenix847mm`) — o `references/garmin_platform.md` tem a lista esperada, mas valores podem diferir do que está documentado. Atualizar o arquivo se necessário.

### 8. Validar com projeto template

Antes de criar o Toma, validar o ambiente com um projeto Hello World:

```bash
cd /tmp
# Via VS Code Command Palette: "Monkey C: New Project"
# Escolher "App", device "Forerunner 255", template "Watch App"
```

Compilar e rodar no simulador (`F5`). Se aparece "Hello World" no FR255, ambiente OK.

Se falhar, debugar antes de prosseguir. **Não** começar tasks do Toma com ambiente quebrado.

---

## Criação inicial do projeto Toma

Após o ambiente validado:

### A. Scaffold do Toma

Comando do usuário (na próxima task de prototype, **não** aqui):
```
/research tasks/01-prototipos-visuais/01-tela-home.md
```

Isso vai gerar PRD que inclui criação inicial de:
- `manifest.xml` (decla devices suportados, permissões, idiomas).
- `monkey.jungle` (configuração multi-device).
- `source/TomaApp.mc` mínimo (extends AppBase, retorna HomeView).
- `resources/strings/strings.xml` mínimo.
- `.vscode/launch.json` para debug.
- `.gitignore` (ignorar `developer_key.der`, `bin/`, `.iq` de release).

A primeira task (P1 Home) já implica esse scaffold. Não precisamos de uma task separada "criar scaffold".

### B. Git

Antes de qualquer commit:

```bash
cd /Users/mijose/Desenvolvimento/pomodoro-garmin
git init
```

`.gitignore` essencial (a IA cria na primeira task):

```
# Garmin
*.prg
*.iq
bin/
build/
developer_key.der
.connect-iq/

# IDE
.vscode/.workspaceStorage/
.idea/

# OS
.DS_Store
```

**Não commitar** `developer_key.der` em hipótese alguma.

---

## Output esperado deste bloco

Ao final do setup, você tem:

- [ ] SDK Manager instalado e funcional.
- [ ] SDK 7.x e devices baixados (FR255, FR265, FR955, FR965, Fenix 7, Fenix 8, Epix2, Venu 3, Vivoactive 5).
- [ ] VS Code com extensão Monkey C funcional.
- [ ] `~/.connect-iq/developer_key.der` existe e está backupado.
- [ ] Projeto Hello World rodou com sucesso no simulador FR255.
- [ ] `/Users/mijose/Desenvolvimento/pomodoro-garmin/` está em estado pronto para receber `manifest.xml` na primeira task.
- [ ] `git init` executado, `.gitignore` correto.

---

## Próximo passo

Iniciar **Bloco 01** com a tarefa:

```
tasks/01-prototipos-visuais/01-tela-home.md
```

Comando do usuário:
```
/research tasks/01-prototipos-visuais/01-tela-home.md
```
