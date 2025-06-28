#!/bin/bash

# Полная установка HTTPShare сервера для пользователя mon
# Запускать от имени пользователя mon

echo "=== Полная установка HTTPShare сервера ==="
echo "Пользователь: $USER"
echo ""

# Проверяем, что скрипт запущен от имени пользователя mon
if [ "$USER" != "mon" ]; then
    echo "ОШИБКА: Этот скрипт должен быть запущен от имени пользователя 'mon'"
    echo "Текущий пользователь: $USER"
    echo ""
    echo "Для переключения на пользователя mon выполните:"
    echo "  sudo su - mon"
    echo "  cd /home/mon/httpshare"
    echo "  ./full-install.sh"
    exit 1
fi

# Проверяем, что мы в правильной директории
if [ ! -f "server.js" ]; then
    echo "ОШИБКА: Файл server.js не найден"
    echo "Убедитесь, что вы находитесь в директории /home/mon/httpshare"
    exit 1
fi

echo "1. Устанавливаем Node.js и зависимости..."

# Проверяем, что Node.js установлен
if ! command -v node &> /dev/null; then
    echo "Node.js не найден. Устанавливаем..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "✅ Node.js уже установлен: $(node --version)"
fi

# Устанавливаем зависимости
echo "Устанавливаем npm зависимости..."
npm install

echo ""
echo "2. Настраиваем автозапуск..."

# Делаем скрипты исполняемыми
chmod +x start-server.sh
chmod +x stop-server.sh
chmod +x check-status.sh
chmod +x install-autostart.sh

# Устанавливаем автозапуск
./install-autostart.sh

echo ""
echo "3. Создаем необходимые директории..."

# Создаем папку для изображений, если её нет
mkdir -p public/images

echo ""
echo "4. Запускаем сервер для тестирования..."

# Останавливаем старый сервер, если запущен
./stop-server.sh

# Запускаем новый сервер
./start-server.sh

echo ""
echo "5. Проверяем работу сервера..."

# Ждем немного, чтобы сервер запустился
sleep 3

# Проверяем статус
./check-status.sh

echo ""
echo "=== Установка завершена! ==="
echo ""
echo "🌐 Сервер доступен по адресам:"
echo "   Локально:  http://localhost:8080"
echo "   Удаленно:  http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "🔧 Управление:"
echo "   Статус:    ./check-status.sh"
echo "   Остановка: ./stop-server.sh"
echo "   Запуск:    ./start-server.sh"
echo ""
echo "📋 Логи: /home/mon/httpshare/server.log"
echo ""
echo "🔒 Токен для управления: SECRET123"
echo ""
echo "✅ Сервер будет автоматически запускаться при входе пользователя mon"
echo ""
echo "Для настройки удаленного доступа выполните:"
echo "  sudo ./setup-remote-access.sh" 