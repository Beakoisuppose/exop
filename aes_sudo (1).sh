#!/bin/bash
#-------------------AUTO SETTING BASH SCRIPT BY PARSIFAL ------------------------

set -e

# =========================
# ROOT CHECK
# =========================

if [ "$EUID" -ne 0 ]; then
    echo "Ошибка: запусти скрипт от root"
    exit 1
fi

# =========================
# GLOBAL VARIABLES
# =========================

DEVICE=""

# Флаги выбранных действий
DO_HOSTNAME=0
DO_USER=0
DO_BANNER=0
DO_DNS=0
DO_IP_FORWARD=0
DO_NAT=0
DO_GRE=0
DO_ROUTES=0
DO_SSH=0
DO_OSPF=0
DO_DHCP=0
DO_RAID_NFS=0
DO_CHRONY=0
DO_DOCKER_WIKI=0

# Основные значения
NEW_HOSTNAME=""
NEW_USER=""
NEW_UID=""
BANNER_TEXT=""
DNS_SERVER=""

# NAT
WAN_IF=""
LAN_IF1=""
LAN_IF2=""

# GRE
GRE_NAME="gre1"
GRE_LOCAL_IP=""
GRE_REMOTE_IP=""
GRE_TUNNEL_IP=""

# Routes
ROUTE_NET1=""
ROUTE_VIA1=""
ROUTE_NET2=""
ROUTE_VIA2=""

# Config paths
SSH_CONFIG_PATH=""
FRR_CONFIG_PATH=""
DHCP_CONFIG_PATH=""

# RAID + NFS
RAID_NFS_MODE=""

RAID_DEV="/dev/md0"
RAID_LEVEL="5"
RAID_DISK1=""
RAID_DISK2=""
RAID_DISK3=""
RAID_MOUNT="/mnt/raid5"
RAID_NFS_DIR="/mnt/raid5/nfs"
RAID_ALLOWED_NET=""

NFS_SERVER_IP=""
NFS_REMOTE_DIR="/mnt/raid5/nfs"
NFS_CLIENT_MOUNT="/mnt/nfs"

# Chrony / NTP
CHRONY_MODE=""
NTP_SERVER_IP=""
NTP_TIMEZONE=""

# Docker + MediaWiki
WIKI_DIR="/root"
WIKI_FILE="wiki.yml"
WIKI_PATH="/root/wiki.yml"

# =========================
# HELPERS
# =========================

mark() {
    if [ "$1" -eq 1 ]; then
        echo "+"
    else
        echo " "
    fi
}

pause() {
    echo
    read -p "Нажми Enter для продолжения..."
}

# =========================
# MAIN MENU
# =========================

main_menu() {
    while true; do
        clear
        echo "===================================="
        echo "        AUTO SETUP SCRIPT"
        echo "===================================="
        echo "Выбери устройство:"
        echo "1) HQ-RTR"
        echo "2) BR-RTR"
        echo "3) ISP"
        echo "4) HQ-SRV"
        echo "5) BR-SRV"
        echo "6) HQ-CLI"
        echo "0) Выход"
        echo "===================================="

        read -p "Выбор: " choice

        case "$choice" in
            1)
                DEVICE="HQ-RTR"
                device_menu
                ;;
            2)
                DEVICE="BR-RTR"
                device_menu
                ;;
            3)
                DEVICE="ISP"
                device_menu
                ;;
            4)
                DEVICE="HQ-SRV"
                device_menu
                ;;
            5)
                DEVICE="BR-SRV"
                device_menu
                ;;
            6)
                DEVICE="HQ-CLI"
                device_menu
                ;;
            0)
                echo "Выход."
                exit 0
                ;;
            *)
                echo "Ошибка выбора."
                pause
                ;;
        esac
    done
}

# =========================
# DEVICE MENU
# =========================

device_menu() {
    while true; do
        clear
        echo "===================================="
        echo " Устройство: $DEVICE"
        echo "===================================="
        echo "[$(mark $DO_HOSTNAME)] 1) Hostname"
        echo "[$(mark $DO_USER)] 2) Пользователь"
        echo "[$(mark $DO_BANNER)] 3) Banner"
        echo "[$(mark $DO_DNS)] 4) DNS"
        echo "[$(mark $DO_IP_FORWARD)] 5) IP forwarding"
        echo "[$(mark $DO_NAT)] 6) NAT / iptables"
        echo "[$(mark $DO_GRE)] 7) GRE tunnel"
        echo "[$(mark $DO_ROUTES)] 8) Static routes"
        echo "[$(mark $DO_SSH)] 9) SSH config"
        echo "[$(mark $DO_OSPF)] 10) OSPF / FRR"
        echo "[$(mark $DO_DHCP)] 11) DHCP"
        echo "[$(mark $DO_RAID_NFS)] 12) RAID5 + NFS"
        echo "[$(mark $DO_CHRONY)] 13) Chrony / NTP"
        echo "[$(mark $DO_DOCKER_WIKI)] 14) Установка и настройка Docker на устройстве"
        echo "------------------------------------"
        echo "15) Показать введённые данные"
        echo "16) Применить настройки"
        echo "17) Сбросить выбранные параметры"
        echo "0) Назад"
        echo "===================================="

        read -p "Выбор: " action

        case "$action" in
            1) input_hostname ;;
            2) input_user ;;
            3) input_banner ;;
            4) input_dns ;;
            5) input_ip_forward ;;
            6) input_nat ;;
            7) input_gre ;;
            8) input_routes ;;
            9) input_ssh ;;
            10) input_ospf ;;
            11) input_dhcp ;;
            12) input_raid_nfs_menu ;;
            13) input_chrony_menu ;;
            14) input_docker_wiki ;;
            15) show_summary; pause ;;
            16) apply_menu ;;
            17) reset_params; pause ;;
            0) return ;;
            *) echo "Ошибка выбора."; pause ;;
        esac
    done
}

