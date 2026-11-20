#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_ASSETS_DIR="/storage/emulated/0/Android/data/${FF_PACKAGE}/files/contentcache/Optional/android"

# ⚠️ LINKS APONTANDO PRA OFUSCAÇÃO (GITHUB) ⚠️
REMOTE_ARB1="https://raw.githubusercontent.com/Pkdev730/Holograma/main/bkp_1.txt"
REMOTE_ARB2="https://raw.githubusercontent.com/Pkdev730/Holograma/main/data_02.dat"
REMOTE_ARB3="https://raw.githubusercontent.com/Pkdev730/Holograma/main/texture_3.bin"
REMOTE_ARB4="https://raw.githubusercontent.com/Pkdev730/Holograma/main/cfg_4.db"

declare -A ESTADO
ESTADO[1]=0
ESTADO[2]=0

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

        echo -e "${YELLOW}[*] Desativando mods e restaurando originais via Stream...${NC}"
        
        adb shell "rm -f ${FF_ASSETS_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
        adb shell "rm -f ${FF_ASSETS_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D"

        # Baixa os fileinfos originais (camuflados) e restaura
        curl -s "$REMOTE_ARB2" | adb shell "cat > ${FF_ASSETS_DIR}/fileinfo"
        curl -s "$REMOTE_ARB4" | adb shell "cat > ${FF_ASSETS_DIR}/optionalavatarres/fileinfo"

        ESTADO[1]=0
        ESTADO[2]=0

        echo -e "${GREEN}[+] Bypass concluído! Originais restaurados.${NC}"
        sleep 3
        continue
    fi

    case $FUNC_OPT in
        1)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Injetando Shaders via Cloud...${NC}"
            adb shell "mkdir -p ${FF_ASSETS_DIR}/gameassetbundles"
            adb shell "mkdir -p ${FF_ASSETS_DIR}/optionalavatarres/gameassetbundles"
            
            curl -s "$REMOTE_ARB1" | adb shell "cat > ${FF_ASSETS_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
            curl -s "$REMOTE_ARB3" | adb shell "cat > ${FF_ASSETS_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D"

            ESTADO[1]=1
            echo -e "\n${GREEN}[+] Shaders Injetados! Abra o Free Fire.${NC}"
            ;;
        2)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Injetando Fileinfos via Cloud...${NC}"
            
            curl -s "$REMOTE_ARB2" | adb shell "cat > ${FF_ASSETS_DIR}/fileinfo"
            curl -s "$REMOTE_ARB4" | adb shell "cat > ${FF_ASSETS_DIR}/optionalavatarres/fileinfo"

            ESTADO[2]=1
            echo -e "\n${GREEN}[+] Fileinfos Injetados! Aimbot aplicado.${NC}"
            ;;
        0)
            printf "\033c"
            exit 0
            ;;
        *)
            continue
            ;;
    esac

    echo -e "\n${CYAN}Pressione ENTER para voltar ao menu...${NC}"
    read -r < /dev/tty
done
