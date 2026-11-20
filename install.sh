#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_DIR="/storage/emulated/0/Android/data/com.dts.freefireth/files/contentcache/Optional/android"
TMP_DIR="/data/data/com.termux/files/usr/tmp/ghost_remote"

# URLs dos arquivos no GitHub
REMOTE_ARB1="https://raw.githubusercontent.com/Pkdev730/Holograma/main/bkp_1.txt"
REMOTE_ARB2="https://raw.githubusercontent.com/Pkdev730/Holograma/main/data_02.dat"
REMOTE_ARB3="https://raw.githubusercontent.com/Pkdev730/Holograma/main/texture_3.bin"
REMOTE_ARB4="https://raw.githubusercontent.com/Pkdev730/Holograma/main/cfg_4.db"

declare -A ESTADO
ESTADO[1]=0
ESTADO[2]=0
ESTADO[3]=0

# --- FUNÇÃO DE DOWNLOAD COM VERIFICAÇÃO ---
download_verified() {
    local url="$1"
    local local_file="$2"
    local min_size="${3:-512}"

    echo -e "${YELLOW}[*] Baixando $(basename "$local_file")...${NC}"
    curl -sL --max-time 20 -o "$local_file" "$url"

    if [ ! -f "$local_file" ]; then
        echo -e "${RED}[!] Falha no download: $url${NC}"
        return 1
    fi

    local size=$(stat -c%s "$local_file" 2>/dev/null || echo 0)
    if [ "$size" -lt "$min_size" ]; then
        echo -e "${RED}[!] Arquivo muito pequeno ($size bytes). Provável erro 404 do GitHub.${NC}"
        rm -f "$local_file"
        return 1
    fi

    if head -c 100 "$local_file" | grep -qi "<!DOCTYPE\|<html"; then
        echo -e "${RED}[!] O arquivo é uma página HTML de erro, não o binário.${NC}"
        rm -f "$local_file"
        return 1
    fi

    echo -e "${GREEN}[+] $(basename "$local_file") ok ($size bytes)${NC}"
    return 0
}

# --- FUNÇÃO DE INJEÇÃO (COM FALLBACK) ---
inject_file() {
    local local_file="$1"
    local remote_path="$2"
    local remote_dir=$(dirname "$remote_path")

    # 1. Tenta via Shizuku (rish) - Sem precisar de root
    if command -v rish >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Injetando via Shizuku (rish)...${NC}"
        rish -c "mkdir -p '$remote_dir' && cat '$local_file' > '$remote_path'" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] Injetado via Shizuku: $(basename "$remote_path")${NC}"
            return 0
        fi
        echo -e "${YELLOW}[!] Shizuku falhou. Tentando via ADB Push...${NC}"
    fi

    # 2. Tenta via ADB Push normal (funciona se o aparelho tiver root ou for emulador)
    adb push "$local_file" "$remote_path" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Injetado via ADB: $(basename "$remote_path")${NC}"
        return 0
    fi

    echo -e "${RED}[!] Falha total ao injetar: $(basename "$remote_path")${NC}"
    return 1
}

# --- FORÇAR ADB ROOT (Opcional) ---
force_adb_root() {
    echo -e "${YELLOW}[*] Verificando ADB root...${NC}"
    adb root > /dev/null 2>&1
    sleep 1
    if adb shell "id" 2>/dev/null | grep -q "uid=0"; then
        echo -e "${GREEN}[+] ADB root disponível.${NC}"
        return 0
    fi
    echo -e "${YELLOW}[!] Sem ADB root. Tentaremos via Shizuku.${NC}"
    return 1
}

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}            AUTENTICAÇÃO GHOST            ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

# --- CONEXÃO ADB ---
ADB_STATE=$(adb get-state 2>/dev/null | tr -d '\r\n')

if [ "$ADB_STATE" == "device" ]; then
    echo -e "${GREEN}[+] Sistema ADB já conectado.${NC}"
    sleep 1
else
    echo -e "${WHITE}Etapa 1: Conexão com o Dispositivo${NC}"
    echo -e "${YELLOW}O ADB não está conectado. Vamos configurar agora.${NC}\n"

    echo -n "IP:PORTA de PAREAMENTO: "
    read -r PAIR_ADDR < /dev/tty
    echo -n "Código de 6 dígitos: "
    read -r PAIR_CODE < /dev/tty

    echo -e "\n${YELLOW}[*] Pareando dispositivos...${NC}"
    adb pair $PAIR_ADDR $PAIR_CODE

    echo -n "IP:PORTA de CONEXÃO: "
    read -r CONN_ADDR < /dev/tty

    echo -e "${YELLOW}[*] Estabelecendo conexão segura...${NC}"
    adb connect $CONN_ADDR
    sleep 1

    if [ "$(adb get-state 2>/dev/null | tr -d '\r\n')" != "device" ]; then
        echo -e "${RED}[!] Falha na conexão. Abortando.${NC}"
        exit 1
    fi
fi

force_adb_root

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

echo -n "Digite a sua Key (ex: External-teste1): "
read -r USER_KEY < /dev/tty

echo -e "${YELLOW}[*] Verificando Key no servidor...${NC}"
FIREBASE_RESPONSE=$(curl -s --max-time 5 "${FIREBASE_URL}/.json")

if [ -z "$FIREBASE_RESPONSE" ] || echo "$FIREBASE_RESPONSE" | grep -q "error"; then
    echo -e "${RED}[!] Falha ao conectar no banco.${NC}"
    exit 1