# =========================
# INPUT FUNCTIONS
# =========================

input_hostname() {
    clear
    echo "=== HOSTNAME ==="

    read -p "Введите hostname [$DEVICE]: " NEW_HOSTNAME
    NEW_HOSTNAME=${NEW_HOSTNAME:-$DEVICE}

    DO_HOSTNAME=1

    echo "Hostname сохранён: $NEW_HOSTNAME"
    echo "Параметр Hostname отмечен +"
    pause
}

input_user() {
    clear
    echo "=== USER ==="

    read -p "Введите имя пользователя [net_admin]: " NEW_USER
    NEW_USER=${NEW_USER:-net_admin}

    read -p "Введите UID пользователя [1010]: " NEW_UID
    NEW_UID=${NEW_UID:-1010}

    DO_USER=1

    echo "Пользователь сохранён: $NEW_USER"
    echo "UID сохранён: $NEW_UID"
    echo "Параметр Пользователь отмечен +"
    pause
}

input_banner() {
    clear
    echo "=== BANNER ==="

    read -p "Введите текст banner [------Hello Its $DEVICE-----]: " BANNER_TEXT
    BANNER_TEXT=${BANNER_TEXT:-"------Hello Its $DEVICE-----"}

    DO_BANNER=1

    echo "Banner сохранён: $BANNER_TEXT"
    echo "Параметр Banner отмечен +"
    pause
}

input_dns() {
    clear
    echo "=== DNS ==="

    read -p "Введите DNS server [8.8.8.8]: " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-8.8.8.8}

    DO_DNS=1

    echo "DNS сохранён: $DNS_SERVER"
    echo "Параметр DNS отмечен +"
    pause
}

input_ip_forward() {
    clear
    echo "=== IP FORWARDING ==="
    echo "Будет включён net.ipv4.ip_forward=1"

    DO_IP_FORWARD=1

    echo "Параметр IP forwarding отмечен +"
    pause
}

input_nat() {
    clear
    echo "=== NAT / IPTABLES ==="

    read -p "Введите WAN interface [enp0s3]: " WAN_IF
    WAN_IF=${WAN_IF:-enp0s3}

    read -p "Введите LAN interface 1 [enp0s8]: " LAN_IF1
    LAN_IF1=${LAN_IF1:-enp0s8}

    read -p "Введите LAN interface 2 [enp0s9]: " LAN_IF2
    LAN_IF2=${LAN_IF2:-enp0s9}

    DO_NAT=1

    echo "WAN сохранён: $WAN_IF"
    echo "LAN1 сохранён: $LAN_IF1"
    echo "LAN2 сохранён: $LAN_IF2"
    echo "Параметр NAT отмечен +"
    pause
}

input_gre() {
    clear
    echo "=== GRE TUNNEL ==="

    read -p "Введите имя GRE tunnel [gre1]: " GRE_NAME
    GRE_NAME=${GRE_NAME:-gre1}

    read -p "Введите local IP для GRE: " GRE_LOCAL_IP
    read -p "Введите remote IP для GRE: " GRE_REMOTE_IP
    read -p "Введите IP туннеля, например 10.10.10.1/30: " GRE_TUNNEL_IP

    DO_GRE=1

    echo "GRE tunnel сохранён: $GRE_NAME"
    echo "Local IP: $GRE_LOCAL_IP"
    echo "Remote IP: $GRE_REMOTE_IP"
    echo "Tunnel IP: $GRE_TUNNEL_IP"
    echo "Параметр GRE отмечен +"
    pause
}

input_routes() {
    clear
    echo "=== STATIC ROUTES ==="

    read -p "Введите сеть 1, например 192.168.99.0/25: " ROUTE_NET1
    read -p "Введите gateway для сети 1: " ROUTE_VIA1

    read -p "Введите сеть 2, например 172.17.0.0/29: " ROUTE_NET2
    read -p "Введите gateway для сети 2: " ROUTE_VIA2

    DO_ROUTES=1

    echo "Маршрут 1 сохранён: $ROUTE_NET1 via $ROUTE_VIA1"
    echo "Маршрут 2 сохранён: $ROUTE_NET2 via $ROUTE_VIA2"
    echo "Параметр Static routes отмечен +"
    pause
}

input_ssh() {
    clear
    echo "=== SSH CONFIG ==="

    read -p "Введите путь к sshd_config [/home/user/repo-for-exs/sshd_config]: " SSH_CONFIG_PATH
    SSH_CONFIG_PATH=${SSH_CONFIG_PATH:-/home/user/repo-for-exs/sshd_config}

    DO_SSH=1

    echo "Путь сохранён: $SSH_CONFIG_PATH"
    echo "Параметр SSH отмечен +"
    pause
}

