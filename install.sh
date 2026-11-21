#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; PURPLE='\033[0;35m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- CONFIGURAÇÕES ---
FIREBASE_URL="https://external-serv-default-rtdb.firebaseio.com"
FF_PACKAGE="com.dts.freefireth"
FF_DIR="/storage/emulated/0/Android/data/${FF_PACKAGE}/files/contentcache/Optional/android"
BACKUP_DIR="/sdcard/Download/ff_original_backup"
TMP_DIR="/data/data/com.termux/files/usr/tmp/ghost"

# LINK DO ZIP NO GITHUB
REMOTE_ZIP="https://raw.githubusercontent.com/Pkdev730/Holograma/main/assets.zip"

# --- CHECA DEPENDÊNCIAS ---
for cmd in adb curl unzip; do
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
        echo -e "${RED}[!] Falha na conexão. Verifique os dados e tente novamente.${NC}"
        exit 1
    fi
fi

printf "\033c"
echo -e "${PURPLE}==========================================${NC}"
echo -e "${WHITE}             VALIDAÇÃO DE LICENÇA         ${NC}"
echo -e "${PURPLE}==========================================${NC}\n"

echo -n "Digite a sua Key (ex: External-teste1): "
read -r USER_KEY < /dev/tty

if [ -z "$USER_KEY" ]; then
    echo -e "${RED}[!] Key vazia. Abortando.${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Verificando Key no servidor...${NC}"
FIREBASE_RESPONSE=$(curl -s --max-time 5 "${FIREBASE_URL}/.json")

if [ -z "$FIREBASE_RESPONSE" ] || [ "$FIREBASE_RESPONSE" == "null" ]; then
    echo -e "${RED}[!] Falha ao conectar ou banco vazio.${NC}"
    exit 1
fi

STATUS=$(echo "$FIREBASE_RESPONSE" | grep -o "\"$USER_KEY\".*\"status\":\"ativada\"" | head -n 1)

if [ -z "$STATUS" ]; then
    echo -e "${RED}[!] Key não encontrada, inativa ou expirada.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Acesso Autorizado! Licença Válida.${NC}"
sleep 2

# --- MENU PRINCIPAL ---
declare -A ESTADO
for i in 1 2 3; do ESTADO[$i]=0; done

