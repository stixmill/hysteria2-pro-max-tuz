#!/bin/bash

export LANG=ru_RU.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

if [[ $EUID -ne 0 ]]; then
    red "Внимание: Запустите скрипт от имени root пользователя"
    exit 1
fi

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Alpine")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install" "apk add -f")

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "Текущая система VPS не поддерживается, используйте основную операционную систему" && exit 1

if [[ -z $(type -P curl) ]]; then
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl
fi

get_ip() {
    local ip=$(curl -s4m8 ip.sb -k) || ip=$(curl -s6m8 ip.sb -k)
    echo "$ip"
}

install_server_core() {
    yellow "Установка Hysteria2..."

    set -e

    SCRIPT_ARGS=("$@")

    EXECUTABLE_INSTALL_PATH="/usr/local/bin/hysteria"

    SYSTEMD_SERVICES_DIR="/etc/systemd/system"

    CONFIG_DIR="/etc/hysteria"

    REPO_URL="https://github.com/apernet/hysteria"

    HY2_API_BASE_URL="https://api.hy2.io/v1"

    CURL_FLAGS=(-L -f -q --retry 5 --retry-delay 10 --retry-max-time 60)

    PACKAGE_MANAGEMENT_INSTALL="${PACKAGE_MANAGEMENT_INSTALL:-}"

    OPERATING_SYSTEM="${OPERATING_SYSTEM:-}"

    ARCHITECTURE="${ARCHITECTURE:-}"

    HYSTERIA_USER="${HYSTERIA_USER:-}"

    HYSTERIA_HOME_DIR="${HYSTERIA_HOME_DIR:-}"

    OPERATION=

    VERSION=

    FORCE=

    LOCAL_FILE=

    has_command() {
      local _command=$1
      type -P "$_command" > /dev/null 2>&1
    }

    curl() {
      command curl "${CURL_FLAGS[@]}" "$@"
    }

    mktemp() {
      command mktemp "$@" "/tmp/hyservinst.XXXXXXXXXX"
    }

    note() {
      local _msg="$1"
      echo -e "$SCRIPT_NAME: $(tput bold)note: $_msg$(tput sgr0)"
    }

    warning() {
      local _msg="$1"
      echo -e "$SCRIPT_NAME: $(tput setaf 3)warning: $_msg$(tput sgr0)"
    }

    error() {
      local _msg="$1"
      echo -e "$SCRIPT_NAME: $(tput setaf 1)error: $_msg$(tput sgr0)"
    }

    check_environment_operating_system() {
      if [[ -n "$OPERATING_SYSTEM" ]]; then
        warning "OPERATING_SYSTEM=$OPERATING_SYSTEM обнаружено, определение ОС выполняться не будет."
        return
      fi

      if [[ "x$(uname)" == "xLinux" ]]; then
        OPERATING_SYSTEM=linux
        return
      fi

      error "Этот скрипт поддерживает только Linux."
      exit 95
    }

    check_environment_architecture() {
      if [[ -n "$ARCHITECTURE" ]]; then
        warning "ARCHITECTURE=$ARCHITECTURE обнаружено, определение архитектуры выполняться не будет."
        return
      fi

      case "$(uname -m)" in
        'i386' | 'i686')
          ARCHITECTURE='386'
          ;;
        'amd64' | 'x86_64')
          ARCHITECTURE='amd64'
          ;;
        'armv5tel' | 'armv6l' | 'armv7' | 'armv7l')
          ARCHITECTURE='arm'
          ;;
        'armv8' | 'aarch64')
          ARCHITECTURE='arm64'
          ;;
        'mips' | 'mipsle' | 'mips64' | 'mips64le')
          ARCHITECTURE='mipsle'
          ;;
        's390x')
          ARCHITECTURE='s390x'
          ;;
        *)
          error "Архитектура '$(uname -a)' не поддерживается."
          exit 8
          ;;
      esac
    }

    check_environment_systemd() {
      if [[ -d "/run/systemd/system" ]] || grep -q systemd <(ls -l /sbin/init); then
        return
      fi

      case "$FORCE_NO_SYSTEMD" in
        '1')
          warning "FORCE_NO_SYSTEMD=1, продолжим даже если systemd не обнаружен."
          ;;
        '2')
          warning "FORCE_NO_SYSTEMD=2, продолжим но пропустим все команды связанные с systemd."
          ;;
        *)
          error "Этот скрипт поддерживает только дистрибутивы Linux с systemd."
          exit 1
          ;;
      esac
    }

    update_packages() {
      ${PACKAGE_UPDATE[int]}
    }

    check_environment_curl() {
      if has_command curl; then
        return
      fi
      ${PACKAGE_INSTALL[int]} curl
    }

    check_environment_grep() {
      if has_command grep; then
        return
      fi
      ${PACKAGE_INSTALL[int]} grep
    }

    check_environment_qrencode() {
      if has_command qrencode; then
        return
      fi
      ${PACKAGE_INSTALL[int]} qrencode
    }

    check_environment() {
      update_packages
      check_environment_operating_system
      check_environment_architecture
      check_environment_systemd
      check_environment_curl
      check_environment_grep
      check_environment_qrencode
    }

    install_content() {
      local _install_flags="$1"
      local _content="$2"
      local _destination="$3"
      local _overwrite="$4"

      local _tmpfile="$(mktemp)"

      echo -ne "Установка $_destination ... "
      echo "$_content" > "$_tmpfile"
      if [[ -z "$_overwrite" && -e "$_destination" ]]; then
        echo -e "существует"
      elif install "$_install_flags" "$_tmpfile" "$_destination"; then
        echo -e "ок"
      fi

      rm -f "$_tmpfile"
    }

    get_latest_version() {
      if [[ -n "$VERSION" ]]; then
        echo "$VERSION"
        return
      fi

      local _tmpfile=$(mktemp)
      if ! curl -sS "$HY2_API_BASE_URL/update?cver=installscript&plat=${OPERATING_SYSTEM}&arch=${ARCHITECTURE}&chan=release&side=server" -o "$_tmpfile"; then
        error "Ошибка получения последней версии от Hysteria 2 API"
        exit 11
      fi

      local _latest_version=$(grep -oP '"lver":\s*\K"v.*?"' "$_tmpfile" | head -1)
      _latest_version=${_latest_version#'"'}
      _latest_version=${_latest_version%'"'}

      if [[ -n "$_latest_version" ]]; then
        echo "$_latest_version"
      fi

      rm -f "$_tmpfile"
    }

    download_hysteria() {
      local _version="$1"
      local _destination="$2"

      local _download_url="$REPO_URL/releases/download/app/$_version/hysteria-$OPERATING_SYSTEM-$ARCHITECTURE"
      echo "Загрузка бинарного файла hysteria: $_download_url ..."
      if ! curl -R -H 'Cache-Control: no-cache' "$_download_url" -o "$_destination"; then
        error "Ошибка загрузки, проверьте ваше соединение и попробуйте снова."
        return 11
      fi
      return 0
    }

    perform_install_hysteria_binary() {
      local _tmpfile=$(mktemp)
      local _version=$(get_latest_version)

      if ! download_hysteria "$_version" "$_tmpfile"; then
        rm -f "$_tmpfile"
        exit 11
      fi

      echo -ne "Установка исполняемого файла hysteria ... "
      if install -Dm755 "$_tmpfile" "$EXECUTABLE_INSTALL_PATH"; then
        echo "ок"
      else
        exit 13
      fi

      rm -f "$_tmpfile"

      mkdir -p /etc/hysteria
    }

    perform_install_hysteria_systemd() {
      if [[ "x$FORCE_NO_SYSTEMD" == "x2" ]]; then
        return
      fi

      local _service_content=$(cat << 'EOF'
[Unit]
Description=Hysteria Server Service (config.yaml)
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
WorkingDirectory=~
User=root
Group=root
Environment=HYSTERIA_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
)
      install_content -Dm644 "$_service_content" "$SYSTEMD_SERVICES_DIR/hysteria-server.service" "1"

      systemctl daemon-reload
    }

    check_environment
    HYSTERIA_USER="root"
    HYSTERIA_HOME_DIR="/root"

    perform_install_hysteria_binary
    perform_install_hysteria_systemd

    green "Hysteria2 core успешно установлен!"
}

