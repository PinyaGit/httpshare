#!/bin/bash

# Скрипт для настройки удаленного доступа к серверу
# Запускать с правами sudo

echo "Настройка удаленного доступа к HTTPShare серверу..."

# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "ОШИБКА: Этот скрипт должен быть запущен с правами sudo"
    exit 1
fi

# Получаем IP-адрес машины
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "IP-адрес машины: $IP_ADDRESS"

# Проверяем, установлен ли ufw
if command -v ufw >/dev/null; then
    echo "Настраиваем файрвол (ufw)..."
    
    # Разрешаем порт 8080
    ufw allow 8080/tcp
    echo "✅ Порт 8080 открыт в файрволе"
else
    echo "⚠️  ufw не установлен. Установите его:"
    echo "   sudo apt install ufw"
    echo "   sudo ufw enable"
    echo "   sudo ufw allow 8080/tcp"
fi

# Проверяем, установлен ли iptables
if command -v iptables >/dev/null; then
    echo "Настраиваем iptables..."
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    echo "✅ Правило iptables добавлено"
fi

echo ""
echo "=== Настройка завершена ==="
echo ""
echo "Сервер будет доступен по адресам:"
echo "  Локально:  http://localhost:8080"
echo "  Удаленно:  http://$IP_ADDRESS:8080"
echo ""
echo "Для проверки доступности используйте:"
echo "  curl http://$IP_ADDRESS:8080/api/images"
echo ""
echo "⚠️  ВАЖНО: Убедитесь, что сервер запущен!"
echo "   Для запуска: /home/mon/httpshare/start-server.sh"
echo ""
echo "🔒 Безопасность:"
echo "   - Токен для управления: SECRET123"
echo "   - Рекомендуется настроить дополнительную аутентификацию"
echo "   - Рассмотрите использование HTTPS для продакшена" 