input_ospf() {
    clear
    echo "=== OSPF / FRR ==="

    read -p "Введите путь к frr.conf [/home/user/repo-for-exs/frr.conf]: " FRR_CONFIG_PATH
    FRR_CONFIG_PATH=${FRR_CONFIG_PATH:-/home/user/repo-for-exs/frr.conf}

    DO_OSPF=1

    echo "Путь сохранён: $FRR_CONFIG_PATH"
    echo "Параметр OSPF отмечен +"
    pause
}

input_dhcp() {
    clear
    echo "=== DHCP ==="

    read -p "Введите путь к dhcpd.conf [/home/user/repo-for-exs/dhcpd.conf]: " DHCP_CONFIG_PATH
    DHCP_CONFIG_PATH=${DHCP_CONFIG_PATH:-/home/user/repo-for-exs/dhcpd.conf}

    DO_DHCP=1

    echo "Путь сохранён: $DHCP_CONFIG_PATH"
    echo "Параметр DHCP отмечен +"
    pause
}

# =========================
# RAID + NFS INPUT
# =========================

input_raid_nfs_menu() {
    while true; do
        clear
        echo "===================================="
        echo "        RAID5 + NFS"
        echo "===================================="
        echo "Устройство: $DEVICE"
        echo
        echo "1) Для сервера настройка"
        echo "2) Для клиента настройка"
        echo "0) Назад"
        echo "===================================="

        read -p "Выбор: " raid_choice

        case "$raid_choice" in
            1)
                input_raid_nfs_server
                return
                ;;
            2)
                input_raid_nfs_client
                return
                ;;
            0)
                return
                ;;
            *)
                echo "Ошибка выбора."
                pause
                ;;
        esac
    done
}

input_raid_nfs_server() {
    clear
    echo "=== RAID5 + NFS SERVER ==="
    echo "Рекомендуемое устройство: BR-SRV или HQ-SRV"
    echo

    read -p "Введите RAID устройство [/dev/md0]: " RAID_DEV
    RAID_DEV=${RAID_DEV:-/dev/md0}

    echo
    echo "Введите 3 диска для RAID5."
    echo "Пример: /dev/sdb /dev/sdc /dev/sdd"
    echo

    read -p "Диск 1 [/dev/sdb]: " RAID_DISK1
    RAID_DISK1=${RAID_DISK1:-/dev/sdb}

    read -p "Диск 2 [/dev/sdc]: " RAID_DISK2
    RAID_DISK2=${RAID_DISK2:-/dev/sdc}

    read -p "Диск 3 [/dev/sdd]: " RAID_DISK3
    RAID_DISK3=${RAID_DISK3:-/dev/sdd}

    read -p "Точка монтирования RAID [/mnt/raid5]: " RAID_MOUNT
    RAID_MOUNT=${RAID_MOUNT:-/mnt/raid5}

    read -p "Папка NFS [$RAID_MOUNT/nfs]: " RAID_NFS_DIR
    RAID_NFS_DIR=${RAID_NFS_DIR:-"$RAID_MOUNT/nfs"}

    read -p "Сеть клиента для доступа к NFS [192.168.200.0/28]: " RAID_ALLOWED_NET
    RAID_ALLOWED_NET=${RAID_ALLOWED_NET:-192.168.200.0/28}

    RAID_NFS_MODE="server"
    DO_RAID_NFS=1

    echo
    echo "Данные сохранены."
    echo "RAID mode: server"
    echo "RAID device: $RAID_DEV"
    echo "RAID level: 5"
    echo "Disks: $RAID_DISK1 $RAID_DISK2 $RAID_DISK3"
    echo "Mount: $RAID_MOUNT"
    echo "NFS dir: $RAID_NFS_DIR"
    echo "Allowed net: $RAID_ALLOWED_NET"
    echo
    echo "Параметр RAID5 + NFS отмечен +"
    pause
}

input_raid_nfs_client() {
    clear
    echo "=== NFS CLIENT ==="
    echo "Рекомендуемое устройство: HQ-CLI или BR-CLI"
    echo

    read -p "Введите IP NFS-сервера [192.168.100.62]: " NFS_SERVER_IP
    NFS_SERVER_IP=${NFS_SERVER_IP:-192.168.100.62}

    read -p "Удалённая NFS папка [/mnt/raid5/nfs]: " NFS_REMOTE_DIR
    NFS_REMOTE_DIR=${NFS_REMOTE_DIR:-/mnt/raid5/nfs}

    read -p "Локальная папка монтирования [/mnt/nfs]: " NFS_CLIENT_MOUNT
    NFS_CLIENT_MOUNT=${NFS_CLIENT_MOUNT:-/mnt/nfs}

    RAID_NFS_MODE="client"
    DO_RAID_NFS=1

    echo
    echo "Данные сохранены."
    echo "RAID/NFS mode: client"
    echo "NFS server: $NFS_SERVER_IP"
    echo "Remote dir: $NFS_REMOTE_DIR"
    echo "Local mount: $NFS_CLIENT_MOUNT"
    echo
    echo "Параметр RAID5 + NFS отмечен +"
    pause
}

# =========================
# CHRONY INPUT
# =========================

input_chrony_menu() {
    while true; do
        clear
        echo "===================================="
        echo "          CHRONY / NTP"
        echo "===================================="
        echo "Устройство: $DEVICE"
        echo
        echo "1) Для сервера настройка"
        echo "2) Для клиента настройка"
        echo "0) Назад"
        echo "===================================="

        read -p "Выбор: " chrony_choice

        case "$chrony_choice" in
            1)
                input_chrony_server
                return
                ;;
            2)
                input_chrony_client
                return
                ;;
            0)
                return
                ;;
            *)
                echo "Ошибка выбора."
                pause
                ;;
        esac
    done
}

