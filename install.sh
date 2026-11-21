#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_DATA_ROOT="/storage/emulated/0/Android/data/${FF_PACKAGE}"
FF_ASSETS_DIR="${FF_DATA_ROOT}/files/contentcache/Optional/android"

REMOTE_ZIP="https://raw.githubusercontent.com/Pkdev730/Holograma/main/HOLOGRAMA%20VIP.zip"
TMP_DIR="/data/data/com.termux/files/usr/tmp/ghost_cloud"

SHADER_ORIGINAL="shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D"
SHADER_MOD="shaders.pedroomods~vip~3D"

# --- CHECA DEPENDÊNCIAS ---
for cmd in adb curl unzip find; do
    if ! command -v $cmd &> /dev/null; then
        printf "\033c"
        echo -e "${RED}[!] Falta o pacote: $cmd. Rode: pkg install android-tools curl unzip${NC}"
        exit 1
    fi
done

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
    echo -n "IP:PORTA de PAREAMENTO: "; read -r PAIR_ADDR < /dev/tty
    echo -n "Código de 6 dígitos: "; read -r PAIR_CODE < /dev/tty
    echo -e "\n${YELLOW}[*] Pareando dispositivos...${NC}"
    adb pair $PAIR_ADDR $PAIR_CODE
    echo -n "IP:PORTA de CONEXÃO: "; read -r CONN_ADDR < /dev/tty
    echo -e "${YELLOW}[*] Estabelecendo conexão segura...${NC}"
    adb connect $CONN_ADDR
    sleep 1
    if [ "$(adb get-state 2>/dev/null | tr -d '\r\n')" != "device" ]; then
        echo -e "${RED}[!] Falha na conexão. Verifique os dados e tente novamente.${NC}"; exit 1
    fi
fi

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

echo -n "Digite a sua Key (ex: External-teste1): "; read -r USER_KEY < /dev/tty
if [ -z "$USER_KEY" ]; then echo -e "${RED}[!] Key vazia. Abortando.${NC}"; exit 1; fi

echo -e "${YELLOW}[*] Verificando Key no servidor...${NC}"
FIREBASE_RESPONSE=$(curl -s --max-time 5 "${FIREBASE_URL}/.json")
if [ -z "$FIREBASE_RESPONSE" ] || [ "$FIREBASE_RESPONSE" == "null" ]; then
    echo -e "${RED}[!] Falha ao conectar ou banco vazio.${NC}"; exit 1
fi
STATUS=$(echo "$FIREBASE_RESPONSE" | grep -o "\"$USER_KEY\".*\"status\":\"ativada\"" | head -n 1)
if [ -z "$STATUS" ]; then echo -e "${RED}[!] Key não encontrada, inativa ou expirada.${NC}"; exit 1; fi

echo -e "${GREEN}[+] Acesso Autorizado! Licença Válida.${NC}"
sleep 2

# --- MENU PRINCIPAL ---
declare -A ESTADO
ESTADO[1]=0

while true; do
    printf "\033c"
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${WHITE}              GHOST REMOTE                ${NC}"
    echo -e "${PURPLE}==========================================${NC}\n"

    status() {
        if [ "${ESTADO[$1]}" -eq 1 ]; then echo -e "${GREEN}[ON]${NC}"; else echo -e "${RED}[OFF]${NC}"; fi
    }

    echo -e "${CYAN}┌── MODS FREE FIRE (ZIP CLOUD) ──────────┐${NC}"
    echo -e "  [1] Injetar ESP/Chams (Shaders) $(status 1)"
    echo -e "  [2] Desativar Holograma (Nuvem)"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"

    echo -e "\n${RED}┌── DESCONECTAR / LIMPAR (BYPASS) ───────┐${NC}"
    echo -e "  [99] Limpar Rastros e Fechar Sessão"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"

    echo -e "\n  [0] Encerrar Sessão"
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    case $FUNC_OPT in
        99)
            echo -e "\n${RED}[!] AVISO: Vai fechar o jogo e apagar todas as pastas temporárias e caches locais.${NC}"
            echo -n "Tem certeza? (s/n): "
            read -r CONFIRMA < /dev/tty

            if [ "$CONFIRMA" == "s" ]; then
                echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
                adb shell am force-stop $FF_PACKAGE
                sleep 1

                echo -e "${YELLOW}[*] Limpando rastros e pastas temporárias...${NC}"
                rm -rf "$TMP_DIR"
                rm -rf "/sdcard/Download/ff_original_backup" 
                
                echo -e "${GREEN}[+] Faxina concluída! Rastros apagados.${NC}"
                ESTADO[1]=0
                sleep 3
            fi
            ;;

        1)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Baixando e injetando mod da nuvem...${NC}"
            rm -rf "$TMP_DIR"
            mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip"

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar o ZIP.${NC}"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content"
            
            # A CORREÇÃO: O find agora tem a barra antes pra não confundir com REMOVER
            SRC_MOD=$(find "${TMP_DIR}/content" -type d -name "com.dts.freefireth" -path "*/HOLOGRAMA FREE FIRE NORMAL/*" | head -n 1)

            if [ -z "$SRC_MOD" ]; then
                echo -e "${RED}[!] Pasta do MOD não encontrada.${NC}"; sleep 3; continue
            fi

            echo -e "${CYAN}  [+] Limpando shaders antigos...${NC}"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_ORIGINAL}'"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_MOD}'"
            
            echo -e "${CYAN}  [+] Injetando holograma...${NC}"
            adb push "$SRC_MOD/." "${FF_DATA_ROOT}/" > /dev/null
            
            ESTADO[1]=1
            echo -e "\n${GREEN}[+] Holograma Injetado! Abra o Free Fire.${NC}"
            rm -rf "$TMP_DIR"
            ;;

        2)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1

            echo -e "${YELLOW}[*] Baixando o pacote de restauração da nuvem...${NC}"
            rm -rf "$TMP_DIR"
            mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip"

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar o ZIP.${NC}"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content"
            
            # A CORREÇÃO: O find com barra pra pegar SÓ a pasta REMOVER
            SRC_RESTORE=$(find "${TMP_DIR}/content" -type d -name "com.dts.freefireth" -path "*/REMOVER HOLOGRAMA FREE FIRE NORMAL/*" | head -n 1)

            if [ -z "$SRC_RESTORE" ]; then
                echo -e "${RED}[!] Pasta REMOVER não encontrada no ZIP.${NC}"; sleep 3; continue
            fi

            echo -e "${CYAN}  [+] Limpando shaders modificados...${NC}"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_ORIGINAL}'"
            adb shell "rm -f '${FF_ASSETS_DIR}/gameassetbundles/${SHADER_MOD}'"

            echo -e "${CYAN}  [+] Restaurando originais da nuvem...${NC}"
            adb push "$SRC_RESTORE/." "${FF_DATA_ROOT}/" > /dev/null
            
            ESTADO[1]=0
            echo -e "\n${GREEN}[+] Holograma Desativado! Original de volta.${NC}"
            rm -rf "$TMP_DIR"
            ;;

        0)
            printf "\033c"
            exit 0
            ;;
    esac

    echo -e "\n${CYAN}Pressione ENTER para continuar...${NC}"
    read -r < /dev/tty
done