configure_hysteria() {
    yellow "Настройка сервера Hysteria2..."

    mkdir -p /etc/hysteria

    local sni_host="web.max.ru"
    local masquerade_url="web.max.ru"
    local port="443"

    local obfs_pwd=$(date +%s%N | md5sum | cut -c 1-16)

    echo "$obfs_pwd" > /etc/hysteria/obfs_password.txt

    openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key
    openssl req -new -x509 -days 36500 -key /etc/hysteria/private.key -out /etc/hysteria/cert.crt -subj "/CN=$sni_host"
    chmod 600 /etc/hysteria/cert.crt
    chmod 600 /etc/hysteria/private.key
    local sha256hash="$(openssl x509 -in /etc/hysteria/cert.crt -outform DER 2>/dev/null | sha256sum 2>/dev/null | awk '{print $1}')"

    # Запрашиваем имя первого пользователя
    read -p "Введите имя первого пользователя (латиница/цифры): " first_username
    if [[ -z "$first_username" ]]; then
        red "Имя пользователя не может быть пустым!"
        exit 1
    fi

    local first_pwd=$(date +%s%N | md5sum | cut -c 1-16)
    echo "$first_username:$first_pwd" > /etc/hysteria/users.txt

    cat > /etc/hysteria/config.yaml << EOF
listen: :$port

tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/private.key
  sniGuard: disable

resolver:
  tcp:
    addr: 8.8.8.8:53
    timeout: 4s
  udp:
    addr: 8.8.4.4:53
    timeout: 4s
  tls:
    addr: 1.1.1.1:853
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false

obfs:
  type: salamander
  salamander:
    password: $obfs_pwd

auth:
  type: userpass
  userpass:
    $first_username: $first_pwd

masquerade:
  type: proxy
  listenHTTP: :80
  listenHTTPS: :443
  forceHTTPS: true
  proxy:
    url: https://$masquerade_url
    rewriteHost: true

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false
EOF

    local server_ip=$(get_ip)

    cat > /etc/hysteria/server_info.txt << EOF
SERVER_IP=$server_ip
PORT=$port
SNI=$sni_host
OBFS_PWD=$obfs_pwd
MASQUERADE=$masquerade_url
SHA256HASH=$sha256hash
EOF

    cat > /root/hysteria2_${first_username}.txt << EOF
hy2://$first_username:$first_pwd@$server_ip:$port?mport&security=tls&sni=$sni_host&allowInsecure=true&pinSHA256=$sha256hash&alpn&obfs=salamander&obfs-password=$obfs_pwd#$first_username
EOF

    green "Настройка завершена!"
    echo
    yellow "IP сервера: $server_ip"
    yellow "Порт: $port"
    yellow "SNI: $sni_host"
    yellow "Имя пользователя 1: $first_username"
    yellow "Пароль пользователя 1: $first_pwd"
    yellow "Пароль обфускации: $obfs_pwd"
    yellow "Маскировка: https://$masquerade_url"
    yellow "Хэш ssl сертификата : $sha256hash"
    echo
}