input_chrony_server() {
    clear
    echo "=== CHRONY SERVER ==="
    echo "Будет создан backup:"
    echo "/etc/chrony.conf -> /etc/chrony.conf.bak"
    echo
    echo "В /etc/chrony.conf будут записаны:"
    echo "server 127.0.0.1 iburst prefer"
    echo "hwtimestamp *"
    echo "local stratum 5"
    echo "allow 0/0"
    echo

    CHRONY_MODE="server"
    DO_CHRONY=1

    echo "Параметр Chrony / NTP отмечен +"
    pause
}

input_chrony_client() {
    clear
    echo "=== CHRONY CLIENT ==="

    read -p "Введите IP-адрес NTP-сервера [172.16.4.1]: " NTP_SERVER_IP
    NTP_SERVER_IP=${NTP_SERVER_IP:-172.16.4.1}

    read -p "Введите часовой пояс [utc+5]: " NTP_TIMEZONE
    NTP_TIMEZONE=${NTP_TIMEZONE:-utc+5}

    CHRONY_MODE="client"
    DO_CHRONY=1

    echo
    echo "NTP server: $NTP_SERVER_IP"
    echo "Timezone: $NTP_TIMEZONE"
    echo
    echo "Параметр Chrony / NTP отмечен +"
    pause
}

# =========================
# DOCKER INPUT
# =========================

input_docker_wiki() {
    clear
    echo "=== DOCKER + MEDIAWIKI ==="
    echo "Будет выполнено:"
    echo "- отключение ahttpd"
    echo "- установка docker-ce и docker-compose"
    echo "- запуск docker"
    echo "- создание wiki.yml"
    echo "- запуск MediaWiki + MariaDB"
    echo

    read -p "Введите директорию для wiki.yml [/root]: " WIKI_DIR
    WIKI_DIR=${WIKI_DIR:-/root}

    WIKI_FILE="wiki.yml"
    WIKI_PATH="$WIKI_DIR/$WIKI_FILE"

    DO_DOCKER_WIKI=1

    echo
    echo "Данные сохранены."
    echo "Wiki compose file: $WIKI_PATH"
    echo "Параметр Docker + MediaWiki отмечен +"
    pause
}

# =========================
# SUMMARY
# =========================

