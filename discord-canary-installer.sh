#!/bin/bash

# Configurações globais
readonly EXTRACT_DIR="$HOME/.discord-canary"
readonly TAR_URL="https://discord.com/api/download/canary?platform=linux&format=tar.gz"
readonly NOTIFICATION_TITLE="Discord Canary Update"
readonly LOCAL_BIN_DIR="$HOME/.local/bin"
readonly APPLICATIONS_DIR="$HOME/.local/share/applications"

# Log de erros
log_error() {
    echo "[ERROR] $1" >&2
}

# Função de notificação
notify_user() {
    local message="$1"
    local notification_methods=(
        "notify-send"
        "kdialog --passivepopup"
        "zenity --notification --text"
    )

    for method in "${notification_methods[@]}"; do
        if command -v "${method%% *}" &>/dev/null; then
            case "$method" in
                "notify-send")
                    notify-send "$NOTIFICATION_TITLE" "$message"
                    return 0
                    ;;
                "kdialog --passivepopup")
                    kdialog --passivepopup "$message" 5
                    return 0
                    ;;
                "zenity --notification --text")
                    zenity --notification --text "$message"
                    return 0
                    ;;
            esac
        fi
    done

    # Fallback para saída de console
    echo "Notificação: $message"
}

# Extrai a versão do nome do arquivo
extract_version_from_filename() {
    local filename="$1"
    echo "$filename" | grep -oP 'discord-canary-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)' || echo "Desconhecida"
}

# Obtém a versão instalada
get_installed_version() {
    local build_info_file="$EXTRACT_DIR/resources/build_info.json"
    if [[ -f "$build_info_file" ]]; then
        jq -r '.version' "$build_info_file" 2>/dev/null || echo "Desconhecida"
    else
        echo "Desconhecida"
    fi
}

# Obtém a URL de redirecionamento
get_redirect_url() {
    local url="$1"
    curl -s -I -L -o /dev/null -w '%{url_effective}' "$url"
}

# Corrige permissões do chrome-sandbox
fix_chrome_sandbox_permissions() {
    local sandbox_path="$1"
    sudo chown root:root "$sandbox_path" || {
        log_error "Falha ao corrigir a propriedade do chrome-sandbox."
        return 1
    }
    sudo chmod 4755 "$sandbox_path" || {
        log_error "Falha ao corrigir as permissões do chrome-sandbox."
        return 1
    }
}

# Instala pacotes necessários
install_required_packages() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu | debian)
                sudo apt-get update
                sudo apt-get install -y curl wget jq libnotify-bin kdialog zenity
                ;;
            fedora)
                sudo dnf install -y curl wget jq libnotify kdialog zenity
                ;;
            *)
                log_error "Distribuição não suportada: $ID"
                exit 1
                ;;
        esac
    else
        log_error "Não foi possível detectar a distribuição do sistema."
        exit 1
    fi
}

# Instala o Discord Canary
install_discord() {
    local temp_tar="$1"
    
    # Cria diretórios necessários
    mkdir -p "$EXTRACT_DIR" "$LOCAL_BIN_DIR"
    
    # Extrai o pacote
    tar -xzf "$temp_tar" -C "$EXTRACT_DIR" --strip-components=1 || {
        log_error "Falha ao extrair o pacote .tar.gz."
        return 1
    }
    
    # Cria link simbólico
    ln -sf "$EXTRACT_DIR/DiscordCanary" "$LOCAL_BIN_DIR/discord-canary"
    
    # Corrige permissões do sandbox
    fix_chrome_sandbox_permissions "$EXTRACT_DIR/chrome-sandbox"
}

# Cria script de verificação de atualização
create_check_update_script() {
    local script_path="$EXTRACT_DIR/checkUpdate.sh"
    local script_content=$(cat <<'EOL'
#!/bin/bash

# Importa funções de utilitário
source "$HOME/.discord-canary/update_utils.sh"

# Função principal de verificação e atualização
check_and_update() {
    local installed_version=$(get_installed_version)
    local latest_url=$(get_redirect_url "$TAR_URL")
    local filename=$(basename "$latest_url")
    local latest_version=$(extract_version_from_filename "$filename")

    if [[ "$installed_version" == "Desconhecida" ]]; then
        notify_user "Discord Canary não instalado. Instalando..."
        TEMP_TAR="$EXTRACT_DIR/$filename"
        download_and_install "$latest_url" "$TEMP_TAR"
        notify_user "Discord Canary instalado."
        launch_discord
        return
    fi

    # Verificar se há atualização
    if [[ "$installed_version" != "$latest_version" ]]; then
        notify_user "Nova versão encontrada ($latest_version). Atualizando..."
        TEMP_TAR="$EXTRACT_DIR/$filename"
        download_and_install "$latest_url" "$TEMP_TAR"
        notify_user "Atualização concluída para a versão $latest_version."
    else
        notify_user "Você já está utilizando a versão mais recente ($installed_version)."
    fi

    launch_discord
}

# Funções adicionais de utilitário
download_and_install() {
    local url="$1"
    local temp_tar="$2"
    
    wget --progress=bar:force "$url" -O "$temp_tar" || {
        notify_user "Falha ao baixar o arquivo de instalação/atualização."
        return 1
    }
    
    install_discord "$temp_tar"
    rm "$temp_tar"
}

launch_discord() {
    discord-canary &>/dev/null & disown
}

# Chama a função de verificação e atualização
check_and_update
EOL
    )

    # Cria o script de utilitários
    cat > "$EXTRACT_DIR/update_utils.sh" <<'EOL'
#!/bin/bash

# Configurações globais
readonly EXTRACT_DIR="$HOME/.discord-canary"
readonly TAR_URL="https://discord.com/api/download/canary?platform=linux&format=tar.gz"
readonly NOTIFICATION_TITLE="Discord Canary Update"

# Importa funções de notificação e outras utilitárias
source "$EXTRACT_DIR/notification_utils.sh"

# Funções do Discord
source "$EXTRACT_DIR/discord_utils.sh"
EOL

    # Cria o script de notificação
    cat > "$EXTRACT_DIR/notification_utils.sh" <<'EOL'
#!/bin/bash

# Função de notificação
notify_user() {
    local message="$1"
    local notification_methods=(
        "notify-send"
        "kdialog --passivepopup"
        "zenity --notification --text"
    )

    for method in "${notification_methods[@]}"; do
        if command -v "${method%% *}" &>/dev/null; then
            case "$method" in
                "notify-send")
                    notify-send "$NOTIFICATION_TITLE" "$message"
                    return 0
                    ;;
                "kdialog --passivepopup")
                    kdialog --passivepopup "$message" 5
                    return 0
                    ;;
                "zenity --notification --text")
                    zenity --notification --text "$message"
                    return 0
                    ;;
            esac
        fi
    done

    # Fallback para saída de console
    echo "Notificação: $message"
}

