#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'
BLACK='\033[1;30m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_DATA_ROOT="/storage/emulated/0/Android/data/${FF_PACKAGE}"
FF_ASSETS_DIR="${FF_DATA_ROOT}/files/contentcache/Optional/android"

REMOTE_ZIP="https://raw.githubusercontent.com/Pkdev730/Holograma/main/HOLOGRAMA%20VIP.zip"
TMP_DIR="/data/data/com.termux/files/usr/tmp/ghost_cloud"

DATA_FALSA="202611211357.00"
LOGCAT_PKG="com.dp.logcatapp"

# --- CHECA DEPENDÊNCIAS ---
for cmd in adb curl unzip find; do
    if ! command -v $cmd &> /dev/null; then
        printf "\033c"
        echo -e "${RED}[!] Falta: $cmd. Rode: pkg install android-tools curl unzip${NC}"
        exit 1
    fi
done

printf "\033c"
echo -e "${BLACK}==========================================${NC}"
echo -e "${BLACK}              REMOTE 3ENVOLV              ${NC}"
echo -e "${BLACK}==========================================${NC}\n"

# --- CONEXÃO ADB ---
ADB_STATE=$(adb get-state 2>/dev/null | tr -d '\r\n')
if [ "$ADB_STATE" != "device" ]; then
    echo -e "${WHITE}Etapa 1: Conexão com o Dispositivo${NC}"
    echo -e "${YELLOW}ADB não conectado. Configure agora.${NC}\n"
    echo -n "IP:PORTA de PAREAMENTO: "; read -r PAIR_ADDR < /dev/tty
    echo -n "Código de 6 dígitos:    "; read -r PAIR_CODE < /dev/tty
    adb pair $PAIR_ADDR $PAIR_CODE >/dev/null 2>&1
    echo -n "IP:PORTA de CONEXÃO: "; read -r CONN_ADDR < /dev/tty
    adb connect $CONN_ADDR >/dev/null 2>&1
    if [ "$(adb get-state 2>/dev/null | tr -d '\r\n')" != "device" ]; then
        echo -e "${RED}[!] Falha na conexão.${NC}"; exit 1
    fi
fi

# --- LICENÇA ---
printf "\033c"
echo -e "${BLACK}==========================================${NC}"
echo -e "${BLACK}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${BLACK}==========================================${NC}\n"
echo -n "Digite sua Key: "; read -r USER_KEY < /dev/tty
FIREBASE_RESPONSE=$(curl -s --max-time 5 "${FIREBASE_URL}/.json")
STATUS=$(echo "$FIREBASE_RESPONSE" | grep -o "\"$USER_KEY\".*\"status\":\"ativada\"" | head -n 1)
if [ -z "$STATUS" ]; then echo -e "${RED}[!] Key inválida.${NC}"; exit 1; fi
echo -e "${GREEN}[+] Acesso Autorizado!${NC}"
sleep 2

# --- MENU ---
declare -A ESTADO
ESTADO[1]=0