show_summary() {
    clear
    echo "===================================="
    echo "       ПРОВЕРКА ДАННЫХ"
    echo "===================================="
    echo "Устройство: $DEVICE"
    echo

    if [ "$DO_HOSTNAME" -eq 1 ]; then
        echo "[+] Hostname: $NEW_HOSTNAME"
    fi

    if [ "$DO_USER" -eq 1 ]; then
        echo "[+] User: $NEW_USER"
        echo "    UID: $NEW_UID"
    fi

    if [ "$DO_BANNER" -eq 1 ]; then
        echo "[+] Banner: $BANNER_TEXT"
    fi

    if [ "$DO_DNS" -eq 1 ]; then
        echo "[+] DNS: $DNS_SERVER"
    fi

    if [ "$DO_IP_FORWARD" -eq 1 ]; then
        echo "[+] IP forwarding: net.ipv4.ip_forward=1"
    fi

    if [ "$DO_NAT" -eq 1 ]; then
        echo "[+] NAT:"
        echo "    WAN: $WAN_IF"
        echo "    LAN1: $LAN_IF1"
        echo "    LAN2: $LAN_IF2"
    fi

    if [ "$DO_GRE" -eq 1 ]; then
        echo "[+] GRE:"
        echo "    Tunnel: $GRE_NAME"
        echo "    Local: $GRE_LOCAL_IP"
        echo "    Remote: $GRE_REMOTE_IP"
        echo "    Tunnel IP: $GRE_TUNNEL_IP"
    fi

    if [ "$DO_ROUTES" -eq 1 ]; then
        echo "[+] Routes:"
        echo "    $ROUTE_NET1 via $ROUTE_VIA1"
        echo "    $ROUTE_NET2 via $ROUTE_VIA2"
    fi

    if [ "$DO_SSH" -eq 1 ]; then
        echo "[+] SSH config: $SSH_CONFIG_PATH"
    fi

    if [ "$DO_OSPF" -eq 1 ]; then
        echo "[+] FRR config: $FRR_CONFIG_PATH"
    fi

    if [ "$DO_DHCP" -eq 1 ]; then
        echo "[+] DHCP config: $DHCP_CONFIG_PATH"
    fi

    if [ "$DO_RAID_NFS" -eq 1 ]; then
        echo "[+] RAID5 + NFS:"

        if [ "$RAID_NFS_MODE" = "server" ]; then
            echo "    Mode: server"
            echo "    RAID device: $RAID_DEV"
            echo "    RAID level: 5"
            echo "    Disk 1: $RAID_DISK1"
            echo "    Disk 2: $RAID_DISK2"
            echo "    Disk 3: $RAID_DISK3"
            echo "    Mount: $RAID_MOUNT"
            echo "    NFS dir: $RAID_NFS_DIR"
            echo "    Allowed net: $RAID_ALLOWED_NET"
        fi

        if [ "$RAID_NFS_MODE" = "client" ]; then
            echo "    Mode: client"
            echo "    NFS server: $NFS_SERVER_IP"
            echo "    Remote dir: $NFS_REMOTE_DIR"
            echo "    Local mount: $NFS_CLIENT_MOUNT"
        fi
    fi

    if [ "$DO_CHRONY" -eq 1 ]; then
        echo "[+] Chrony / NTP:"

        if [ "$CHRONY_MODE" = "server" ]; then
            echo "    Mode: server"
            echo "    Backup: /etc/chrony.conf -> /etc/chrony.conf.bak"
            echo "    Config:"
            echo "      server 127.0.0.1 iburst prefer"
            echo "      hwtimestamp *"
            echo "      local stratum 5"
            echo "      allow 0/0"
        fi

        if [ "$CHRONY_MODE" = "client" ]; then
            echo "    Mode: client"
            echo "    Backup: /etc/chrony.conf -> /etc/chrony.conf.bak"
            echo "    NTP server: $NTP_SERVER_IP"
            echo "    Timezone: $NTP_TIMEZONE"
        fi
    fi

    if [ "$DO_DOCKER_WIKI" -eq 1 ]; then
        echo "[+] Docker + MediaWiki:"
        echo "    Compose file: $WIKI_PATH"
        echo "    Web port: 8080"
        echo "    MediaWiki container: wiki"
        echo "    MariaDB container: mariadb"
    fi

    echo
    echo "===================================="
    echo "        БУДУТ ВЫПОЛНЕНЫ ДЕЙСТВИЯ"
    echo "===================================="

    [ "$DO_HOSTNAME" -eq 1 ] && echo "- Установить hostname"
    [ "$DO_USER" -eq 1 ] && echo "- Создать пользователя"
    [ "$DO_BANNER" -eq 1 ] && echo "- Записать /etc/banner"
    [ "$DO_DNS" -eq 1 ] && echo "- Добавить DNS в /etc/resolv.conf"
    [ "$DO_IP_FORWARD" -eq 1 ] && echo "- Включить IP forwarding"
    [ "$DO_NAT" -eq 1 ] && echo "- Настроить iptables NAT/FORWARD"
    [ "$DO_GRE" -eq 1 ] && echo "- Поднять GRE tunnel"
    [ "$DO_ROUTES" -eq 1 ] && echo "- Добавить статические маршруты"
    [ "$DO_SSH" -eq 1 ] && echo "- Скопировать sshd_config"
    [ "$DO_OSPF" -eq 1 ] && echo "- Установить FRR и скопировать frr.conf"
    [ "$DO_DHCP" -eq 1 ] && echo "- Установить DHCP и скопировать dhcpd.conf"

    if [ "$DO_RAID_NFS" -eq 1 ]; then
        if [ "$RAID_NFS_MODE" = "server" ]; then
            echo "- Создать RAID5 и настроить NFS-сервер"
        fi

        if [ "$RAID_NFS_MODE" = "client" ]; then
            echo "- Настроить NFS-клиент и автомонтирование"
        fi
    fi

    if [ "$DO_CHRONY" -eq 1 ]; then
        if [ "$CHRONY_MODE" = "server" ]; then
            echo "- Настроить Chrony как NTP-сервер"
        fi

        if [ "$CHRONY_MODE" = "client" ]; then
            echo "- Настроить Chrony/NTP-клиент"
        fi
    fi

    [ "$DO_DOCKER_WIKI" -eq 1 ] && echo "- Установить Docker и запустить MediaWiki stack"

    echo "===================================="
}

# =========================
# APPLY MENU
# =========================

apply_menu() {
    show_summary
    echo
    read -p "Применить настройки? [y/N]: " confirm

    case "$confirm" in
        y|Y|yes|YES)
            apply_settings
            ;;
        *)
            echo "Применение отменено."
            pause
            ;;
    esac
}

# =========================
# APPLY SETTINGS
# =========================