update_config_from_users() {
    local obfs_pwd=$(cat /etc/hysteria/obfs_password.txt)
    local port=$(grep PORT /etc/hysteria/server_info.txt | cut -d'=' -f2)
    local sni=$(grep SNI /etc/hysteria/server_info.txt | cut -d'=' -f2)
    local masquerade=$(grep MASQUERADE /etc/hysteria/server_info.txt | cut -d'=' -f2)
    local sha256hash=$(grep SHA256HASH /etc/hysteria/server_info.txt | cut -d'=' -f2)

    cat > /etc/hysteria/config.yaml << EOF
listen: :$port

tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/private.key
  sniGuard: disable

resolver:
  tcp:
    addr: 8.8.8.8:53
    timeout: 4s
  udp:
    addr: 8.8.4.4:53
    timeout: 4s
  tls:
    addr: 1.1.1.1:853
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
    
obfs:
  type: salamander
  salamander:
    password: $obfs_pwd

auth:
  type: userpass
  userpass:
EOF
    while IFS=: read -r user pass; do
    echo "    $user: $pass" >> /etc/hysteria/config.yaml
    done < /etc/hysteria/users.txt

    cat >> /etc/hysteria/config.yaml << EOF

masquerade:
  type: proxy
  proxy:
    url: https://$masquerade
    rewriteHost: true
  listenHTTP: :80
  listenHTTPS: :443
  forceHTTPS: true

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false
EOF
}