# Log de erros
log_error() {
    echo "[ERROR] $1" >&2
}
EOL

    # Cria o script de utilitários do Discord
    cat > "$EXTRACT_DIR/discord_utils.sh" <<'EOL'
#!/bin/bash

# Extrai a versão do nome do arquivo
extract_version_from_filename() {
    local filename="$1"
    echo "$filename" | grep -oP 'discord-canary-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)' || echo "Desconhecida"
}

# Obtém a versão instalada
get_installed_version() {
    local build_info_file="$EXTRACT_DIR/resources/build_info.json"
    if [[ -f "$build_info_file" ]]; then
        jq -r '.version' "$build_info_file" 2>/dev/null || echo "Desconhecida"
    else
        echo "Desconhecida"
    fi
}

# Obtém a URL de redirecionamento
get_redirect_url() {
    local url="$1"
    curl -s -I -L -o /dev/null -w '%{url_effective}' "$url"
}

# Corrige permissões do chrome-sandbox
fix_chrome_sandbox_permissions() {
    local sandbox_path="$1"
    sudo chown root:root "$sandbox_path" || {
        log_error "Falha ao corrigir a propriedade do chrome-sandbox."
        return 1
    }
    sudo chmod 4755 "$sandbox_path" || {
        log_error "Falha ao corrigir as permissões do chrome-sandbox."
        return 1
    }
}

# Instala o Discord Canary
install_discord() {
    local temp_tar="$1"
    
    # Cria diretórios necessários
    mkdir -p "$EXTRACT_DIR" "$HOME/.local/bin"
    
    # Extrai o pacote
    tar -xzf "$temp_tar" -C "$EXTRACT_DIR" --strip-components=1 || {
        log_error "Falha ao extrair o pacote .tar.gz."
        return 1
    }
    
    # Cria link simbólico
    ln -sf "$EXTRACT_DIR/DiscordCanary" "$HOME/.local/bin/discord-canary"
    
    # Corrige permissões do sandbox
    fix_chrome_sandbox_permissions "$EXTRACT_DIR/chrome-sandbox"
}
EOL

    # Escreve o conteúdo do script
    echo "$script_content" > "$script_path"
    
    # Torna os scripts executáveis
    chmod +x "$script_path"
    chmod +x "$EXTRACT_DIR/update_utils.sh"
    chmod +x "$EXTRACT_DIR/notification_utils.sh"
    chmod +x "$EXTRACT_DIR/discord_utils.sh"
}

# Cria ícone no menu de aplicativos
create_menu_icon() {
    mkdir -p "$APPLICATIONS_DIR"
    cat > "$APPLICATIONS_DIR/discord-canary-update.desktop" <<EOL
[Desktop Entry]
Name=Discord Canary
Comment=Discord Canary Client
Exec=$EXTRACT_DIR/checkUpdate.sh
Icon=$EXTRACT_DIR/discord.png
Terminal=false
Type=Application
Categories=Network;Chat;
EOL
}

# Função principal de instalação
main() {
    local latest_url
    local filename
    local TEMP_TAR

    # Instala pacotes necessários
    install_required_packages

    # Obtém a URL de download
    latest_url=$(get_redirect_url "$TAR_URL")
    filename=$(basename "$latest_url")
    TEMP_TAR="$EXTRACT_DIR/$filename"

    # Cria diretórios
    mkdir -p "$EXTRACT_DIR" "$LOCAL_BIN_DIR"

    # Baixa o pacote
    wget --progress=bar:force "$latest_url" -O "$TEMP_TAR" || {
        notify_user "Falha ao baixar o arquivo de instalação."
        exit 1
    }

    # Instala o Discord
    install_discord "$TEMP_TAR"
    rm "$TEMP_TAR"

    # Cria scripts de atualização e ícone
    create_check_update_script
    create_menu_icon

    notify_user "Discord Canary instalado com sucesso."
}

# Inicia o processo de instalação
main
