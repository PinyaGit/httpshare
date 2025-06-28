#!/bin/bash

# Скрипт для запуска сервера изображений
# Автор: mon
# Дата: $(date)

# Переходим в директорию проекта
cd /home/mon/httpshare

# Проверяем, что Node.js установлен
if ! command -v node &> /dev/null; then
    echo "Node.js не найден. Устанавливаем..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Устанавливаем зависимости, если нужно
if [ ! -d "node_modules" ]; then
    echo "Устанавливаем зависимости..."
    npm install
fi

# Проверяем, что порт 8080 свободен
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null ; then
    echo "Порт 8080 уже занят. Останавливаем существующий процесс..."
    pkill -f "node server.js"
    sleep 2
fi

# Запускаем сервер
echo "Запускаем сервер изображений..."
export DISPLAY=:0
export XAUTHORITY=/home/mon/.Xauthority

# Запускаем сервер в фоновом режиме
nohup node server.js > /home/mon/httpshare/server.log 2>&1 &

# Сохраняем PID процесса
echo $! > /home/mon/httpshare/server.pid

echo "Сервер запущен с PID $(cat /home/mon/httpshare/server.pid)"
echo "Логи доступны в /home/mon/httpshare/server.log"
echo "Сервер доступен по адресу: http://localhost:8080" 