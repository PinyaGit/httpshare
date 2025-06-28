#!/bin/bash

# Скрипт для проверки статуса сервера HTTPShare

echo "=== Проверка статуса HTTPShare сервера ==="
echo ""

# Проверяем, запущен ли процесс
if pgrep -f "node server.js" > /dev/null; then
    echo "✅ Сервер запущен"
    PID=$(pgrep -f "node server.js")
    echo "   PID: $PID"
else
    echo "❌ Сервер не запущен"
fi

echo ""

# Проверяем, слушает ли порт 8080
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null; then
    echo "✅ Порт 8080 активен"
else
    echo "❌ Порт 8080 не слушается"
fi

echo ""

# Проверяем доступность API
if command -v curl >/dev/null; then
    if curl -s http://localhost:8080/api/images >/dev/null; then
        echo "✅ API доступен"
        echo "   Количество изображений: $(curl -s http://localhost:8080/api/images | jq length 2>/dev/null || echo 'неизвестно')"
    else
        echo "❌ API недоступен"
    fi
else
    echo "⚠️  curl не установлен, не могу проверить API"
fi

echo ""

# Показываем логи, если есть
if [ -f "/home/mon/httpshare/server.log" ]; then
    echo "📋 Последние логи сервера:"
    tail -5 /home/mon/httpshare/server.log
else
    echo "📋 Логи сервера не найдены"
fi

echo ""
echo "=== Полезные команды ==="
echo "Запуск:    /home/mon/httpshare/start-server.sh"
echo "Остановка: /home/mon/httpshare/stop-server.sh"
echo "Веб-интерфейс: http://localhost:8080" 