while true; do
    printf "\033c"
    echo -e "${PURPLE}==========================================${NC}"
    echo -e "${WHITE}              GHOST REMOTE                ${NC}"
    echo -e "${PURPLE}==========================================${NC}\n"

    status() {
        if [ "${ESTADO[$1]}" -eq 1 ]; then echo -e "${GREEN}[ON]${NC}"; else echo -e "${RED}[OFF]${NC}"; fi
    }

    echo -e "${CYAN}┌── MODS FREE FIRE ──────────────────────┐${NC}"
    echo -e "  [1] Injetar ESP/Chams (Shaders) $(status 1)"
    echo -e "  [2] Injetar Aimbot (Hook/Assets) $(status 2)"
    echo -e "  [3] Injetar Todos os Mods        $(status 3)"
    echo -e "${CYAN}└────────────────────────────────────────┘${NC}"

    echo -e "\n${RED}┌── DESCONECTAR / LIMPAR (BYPASS) ───────┐${NC}"
    echo -e "  [99] Restaurar Originais e Limpar Cache"
    echo -e "${RED}└────────────────────────────────────────┘${NC}"

    echo -e "\n  [0] Encerrar Sessão"
    echo -n "  » Selecione: "
    read -r FUNC_OPT < /dev/tty

    if [ "$FUNC_OPT" == "99" ]; then
        echo -e "\n${RED}[!] AVISO: Isso vai limpar os mods e restaurar o Free Fire original.${NC}"
        echo -n "Tem certeza? (s/n): "
        read -r CONFIRMA < /dev/tty

        if [ "$CONFIRMA" == "s" ]; then
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 1
            
            echo -e "${YELLOW}[*] Removendo travas de arquivo...${NC}"
            adb shell "chattr -i ${FF_DIR}/gameassetbundles/* 2>/dev/null || chmod 644 ${FF_DIR}/gameassetbundles/* 2>/dev/null"

            echo -e "${YELLOW}[*] Restaurando arquivos originais do backup...${NC}"
            if [ -d "${BACKUP_DIR}" ]; then
                adb shell "rm -rf ${FF_DIR}/gameassetbundles"
                adb shell "rm -rf ${FF_DIR}/optionalavatarres"
                adb shell "cp -r ${BACKUP_DIR}/* ${FF_DIR}/"
                echo -e "${GREEN}[+] Bypass concluído! Originais restaurados.${NC}"
            else
                echo -e "${RED}[!] Backup não encontrado. Limpando cache pra o jogo baixar originais...${NC}"
                adb shell "rm -rf ${FF_DIR}/gameassetbundles"
                adb shell "rm -rf ${FF_DIR}/optionalavatarres"
            fi
            
            for i in 1 2 3; do ESTADO[$i]=0; done
            sleep 3
            continue
        fi
    fi

    case $FUNC_OPT in
        1|2|3)
            echo -e "\n${YELLOW}[*] Fechando o Free Fire...${NC}"
            adb shell am force-stop $FF_PACKAGE
            sleep 2

            if [ ! -d "${BACKUP_DIR}" ]; then
                echo -e "${YELLOW}[*] Criando backup de segurança do jogo original...${NC}"
                adb shell "mkdir -p ${BACKUP_DIR}"
                adb shell "cp -r ${FF_DIR}/gameassetbundles ${BACKUP_DIR}/"
                adb shell "cp -r ${FF_DIR}/optionalavatarres ${BACKUP_DIR}/"
                adb shell "cp ${FF_DIR}/fileinfo ${BACKUP_DIR}/"
                adb shell "cp ${FF_DIR}/optionalavatarres/fileinfo ${BACKUP_DIR}/"
            fi

            echo -e "${YELLOW}[*] Baixando pacote de assets do GitHub...${NC}"
            rm -rf "$TMP_DIR"
            mkdir -p "$TMP_DIR"
            
            curl -sL "$REMOTE_ZIP" -o "${TMP_DIR}/assets.zip"

            if [ ! -s "${TMP_DIR}/assets.zip" ]; then
                echo -e "${RED}[!] Falha no download do ZIP. Verifica o link.${NC}"
                sleep 3
                continue
            fi

            echo -e "${YELLOW}[*] Extraindo arquivos temporários...${NC}"
            unzip -q -o "${TMP_DIR}/assets.zip" -d "${TMP_DIR}/extracted"
            
            # As vezes o zip extrai numa subpasta "assets/". Vamos procurar os html_proxyarb
            SRC_DIR=$(find "${TMP_DIR}/extracted" -name "html_proxyarb1.html" -exec dirname {} \; | head -n 1)

            if [ -z "$SRC_DIR" ]; then
                echo -e "${RED}[!] Arquivos html_proxyarb não encontrados no zip.${NC}"
                sleep 3
                continue
            fi

            echo -e "${YELLOW}[*] Injetando mods via ADB Push...${NC}"
            
            adb shell "mkdir -p ${FF_DIR}/gameassetbundles"
            adb shell "mkdir -p ${FF_DIR}/optionalavatarres/gameassetbundles"
            
            # Injeção (Opção 1 ou 3)
            if [ "$FUNC_OPT" == "1" ] || [ "$FUNC_OPT" == "3" ]; then
                echo -e "${CYAN}  [+] Injetando Shaders Principais...${NC}"
                adb push "${SRC_DIR}/html_proxyarb1.html" "${FF_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D" >/dev/null
                adb push "${SRC_DIR}/html_proxyarb2.html" "${FF_DIR}/gameassetbundles/shaders.OMFd4hA1zxkPVCeTGXNDssFQbgI~3D" >/dev/null
                
                echo -e "${CYAN}  [+] Injetando Shaders de Avatar...${NC}"
                adb push "${SRC_DIR}/html_proxyarb3.html" "${FF_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D" >/dev/null
                adb push "${SRC_DIR}/html_proxyarb4.html" "${FF_DIR}/optionalavatarres/gameassetbundles/optionalavatarres_commonab_shader.YXsllDlwiET7~2Flua2jgC6ucxzic~3D" >/dev/null
            fi

            # Injeção (Opção 2 ou 3)
            if [ "$FUNC_OPT" == "2" ] || [ "$FUNC_OPT" == "3" ]; then
                echo -e "${CYAN}  [+] Injetando Fileinfos (Aimbot)...${NC}"
                adb push "${SRC_DIR}/html_proxyarb3.html" "${FF_DIR}/fileinfo" >/dev/null
                adb push "${SRC_DIR}/html_proxyarb4.html" "${FF_DIR}/optionalavatarres/fileinfo" >/dev/null
            fi

            echo -e "${YELLOW}[*] Aplicando trava de leitura (Bypass de escrita)...${NC}"
            adb shell "chattr +i ${FF_DIR}/gameassetbundles/* 2>/dev/null || chmod 444 ${FF_DIR}/gameassetbundles/*"
            adb shell "chattr +i ${FF_DIR}/optionalavatarres/gameassetbundles/* 2>/dev/null || chmod 444 ${FF_DIR}/optionalavatarres/gameassetbundles/*"
            adb shell "chmod 444 ${FF_DIR}/fileinfo 2>/dev/null"
            adb shell "chmod 444 ${FF_DIR}/optionalavatarres/fileinfo 2>/dev/null"

            ESTADO[$FUNC_OPT]=1
            echo -e "\n${GREEN}[+] Módulo Injetado e Travado! Abra o Free Fire.${NC}"
            
            # Limpa os temporários
            rm -rf "$TMP_DIR"
            ;;
        0)
            printf "\033c"
            exit 0
            ;;
        *)
            continue
            ;;
    esac

    echo -e "\n${CYAN}Pressione ENTER para continuar...${NC}"
    read -r < /dev/tty
done