apply_settings() {
    clear
    echo "===================================="
    echo "     ПРИМЕНЕНИЕ НАСТРОЕК"
    echo "===================================="

    if [ "$DO_HOSTNAME" -eq 1 ]; then
        echo "[HOSTNAME] Установка hostname: $NEW_HOSTNAME"
        sudo hostname "$NEW_HOSTNAME"
    else
        echo "[HOSTNAME] Пропущено"
    fi

    if [ "$DO_USER" -eq 1 ]; then
        echo "[USER] Создание пользователя: $NEW_USER"
        id "$NEW_USER" >/dev/null 2>&1 || sudo useradd -m -u "$NEW_UID" -d "/home/$NEW_USER" -s /bin/bash "$NEW_USER"
    else
        echo "[USER] Пропущено"
    fi

    if [ "$DO_BANNER" -eq 1 ]; then
        echo "[BANNER] Запись /etc/banner"
        echo "$BANNER_TEXT" | sudo tee /etc/banner >/dev/null
    else
        echo "[BANNER] Пропущено"
    fi

    if [ "$DO_DNS" -eq 1 ]; then
        echo "[DNS] Добавление DNS: $DNS_SERVER"
        grep -qxF "nameserver $DNS_SERVER" /etc/resolv.conf || echo "nameserver $DNS_SERVER" | sudo tee -a /etc/resolv.conf >/dev/null
    else
        echo "[DNS] Пропущено"
    fi

    if [ "$DO_IP_FORWARD" -eq 1 ]; then
        echo "[IP FORWARDING] Включение маршрутизации"
        grep -qxF "net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf >/dev/null
        sudo sysctl -p
    else
        echo "[IP FORWARDING] Пропущено"
    fi

    if [ "$DO_NAT" -eq 1 ]; then
        echo "[NAT] Настройка iptables"

        sudo iptables -t nat -C POSTROUTING -o "$WAN_IF" -j MASQUERADE 2>/dev/null || \
        sudo iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE

        sudo iptables -C FORWARD -i "$LAN_IF1" -o "$WAN_IF" -j ACCEPT 2>/dev/null || \
        sudo iptables -A FORWARD -i "$LAN_IF1" -o "$WAN_IF" -j ACCEPT

        sudo iptables -C FORWARD -i "$WAN_IF" -o "$LAN_IF1" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
        sudo iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF1" -m state --state RELATED,ESTABLISHED -j ACCEPT

        sudo iptables -C FORWARD -i "$LAN_IF2" -o "$WAN_IF" -j ACCEPT 2>/dev/null || \
        sudo iptables -A FORWARD -i "$LAN_IF2" -o "$WAN_IF" -j ACCEPT

        sudo iptables -C FORWARD -i "$WAN_IF" -o "$LAN_IF2" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
        sudo iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF2" -m state --state RELATED,ESTABLISHED -j ACCEPT
    else
        echo "[NAT] Пропущено"
    fi

    if [ "$DO_GRE" -eq 1 ]; then
        echo "[GRE] Настройка tunnel: $GRE_NAME"

        ip link show "$GRE_NAME" >/dev/null 2>&1 || \
        sudo ip tunnel add "$GRE_NAME" mode gre local "$GRE_LOCAL_IP" remote "$GRE_REMOTE_IP" ttl 255

        sudo ip link set "$GRE_NAME" mtu 1400

        ip addr show dev "$GRE_NAME" | grep -q "$GRE_TUNNEL_IP" || \
        sudo ip addr add "$GRE_TUNNEL_IP" dev "$GRE_NAME"

        sudo ip link set "$GRE_NAME" up
    else
        echo "[GRE] Пропущено"
    fi

    if [ "$DO_ROUTES" -eq 1 ]; then
        echo "[ROUTES] Добавление маршрутов"

        if [ -n "$ROUTE_NET1" ] && [ -n "$ROUTE_VIA1" ]; then
            sudo ip route replace "$ROUTE_NET1" via "$ROUTE_VIA1"
        fi

        if [ -n "$ROUTE_NET2" ] && [ -n "$ROUTE_VIA2" ]; then
            sudo ip route replace "$ROUTE_NET2" via "$ROUTE_VIA2"
        fi
    else
        echo "[ROUTES] Пропущено"
    fi

    if [ "$DO_SSH" -eq 1 ]; then
        echo "[SSH] Настройка SSH"

        if [ ! -f "$SSH_CONFIG_PATH" ]; then
            echo "Ошибка: файл $SSH_CONFIG_PATH не найден"
            exit 1
        fi

        [ -f /etc/openssh/sshd_config.bak ] || sudo cp /etc/openssh/sshd_config /etc/openssh/sshd_config.bak
        sudo cp "$SSH_CONFIG_PATH" /etc/openssh/sshd_config

        sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null || true
    else
        echo "[SSH] Пропущено"
    fi

    if [ "$DO_OSPF" -eq 1 ]; then
        echo "[OSPF] Установка и настройка FRR"

        if [ ! -f "$FRR_CONFIG_PATH" ]; then
            echo "Ошибка: файл $FRR_CONFIG_PATH не найден"
            exit 1
        fi

        sudo apt-get update
        sudo apt-get install -y frr

        sudo cp "$FRR_CONFIG_PATH" /etc/frr/frr.conf

        sudo systemctl enable frr
        sudo systemctl restart frr
    else
        echo "[OSPF] Пропущено"
    fi

    if [ "$DO_DHCP" -eq 1 ]; then
        echo "[DHCP] Установка и настройка DHCP"

        if [ ! -f "$DHCP_CONFIG_PATH" ]; then
            echo "Ошибка: файл $DHCP_CONFIG_PATH не найден"
            exit 1
        fi

        sudo apt-get update
        sudo apt-get install -y dhcp-server

        sudo mkdir -p /etc/dhcp
        sudo cp "$DHCP_CONFIG_PATH" /etc/dhcp/dhcpd.conf

        sudo systemctl enable dhcpd
        sudo systemctl restart dhcpd
    else
        echo "[DHCP] Пропущено"
    fi

    # =========================
    # RAID5 + NFS APPLY
    # =========================

    if [ "$DO_RAID_NFS" -eq 1 ]; then

        if [ "$RAID_NFS_MODE" = "server" ]; then
            echo "[RAID5 + NFS SERVER] Настройка сервера"

            echo "[RAID5 + NFS SERVER] Установка пакетов"
            sudo apt-get update
            sudo apt-get install -y mdadm
            sudo apt-get install -y nfs-server nfs-utils

            echo "[RAID5 + NFS SERVER] Проверка дисков"

            for disk in "$RAID_DISK1" "$RAID_DISK2" "$RAID_DISK3"; do
                if [ ! -b "$disk" ]; then
                    echo "Ошибка: диск $disk не найден"
                    exit 1
                fi
            done

            echo "[RAID5 + NFS SERVER] Обнуление суперблоков"
            sudo mdadm --zero-superblock --force "$RAID_DISK1" "$RAID_DISK2" "$RAID_DISK3" 2>/dev/null || true

            echo "[RAID5 + NFS SERVER] Удаление старых метаданных и подписей"
            sudo wipefs --all --force "$RAID_DISK1" "$RAID_DISK2" "$RAID_DISK3"

            echo "[RAID5 + NFS SERVER] Создание RAID5"
            yes | sudo mdadm --create "$RAID_DEV" -l 5 -n 3 "$RAID_DISK1" "$RAID_DISK2" "$RAID_DISK3"

            echo "[RAID5 + NFS SERVER] Проверка RAID"
            lsblk

            echo "[RAID5 + NFS SERVER] Создание файловой системы ext4"
            sudo mkfs -t ext4 "$RAID_DEV"

            echo "[RAID5 + NFS SERVER] Создание /etc/mdadm"
            sudo mkdir -p /etc/mdadm

            echo "[RAID5 + NFS SERVER] Заполнение /etc/mdadm/mdadm.conf"
            echo "DEVICE partitions" | sudo tee /etc/mdadm/mdadm.conf >/dev/null
            sudo mdadm --detail --scan | awk '/ARRAY/ {print}' | sudo tee -a /etc/mdadm/mdadm.conf >/dev/null

            echo "[RAID5 + NFS SERVER] Создание директории монтирования"
            sudo mkdir -p "$RAID_MOUNT"

            echo "[RAID5 + NFS SERVER] Добавление RAID в /etc/fstab"
            grep -qE "^[^#]+[[:space:]]+$RAID_MOUNT[[:space:]]+" /etc/fstab || \
            echo "$RAID_DEV  $RAID_MOUNT  ext4  defaults  0  0" | sudo tee -a /etc/fstab >/dev/null

            echo "[RAID5 + NFS SERVER] Монтирование"
            sudo mount -a

            echo "[RAID5 + NFS SERVER] Проверка монтирования"
            df -h

            echo "[RAID5 + NFS SERVER] Создание NFS директории"
            sudo mkdir -p "$RAID_NFS_DIR"

            echo "[RAID5 + NFS SERVER] Выдача прав"
            sudo chmod 766 "$RAID_NFS_DIR"

            echo "[RAID5 + NFS SERVER] Настройка /etc/exports"
            EXPORT_LINE="$RAID_NFS_DIR $RAID_ALLOWED_NET(rw,no_root_squash)"

            grep -qxF "$EXPORT_LINE" /etc/exports || echo "$EXPORT_LINE" | sudo tee -a /etc/exports >/dev/null

            echo "[RAID5 + NFS SERVER] Экспорт файловой системы"
            sudo exportfs -arv

            echo "[RAID5 + NFS SERVER] Запуск NFS-сервера"
            sudo systemctl enable --now nfs-server

            echo "[RAID5 + NFS SERVER] Готово"
        fi

        if [ "$RAID_NFS_MODE" = "client" ]; then
            echo "[NFS CLIENT] Настройка клиента"

            echo "[NFS CLIENT] Установка пакетов"
            sudo apt-get update && sudo apt-get install -y nfs-utils nfs-clients

            echo "[NFS CLIENT] Создание директории"
            sudo mkdir -p "$NFS_CLIENT_MOUNT"

            echo "[NFS CLIENT] Выдача прав"
            sudo chmod 777 "$NFS_CLIENT_MOUNT"

            echo "[NFS CLIENT] Добавление записи в /etc/fstab"
            NFS_FSTAB_LINE="$NFS_SERVER_IP:$NFS_REMOTE_DIR  $NFS_CLIENT_MOUNT  nfs  defaults  0  0"

            grep -qE "^[^#]+[[:space:]]+$NFS_CLIENT_MOUNT[[:space:]]+" /etc/fstab || \
            echo "$NFS_FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null

            echo "[NFS CLIENT] Монтирование"
            sudo mount -a

            echo "[NFS CLIENT] Проверка"
            df -h

            echo "[NFS CLIENT] Готово"
        fi

    else
        echo "[RAID5 + NFS] Пропущено"
    fi

    # =========================
    # CHRONY APPLY
    # =========================

    if [ "$DO_CHRONY" -eq 1 ]; then

        if [ "$CHRONY_MODE" = "server" ]; then
            echo "[CHRONY SERVER] Настройка NTP-сервера"

            echo "[CHRONY SERVER] Установка chrony"
            sudo apt-get update
            sudo apt-get install -y chrony

            echo "[CHRONY SERVER] Резервное копирование /etc/chrony.conf"
            if [ -f /etc/chrony.conf ] && [ ! -f /etc/chrony.conf.bak ]; then
                sudo cp /etc/chrony.conf /etc/chrony.conf.bak
            fi

            echo "[CHRONY SERVER] Запись нового /etc/chrony.conf"
            sudo tee /etc/chrony.conf >/dev/null <<EOF
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0
EOF

            echo "[CHRONY SERVER] Перезапуск chrony"
            sudo systemctl enable --now chronyd 2>/dev/null || sudo systemctl enable --now chrony 2>/dev/null || true
            sudo systemctl restart chronyd 2>/dev/null || sudo systemctl restart chrony 2>/dev/null || true

            echo "[CHRONY SERVER] Готово"
        fi

        if [ "$CHRONY_MODE" = "client" ]; then
            echo "[CHRONY CLIENT] Настройка NTP-клиента"

            echo "[CHRONY CLIENT] Установка chrony"
            sudo apt-get update
            sudo apt-get install -y chrony

            echo "[CHRONY CLIENT] Резервное копирование /etc/chrony.conf"
            if [ -f /etc/chrony.conf ] && [ ! -f /etc/chrony.conf.bak ]; then
                sudo cp /etc/chrony.conf /etc/chrony.conf.bak
            fi

            echo "[CHRONY CLIENT] Запись нового /etc/chrony.conf"
            sudo tee /etc/chrony.conf >/dev/null <<EOF
server $NTP_SERVER_IP iburst prefer
EOF

            echo "[CHRONY CLIENT] Установка NTP-сервера и часового пояса"
            sudo ntp server "$NTP_SERVER_IP" 2>/dev/null || true
            sudo ntp timezone "$NTP_TIMEZONE" 2>/dev/null || true

            echo "[CHRONY CLIENT] Перезапуск chrony"
            sudo systemctl enable --now chronyd 2>/dev/null || sudo systemctl enable --now chrony 2>/dev/null || true
            sudo systemctl restart chronyd 2>/dev/null || sudo systemctl restart chrony 2>/dev/null || true

            echo "[CHRONY CLIENT] Готово"
        fi

    else
        echo "[CHRONY / NTP] Пропущено"
    fi

    # =========================
    # DOCKER + MEDIAWIKI APPLY
    # =========================

    if [ "$DO_DOCKER_WIKI" -eq 1 ]; then
        echo "[DOCKER + MEDIAWIKI] Настройка Docker и MediaWiki"

        echo "[DOCKER + MEDIAWIKI] Остановка и отключение ahttpd"
        sudo systemctl disable --now ahttpd 2>/dev/null || true

        echo "[DOCKER + MEDIAWIKI] Установка Docker и Docker Compose"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-compose

        echo "[DOCKER + MEDIAWIKI] Запуск Docker"
        sudo systemctl enable --now docker

        echo "[DOCKER + MEDIAWIKI] Создание директории: $WIKI_DIR"
        sudo mkdir -p "$WIKI_DIR"

        echo "[DOCKER + MEDIAWIKI] Создание файла: $WIKI_PATH"
        sudo tee "$WIKI_PATH" >/dev/null <<EOF
services:
  mediawiki:
    container_name: wiki
    image: mediawiki
    restart: always
    ports:
      - "8080:80"
    links:
      - db
#    volumes:
#      - ./LocalSettings.php:/var/www/html/LocalSettings.php

  db:
    container_name: mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_DATABASE: mediawiki
      MARIADB_USER: wiki
      MARIADB_PASSWORD: WikiP@ssw0rd
      MARIADB_ROOT_PASSWORD: P@ssw0rd
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

        echo "[DOCKER + MEDIAWIKI] Запуск контейнеров"
        cd "$WIKI_DIR"
        sudo docker compose -f "$WIKI_FILE" up -d

        echo "[DOCKER + MEDIAWIKI] Проверка контейнеров"
        sudo docker ps

        echo "[DOCKER + MEDIAWIKI] Готово"
    else
        echo "[DOCKER + MEDIAWIKI] Пропущено"
    fi

    echo
    echo "===================================="
    echo "Работа готова"
    echo "===================================="
    pause
}