add_user() {
    if [[ ! -f /etc/hysteria/users.txt ]]; then
        red "Hysteria2 не установлен! Сначала установите сервер."
        return 1
    fi

    green "=== Добавление нового пользователя ==="
    echo

    local username new_pwd config_file

    read -p "Введите имя пользователя (латиница/цифры): " username

    username="${username// /}"

    if [[ -z "$username" ]]; then
        red "Имя пользователя не может быть пустым!"
        return 1
    fi

    if grep -q "^$username:" /etc/hysteria/users.txt; then
        red "Пользователь с таким именем уже существует!"
        return 1
    fi

    new_pwd=$(date +%s%N | md5sum | cut -c 1-16)

    echo "$username:$new_pwd" >> /etc/hysteria/users.txt

    update_config_from_users

    systemctl restart hysteria-server

    source /etc/hysteria/server_info.txt 2>/dev/null || true

    config_file="/root/hysteria2_${username}.txt"

    cat > "$config_file" << EOF
hy2://$username:$new_pwd@$SERVER_IP:$PORT?mport&security=tls&sni=$SNI&allowInsecure=true&pinSHA256=$SHA256HASH&alpn&obfs=salamander&obfs-password=$OBFS_PWD#$username
EOF

    green "Пользователь '$username' успешно добавлен!"
    echo
    yellow "Имя: $username"
    yellow "Пароль: $new_pwd"
    yellow "Конфигурация сохранена: $config_file"
    echo
    yellow "Строка подключения:"
    cat "$config_file"
    echo

    if command -v qrencode &> /dev/null; then
        green "=== QR Code для $username ==="
        qrencode -t ANSIUTF8 "$(cat $config_file)"
        echo
    fi
}

: '
add_user() {
    green "=== Тест добавления ==="
    echo
    local username new_pwd
    read -p "Имя: " username
    username="${username// /}"
    new_pwd="TEST1234567890"
    echo "Введено имя  : '$username'"
    echo "Длина имени   : ${#username}"
    echo "Полная строка : hy2://$username:$new_pwd@..."
    echo "Файл был бы   : /root/hysteria2_${username}.txt"
}
'
list_users() {
    if [[ ! -f /etc/hysteria/users.txt ]]; then
        red "Hysteria2 не установлен!"
        return 1
    fi

    green "=== Список пользователей ==="
    echo
    local count=1
    while IFS=: read -r username password; do
        yellow "Пользователь $count: $username"
        yellow "Пароль: $password"

        local config_file="/root/hysteria2_${username}.txt"
        if [[ -f "$config_file" ]]; then
            echo "   Конфиг: $config_file"
        fi

        ((count++))
    done < /etc/hysteria/users.txt
    echo
    yellow "Всего пользователей: $((count-1))"
}

delete_user() {
    if [[ ! -f /etc/hysteria/users.txt ]]; then
        red "Hysteria2 не установлен!"
        return 1
    fi

    local user_count=$(wc -l < /etc/hysteria/users.txt)
    if [ "$user_count" -eq 1 ]; then
        red "Нельзя удалить последнего пользователя!"
        return 1
    fi

    list_users
    echo
    read -p "Введите имя пользователя для удаления: " del_username

    if ! grep -q "^$del_username:" /etc/hysteria/users.txt; then
        red "Пользователь с таким именем не найден!"
        return 1
    fi

    sed -i "/^$del_username:/d" /etc/hysteria/users.txt

    update_config_from_users

    systemctl restart hysteria-server

    rm -f "/root/hysteria2_${del_username}.txt"

    green "Пользователь успешно удалён!"
}

