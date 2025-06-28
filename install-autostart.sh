#!/bin/bash

# Скрипт для установки автозапуска сервера
# Запускать от имени пользователя mon

echo "Устанавливаем автозапуск сервера HTTPShare..."

# Проверяем, что скрипт запущен от имени пользователя mon
if [ "$USER" != "mon" ]; then
    echo "ОШИБКА: Этот скрипт должен быть запущен от имени пользователя 'mon'"
    echo "Текущий пользователь: $USER"
    exit 1
fi

# Создаем директорию автозапуска, если её нет
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Делаем скрипты исполняемыми
chmod +x /home/mon/httpshare/start-server.sh
chmod +x /home/mon/httpshare/stop-server.sh

# Копируем desktop файл в директорию автозапуска
cp /home/mon/httpshare/httpshare.desktop "$AUTOSTART_DIR/"

echo "Автозапуск установлен!"
echo "Сервер будет автоматически запускаться при входе пользователя mon в систему"
echo ""
echo "Для проверки статуса сервера используйте:"
echo "  curl http://localhost:8080/api/images"
echo ""
echo "Для остановки сервера используйте:"
echo "  /home/mon/httpshare/stop-server.sh"
echo ""
echo "Логи сервера доступны в:"
echo "  /home/mon/httpshare/server.log" 