# =========================
# RESET
# =========================

reset_params() {
    DO_HOSTNAME=0
    DO_USER=0
    DO_BANNER=0
    DO_DNS=0
    DO_IP_FORWARD=0
    DO_NAT=0
    DO_GRE=0
    DO_ROUTES=0
    DO_SSH=0
    DO_OSPF=0
    DO_DHCP=0
    DO_RAID_NFS=0
    DO_CHRONY=0
    DO_DOCKER_WIKI=0

    NEW_HOSTNAME=""
    NEW_USER=""
    NEW_UID=""
    BANNER_TEXT=""
    DNS_SERVER=""

    WAN_IF=""
    LAN_IF1=""
    LAN_IF2=""

    GRE_NAME="gre1"
    GRE_LOCAL_IP=""
    GRE_REMOTE_IP=""
    GRE_TUNNEL_IP=""

    ROUTE_NET1=""
    ROUTE_VIA1=""
    ROUTE_NET2=""
    ROUTE_VIA2=""

    SSH_CONFIG_PATH=""
    FRR_CONFIG_PATH=""
    DHCP_CONFIG_PATH=""

    RAID_NFS_MODE=""

    RAID_DEV="/dev/md0"
    RAID_LEVEL="5"
    RAID_DISK1=""
    RAID_DISK2=""
    RAID_DISK3=""
    RAID_MOUNT="/mnt/raid5"
    RAID_NFS_DIR="/mnt/raid5/nfs"
    RAID_ALLOWED_NET=""

    NFS_SERVER_IP=""
    NFS_REMOTE_DIR="/mnt/raid5/nfs"
    NFS_CLIENT_MOUNT="/mnt/nfs"

    CHRONY_MODE=""
    NTP_SERVER_IP=""
    NTP_TIMEZONE=""

    WIKI_DIR="/root"
    WIKI_FILE="wiki.yml"
    WIKI_PATH="/root/wiki.yml"

    echo "Все выбранные параметры сброшены."
}

# =========================
# START
# =========================

main_menu
