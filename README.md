# Hysteria 2 - Скрипт автоматической установки и управления﻿

Простой bash-скрипт для установки и управления Hysteria 2 VPN сервером на Linux с поддержкой нескольких пользователей.

## Возможности﻿

✅ Автоматическая установка Hysteria 2 последней версии

✅ Управление несколькими пользователями

✅ Генерация QR-кодов для подключения

✅ Самоподписанные SSL сертификаты

✅ Обфускация трафика (Salamander)

✅ Поддержка Debian, Ubuntu, CentOS, Fedora, Alpine

✅ Интерактивное меню управления

## Требования﻿

VPS на Linux (Debian/Ubuntu/CentOS/Fedora/Alpine)

Root доступ

Открытый порт 443 (или другой на ваш выбор)

## Быстрая установка﻿

bash
wget -N --no-check-certificate https://raw.githubusercontent.com/stixmill/hysteria2-pro-max-tuz/main/hysteria2-install.sh
chmod +x hysteria2-install.sh
./hysteria2-install.sh
Или одной командой:

bash
bash <(curl -fsSL https://raw.githubusercontent.com/stixmill/hysteria2-pro-max-tuz/main/hysteria2-install.sh)
## Использование﻿

### Интерактивное меню﻿

Запустите скрипт без параметров для входа в меню:

bash
./hysteria2-install.sh
Доступные опции:

Установить Hysteria2 - первичная установка сервера

Добавить пользователя - создание нового пользователя

Список пользователей - просмотр всех пользователей

Удалить пользователя - удаление пользователя

Показать статус сервиса - проверка работы службы

Перезапустить сервис - перезапуск Hysteria2

Удалить Hysteria2 - полное удаление

### Управление пользователями﻿

#### Добавление пользователя﻿
После установки выберите пункт 2 в меню:

Введите имя пользователя

Скрипт автоматически сгенерирует пароль

Создаст файл конфигурации и QR-код

#### Просмотр пользователей﻿
Пункт 3 покажет список всех паролей пользователей.

#### Удаление пользователя﻿
Пункт 4 позволит удалить пользователя по его паролю.

## Структура файлов﻿

После установки будут созданы:

/etc/hysteria/

├── config.yaml          # Основной конфиг сервера

├── cert.crt             # SSL сертификат

├── private.key          # Приватный ключ

├── users.txt            # Список паролей пользователей

├── obfs_password.txt    # Пароль обфускации

└── server_info.txt      # Информация о сервере

/root/

├── hysteria2_user1.txt  # Конфиг первого пользователя

├── hysteria2_username.txt # Конфиги других пользователей

└── ...

## Настройка клиентов﻿

### Android﻿

Установите Exclave(https://github.com/ExclaveNetwork/Exclave/releases), Hiddify или v2rayNG

Отсканируйте QR-код или вставьте строку подключения из файла /root/hysteria2_username.txt

### iOS﻿

Установите V2BOX(предпочтительно), Shadowrocket или Stash

Отсканируйте QR-код или вставьте строку подключения

### Windows/Linux/macOS﻿

Скачайте клиент: https://v2.hysteria.network/docs/getting-started/Installation/

Используйте строку подключения из файла конфигурации

## Управление через командную строку﻿

bash
# Запуск сервиса
systemctl start hysteria-server

# Остановка сервиса
systemctl stop hysteria-server

# Перезапуск сервиса
systemctl restart hysteria-server

# Статус сервиса
systemctl status hysteria-server

# Логи
journalctl -u hysteria-server -f
## Настройка﻿

По умолчанию используются:

Порт: 443

SNI: web.max.ru

Маскировка: https://web.max.ru

Для изменения отредактируйте функцию configure_hysteria() в скрипте.

## Устранение неполадок﻿

### Сервис не запускается﻿
Проверьте логи:

bash
journalctl -u hysteria-server -n 50
Проверьте конфиг:

bash
/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml --check
### Порт занят﻿
Проверьте какой процесс использует порт 443:

bash
lsof -i :443
Или

bash
netstat -tulpn | grep 443
### Не подключается клиент﻿

Проверьте открыт ли порт на файрволе

Проверьте правильность строки подключения

Убедитесь что сервис запущен: systemctl status hysteria-server

## Обновление﻿

Удалите старую версию (сохранив пользователей):

bash
cp /etc/hysteria/users.txt ~/users_backup.txt
Запустите скрипт заново:

bash
./hysteria2-install.sh
Восстановите пользователей:

bash
cp ~/users_backup.txt /etc/hysteria/users.txt
systemctl restart hysteria-server

## Безопасность﻿

⚠️ Скрипт генерирует самоподписанные сертификаты (allowInsecure=true)

⚠️ Для продакшена рекомендуется использовать настоящие SSL сертификаты

⚠️ Храните файлы /etc/hysteria/users.txt и конфиги в безопасности

✅ Используйте сильные пароли для SSH доступа к серверу

✅ Настройте файрвол (UFW/iptables)

## Лицензия﻿

MIT License - свободно используйте и модифицируйте.

## Поддержка﻿

📖 Документация Hysteria 2: https://v2.hysteria.network/

🐛 Issues: https://github.com/stixmill/hysteria2-install/issues

💬 Telegram: [ваш канал]

## Благодарности﻿

Hysteria Project - за отличный VPN протокол

Сообщество за тестирование и обратную связь

⭐ Если скрипт помог - поставьте звезду на GitHub!

Инструкция по публикации на GitHub﻿
Создайте новый репозиторий:
Перейдите на https://github.com/new
Название: hysteria2-install
Описание: Автоматическая установка и управление Hysteria 2 VPN сервером с поддержкой нескольких пользователей
Выберите Public
Добавьте .gitignore (шаблон: None)
Выберите лицензию: MIT License
Загрузите файлы:

bash
git clone https://github.com/MeccCZ/hysteria2-install.git
cd hysteria2-install

# Создайте файлы
nano hysteria2-install.sh  # вставьте скрипт выше
nano README.md             # вставьте README выше

chmod +x hysteria2-install.sh

# Закоммитьте
git add .
git commit -m "Initial release: Hysteria2 installer with multi-user support"
git push origin main
Создайте релиз:
Перейдите в Releases → Create a new release
Tag: v1.0.0
Title: v1.0.0 - Initial Release
Описание: добавьте changelog
Прикрепите файл hysteria2-install.sh

Теперь ваш скрипт готов к использованию! Пользователи смогут устанавливать его одной командой через curl или wget. 🚀