fi

STATUS_KEY=$(echo "$FIREBASE_RESPONSE" | grep -o "\"$USER_KEY\".*\"status\":\"ativada\"" | head -n 1)

if [ -z "$STATUS_KEY" ]; then
    echo -e "${RED}[!] Key não encontrada, inativa ou expirada.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Acesso Autorizado!${NC}"
sleep 2

# --- MENU PRINCIPAL ---
mkdir -p "$TMP_DIR"

while true; do
    printf "\033c"
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${WHITE}              GHOST REMOTE                ${NC}"
    echo -e "${PURPLE}==========================================${NC}\n"

    status() {
        if [ "${ESTADO[$1]}" -eq 1 ]; then echo -e "${GREEN}[ON]${NC}"; else echo -e "${RED}[OFF]${NC}"; fi
    }

    echo -e "${CYAN}┌── MODS FREE FIRE (CLOUD) ──────────────┐${NC}"
    echo -e "  [1] Injetar ESP/Chams (Shaders) $(status 1)"
    echo -e "  [2] Injetar Aimbot (Fileinfos) $(status 2)"
    echo -e "  [3] Injetar TUDO (Mod Completo) $(status 3)"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"

    echo -e "\n${RED}┌── DESCONECTAR / LIMPAR (BYPASS) ───────┐${NC}"
    echo -e "  [99] Desativar Mods (Restaurar Originais)"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"

    echo -e "\n  [0] Encerrar Sessão"
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    if [ "$FUNC_OPT" == "99" ]; then
        echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
        adb shell am force-stop $FF_PACKAGE
        sleep 1

        echo -e "${YELLOW}[*] Restaurando originais via Cloud...${NC}"
        
        download_verified "$REMOTE_ARB2" "$TMP_DIR/fileinfo" 512
        download_verified "$REMOTE_ARB4" "$TMP_DIR/fileinfo_opt" 512
        
        inject_file "$TMP_DIR/fileinfo" "${FF_DIR}/fileinfo"
        inject_file "$TMP_DIR/fileinfo_opt" "${FF_DIR}/optionalavatarres/fileinfo"

        ESTADO[1]=0; ESTADO[2]=0; ESTADO[3]=0
        echo -e "\n${GREEN}[+] Bypass concluído! Originais restaurados.${NC}"
        sleep 3
        continue
    fi

    case $FUNC_OPT in
        1)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Injetando Shaders via Cloud...${NC}"
            
            if download_verified "$REMOTE_ARB1" "$TMP_DIR/shaders.bin" 1024 && \
               download_verified "$REMOTE_ARB3" "$TMP_DIR/optional_shader.bin" 1024; then
                inject_file "$TMP_DIR/shaders.bin" "${FF_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
                inject_file "$TMP_DIR/optional_shader.bin" "${FF_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D"
                ESTADO[1]=1
                echo -e "\n${GREEN}[+] Shaders Injetados! Abra o Free Fire.${NC}"
            else
                echo -e "\n${RED}[!] Falha na injeção. Arquivos inválidos ou rede fora.${NC}"
            fi
            ;;
        2)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Injetando Fileinfos via Cloud...${NC}"
            
            if download_verified "$REMOTE_ARB2" "$TMP_DIR/fileinfo" 512 && \
               download_verified "$REMOTE_ARB4" "$TMP_DIR/fileinfo_opt" 512; then
                inject_file "$TMP_DIR/fileinfo" "${FF_DIR}/fileinfo"
                inject_file "$TMP_DIR/fileinfo_opt" "${FF_DIR}/optionalavatarres/fileinfo"
                ESTADO[2]=1
                echo -e "\n${GREEN}[+] Fileinfos Injetados! Abra o Free Fire.${NC}"
            else
                echo -e "\n${RED}[!] Falha na injeção. Arquivos inválidos ou rede fora.${NC}"
            fi
            ;;
        3)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Injetando Pacote Completo via Cloud...${NC}"
            
            local_ok=1
            download_verified "$REMOTE_ARB1" "$TMP_DIR/shaders.bin" 1024 || local_ok=0
            download_verified "$REMOTE_ARB3" "$TMP_DIR/optional_shader.bin" 1024 || local_ok=0
            download_verified "$REMOTE_ARB2" "$TMP_DIR/fileinfo" 512 || local_ok=0
            download_verified "$REMOTE_ARB4" "$TMP_DIR/fileinfo_opt" 512 || local_ok=0

            if [ "$local_ok" -eq 1 ]; then
                inject_file "$TMP_DIR/shaders.bin" "${FF_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
                inject_file "$TMP_DIR/optional_shader.bin" "${FF_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D"
                inject_file "$TMP_DIR/fileinfo" "${FF_DIR}/fileinfo"
                inject_file "$TMP_DIR/fileinfo_opt" "${FF_DIR}/optionalavatarres/fileinfo"
                ESTADO[3]=1
                echo -e "\n${GREEN}[+] Pacote Completo Injetado! Abra o Free Fire.${NC}"
            else
                echo -e "\n${RED}[!] Falha na injeção. Arquivos inválidos ou rede fora.${NC}"
            fi
            ;;
        0)
            printf "\033c"
            rm -rf "$TMP_DIR" 2>/dev/null
            exit 0
            ;;
        *)
            continue
            ;;
    esac

    echo -e "\n${CYAN}Pressione ENTER para voltar ao menu...${NC}"
    read -r < /dev/tty
done