while true; do
    printf "\033c"
    echo -e "${BLACK}==========================================${NC}"
    echo -e "${BLACK}              REMOTE 3ENVOLV              ${NC}"
    echo -e "${BLACK}==========================================${NC}\n"

    status() {
        [ "${ESTADO[$1]}" -eq 1 ] && echo -e "${GREEN}[ON]${NC}" || echo -e "${RED}[OFF]${NC}"
    }

    echo -e "${CYAN}┌── Bypass reina ────────────────────────┐${NC}"
    echo -e "  [1] Injetar Holograma $(status 1)"
    echo -e "  [2] Remover Holograma"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"
    echo -e "\n${RED}┌── ENCERRAR SESSÃO ──────────────────────┐${NC}"
    echo -e "  [99] Bypass"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"
    echo -e "\n  [0] Sair"
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    case $FUNC_OPT in
        99)
            echo -e "\n${RED}[!] Vai apagar rastros e fechar sessão.${NC}"
            echo -n "Tem certeza? (s/n): "
            read -r CONFIRMA < /dev/tty
            if [ "$CONFIRMA" == "s" ]; then
                echo -e "${YELLOW}[*] Executando bypass...${NC}"

                adb shell "pm clear $LOGCAT_PKG" >/dev/null 2>&1
                adb shell "rm -f /data/data/com.termux/files/home/.bash_history" >/dev/null 2>&1
                adb shell "rm -rf /data/data/com.termux/files/usr/tmp/" >/dev/null 2>&1
                adb disconnect >/dev/null 2>&1

                rm -rf "$TMP_DIR" "/sdcard/Download/ff_original_backup" "/sdcard/Download/*.zip" "/sdcard/Download/*.sh"
                history -c
                rm -f ~/.bash_history /data/data/com.termux/files/home/.bash_history
                SCRIPT_PATH="$(realpath $0)"
                rm -f "$SCRIPT_PATH"

                echo -e "${GREEN}[+] Rastros apagados. Sessão encerrada.${NC}"
                echo -e "${YELLOW}[!] Desligue a Depuração Sem Fio manualmente nas configurações.${NC}"
                sleep 2
                exit 0
            fi
            ;;

        1)
            echo -e "\n${CYAN}[*] Escolha a cor do Holograma:${NC}"
            echo -e "  [1] HOLOGRAMA ROSA"
            echo -e "  [2] HOLOGRAMA BRANCO"
            echo -e "  [3] HOLOGRAMA VERDE"
            echo -n "  » Opção: "
            read -r COR_OPT < /dev/tty

            if [ "$COR_OPT" == "1" ]; then
                NOME_COR="ROSA"
            elif [ "$COR_OPT" == "2" ]; then
                NOME_COR="BRANCO"
            elif [ "$COR_OPT" == "3" ]; then
                NOME_COR="VERDE"
            else
                echo -e "${RED}[!] Opção inválida.${NC}"; sleep 2; continue
            fi

            echo -e "\n${CYAN}[*] Injetando Holograma...${NC}"

            rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip" >/dev/null 2>&1

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar.${NC}"
                rm -rf "$TMP_DIR"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content" >/dev/null 2>&1

            SRC_MOD=$(find "${TMP_DIR}/content" -type d -name "com.dts.freefireth" -path "*HOLOGRAMA $NOME_COR*" | head -n 1)

            if [ -z "$SRC_MOD" ]; then
                echo -e "${RED}[!] Pasta do Holograma $NOME_COR não encontrada.${NC}"
                sleep 3; continue
            fi

            # A faxina coringa: apaga tudo que é shader.* na pasta
            adb shell "rm -f ${FF_ASSETS_DIR}/gameassetbundles/shaders.*" >/dev/null 2>&1
            
            adb push "$SRC_MOD/." "${FF_DATA_ROOT}/" > /dev/null 2>&1

            adb shell "find '${FF_ASSETS_DIR}/gameassetbundles' -exec touch -t ${DATA_FALSA} {} \; 2>/dev/null" >/dev/null 2>&1
            adb shell "touch -t ${DATA_FALSA} '${FF_ASSETS_DIR}/fileinfo' 2>/dev/null" >/dev/null 2>&1

            ESTADO[1]=1
            echo -e "\n${GREEN}[+] Holograma $NOME_COR ativado!${NC}"
            echo -e "${YELLOW}[!] Abra o Free Fire.${NC}"
            rm -rf "$TMP_DIR"
            ;;

        2)
            echo -e "\n${CYAN}[*] Removendo bypass...${NC}"
            echo -e "${YELLOW}[!] Feche o Free Fire manualmente antes de continuar.${NC}"
            echo -n "Fechou? (s/n): "
            read -r FECHOU < /dev/tty
            if [ "$FECHOU" != "s" ]; then
                echo -e "${RED}[!] Feche o jogo antes de remover.${NC}"
                sleep 2; continue
            fi

            echo -e "\n${CYAN}[*] Removendo Holograma...${NC}"
            rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR/download"
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/master.zip" >/dev/null 2>&1

            if [ ! -s "${TMP_DIR}/master.zip" ]; then
                echo -e "${RED}[!] Falha ao baixar.${NC}"
                rm -rf "$TMP_DIR"; sleep 3; continue
            fi

            unzip -q -o "${TMP_DIR}/master.zip" -d "${TMP_DIR}/content" >/dev/null 2>&1

            SRC_RESTORE=$(find "${TMP_DIR}/content" -type d -name "com.dts.freefireth" -path "*REMOVER*" | head -n 1)

            if [ -n "$SRC_RESTORE" ]; then
                # A mesma faxina coringa, antes de restaurar
                adb shell "rm -f ${FF_ASSETS_DIR}/gameassetbundles/shaders.*" >/dev/null 2>&1

                adb push "$SRC_RESTORE/." "${FF_DATA_ROOT}/" > /dev/null 2>&1

                adb shell "find '${FF_ASSETS_DIR}/gameassetbundles' -exec touch -t ${DATA_FALSA} {} \; 2>/dev/null" >/dev/null 2>&1
                adb shell "touch -t ${DATA_FALSA} '${FF_ASSETS_DIR}/fileinfo' 2>/dev/null" >/dev/null 2>&1

                ESTADO[1]=0
                echo -e "${GREEN}[+] Bypass removido!${NC}"
                echo -e "${YELLOW}[!] Abra o Free Fire.${NC}"
            else
                echo -e "${RED}[!] Falha na remoção.${NC}"
            fi
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
