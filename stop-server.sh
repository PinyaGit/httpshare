#!/bin/bash

# Скрипт для остановки сервера изображений
# Автор: mon

echo "Останавливаем сервер изображений..."

# Останавливаем процесс по PID, если файл существует
if [ -f "/home/mon/httpshare/server.pid" ]; then
    PID=$(cat /home/mon/httpshare/server.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "Останавливаем процесс с PID $PID"
        kill $PID
        sleep 2
        
        # Проверяем, что процесс остановлен
        if kill -0 $PID 2>/dev/null; then
            echo "Принудительно завершаем процесс"
            kill -9 $PID
        fi
    else
        echo "Процесс с PID $PID не найден"
    fi
    rm -f /home/mon/httpshare/server.pid
else
    echo "Файл PID не найден"
fi

# Дополнительно убиваем все процессы node server.js
pkill -f "node server.js" 2>/dev/null

# Останавливаем слайдшоу, если запущено
pkill -f "feh" 2>/dev/null
pkill -f "eog" 2>/dev/null

echo "Сервер остановлен" 