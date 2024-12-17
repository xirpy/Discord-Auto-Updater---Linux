# Discord Canary Automatic Installer and Updater for Linux

## 📝 Descrição do Projeto

Este script automatiza a instalação e atualização do Discord Canary para sistemas Linux, oferecendo uma solução simples e eficiente para manter o cliente Discord Canary atualizado.

## ✨ Funcionalidades Principais

- Instalação automática do Discord Canary
- Verificação e atualização em segundo plano
- Notificações de sistema para atualizações
- Suporte a múltiplos gerenciadores de notificação
- Criação de ícone no menu de aplicativos

## 🛠️ Pré-requisitos

Antes de usar o script, certifique-se de ter instalado:

- Bash (versão 4.0 ou superior)
- `curl`
- `wget`
- `jq` (para processamento de JSON)
- Um dos seguintes para notificações:
  - `notify-send` (sistemas com libnotify)
  - `kdialog` (ambientes KDE)
  - `zenity` (ambientes GNOME)

## 💾 Instalação

### Clonar Repositório

```bash
# Clone o repositório
git clone https://github.seu-usuario.com/discord-canary-installer.git

# Entre no diretório
cd discord-canary-installer

# Torne o script executável
chmod +x discord-canary-installer.sh

# Execute o script
./discord-canary-installer.sh
```

## 🚀 Como Funciona

1. Baixa automaticamente a versão mais recente do Discord Canary
2. Extrai e instala no diretório `~/.discord-canary`
3. Cria um link simbólico em `~/.local/bin`
4. Configura permissões do chrome-sandbox
5. Adiciona um atalho no menu de aplicativos
6. Verifica atualizações a cada execução

## ⚠️ Avisos e Limitações

- Requer permissões de sudo para configuração do chrome-sandbox
- Projetado especificamente para distribuições Linux

## 🔧 Solução de Problemas

### Erro de Permissão
Se encontrar erros de permissão, verifique:
- Tem `sudo` instalado?
- Deu permissão para o script funcionar?

### Dependências Faltando
Instale as dependências necessárias:
```bash
# Para sistemas baseados em Debian/Ubuntu
sudo apt update
sudo apt install curl wget jq libnotify-bin
```

## 🤝 Contribuições

Contribuições são bem-vindas! Por favor:
1. Faça um fork do repositório
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

---

**Nota:** Este projeto não é oficialmente vinculado ao Discord. Use por sua conta e risco.