start_service() {
    yellow "Запуск службы Hysteria2..."

    systemctl daemon-reload
    systemctl enable hysteria-server
    systemctl start hysteria-server

    sleep 2
    if systemctl is-active --quiet hysteria-server; then
        green "Служба Hysteria2 успешно запущена"
    else
        red "Ошибка запуска службы Hysteria2"
        systemctl status hysteria-server
        exit 1
    fi
}

show_config() {
    # Показываем конфиг первого пользователя (теперь с username)
    local first_line=$(head -n 1 /etc/hysteria/users.txt)
    local first_username=${first_line%%:*}

    echo
    green "=== Конфигурация первого пользователя ($first_username) ==="
    cat /root/hysteria2_${first_username}.txt
    echo

    if command -v qrencode &> /dev/null; then
        green "=== QR Code ==="
        qrencode -t ANSIUTF8 "$(cat /root/hysteria2_${first_username}.txt)"
    fi
}

show_all_configs() {
    if [[ ! -f /etc/hysteria/users.txt ]]; then
        red "Hysteria2 не установлен!"
        return 1
    fi

    source /etc/hysteria/server_info.txt

    green "=== Все конфигурации пользователей ==="
    echo
    local count=1
    while IFS=: read -r username password; do
        yellow "Пользователь $count ($username):"
        echo "hy2://$username:$password@$SERVER_IP:$PORT?mport&security=tls&sni=$SNI&allowInsecure=true&alpn&obfs=salamander&obfs-password=$OBFS_PWD#$username"
        echo
        ((count++))
    done < /etc/hysteria/users.txt
}

uninstall_hysteria() {
    red "Удаление Hysteria2..."

    systemctl stop hysteria-server 2>/dev/null || true
    systemctl disable hysteria-server 2>/dev/null || true
    rm -f /etc/systemd/system/hysteria-server.service
    rm -f /usr/local/bin/hysteria
    rm -rf /etc/hysteria
    rm -f /root/hysteria2*.txt
    systemctl daemon-reload

    green "Hysteria2 полностью удален!"
}

check_hysteria_installed() {
    [[ -f "/usr/local/bin/hysteria" ]]
}

show_menu() {
    clear
    echo "=================================="
    green "  Hysteria2 Установка и Управление"
    echo "=================================="
    echo
    echo "1. Установить Hysteria2"
    echo "2. Добавить пользователя"
    echo "3. Список пользователей"
    echo "4. Показать все конфиги"
    echo "5. Удалить пользователя"
    echo "6. Показать статус сервиса"
    echo "7. Перезапустить сервис"
    echo "8. Удалить Hysteria2"
    echo "0. Выход"
    echo
}

main() {
    if [[ $# -eq 0 ]]; then
        while true; do
            show_menu
            read -p "Выберите действие: " choice
            case $choice in
                1)
                    if check_hysteria_installed; then
                        red "Hysteria2 уже установлен!"
                        read -p "Переустановить? [y/N]: " reinstall
                        if [[ "$reinstall" =~ ^[yY]$ ]]; then
                            uninstall_hysteria
                            install_server_core
                            configure_hysteria
                            start_service
                            show_config
                        fi
                    else
                        install_server_core
                        configure_hysteria
                        start_service
                        show_config
                        green "Установка завершена!"
                        echo
                        yellow "Конфиг: /root/hysteria2_*.txt"
                    fi
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                2)
                    add_user
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                3)
                    list_users
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                4)
                    show_all_configs
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                5)
                    delete_user
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                6)
                    systemctl status hysteria-server
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                7)
                    systemctl restart hysteria-server
                    green "Сервис перезапущен"
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                8)
                    read -p "Удалить Hysteria2? [y/N]: " confirm
                    if [[ "$confirm" =~ ^[yY]$ ]]; then
                        uninstall_hysteria
                    fi
                    read -p "Нажмите Enter для продолжения..."
                    ;;
                0)
                    exit 0
                    ;;
                *)
                    red "Неверный выбор!"
                    sleep 2
                    ;;
            esac
        done
    else
        install_server_core
        configure_hysteria
        start_service
        show_config
    fi
}

main "$@"
