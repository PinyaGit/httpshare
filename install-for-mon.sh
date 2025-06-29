#!/bin/bash

# Универсальный скрипт установки HTTPShare для пользователя mon
# Запускать от любого пользователя с правами sudo

echo "=== Универсальная установка HTTPShare для пользователя mon ==="
echo "Текущий пользователь: $USER"
echo ""

# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "ОШИБКА: Этот скрипт должен быть запущен с правами sudo"
    echo "Выполните: sudo ./install-for-mon.sh"
    exit 1
fi

# Проверяем, что пользователь mon существует
if ! id "mon" &>/dev/null; then
    echo "ОШИБКА: Пользователь 'mon' не найден"
    echo "Создайте пользователя mon:"
    echo "  sudo adduser mon"
    exit 1
fi

# Определяем текущую директорию проекта
CURRENT_DIR=$(pwd)
echo "Текущая директория проекта: $CURRENT_DIR"

# Проверяем, что мы в правильной директории
if [ ! -f "server.js" ]; then
    echo "ОШИБКА: Файл server.js не найден"
    echo "Убедитесь, что вы находитесь в директории проекта"
    exit 1
fi

echo ""
echo "1. Копируем проект к пользователю mon..."

# Создаем директорию, если её нет
sudo -u mon mkdir -p /home/mon

# Копируем проект
cp -r "$CURRENT_DIR" /home/mon/
echo "✅ Проект скопирован в /home/mon/httpshare"

# Устанавливаем правильные права
chown -R mon:mon /home/mon/httpshare
echo "✅ Права установлены для пользователя mon"

echo ""
echo "2. Проверяем и устанавливаем зависимости..."

# Проверяем, что Node.js установлен
if ! command -v node &> /dev/null; then
    echo "Node.js не найден. Устанавливаем..."
    apt-get update
    apt-get install -y nodejs
else
    echo "✅ Node.js уже установлен: $(node --version)"
fi

# Проверяем, что feh установлен
if ! command -v feh &> /dev/null; then
    echo "feh не найден. Устанавливаем..."
    apt-get update
    apt-get install -y feh
else
    echo "✅ feh уже установлен: $(feh --version | head -1)"
fi

echo ""
echo "3. Выполняем установку от имени пользователя mon..."

# Выполняем установку от имени mon
sudo -u mon bash -c "
cd /home/mon/httpshare

echo 'Настраиваем автозапуск...'
chmod +x start-server.sh
chmod +x stop-server.sh
chmod +x check-status.sh

# Создаем desktop файл для автозапуска
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/httpshare.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=HTTPShare Server
Comment=Сервер для удаленного управления изображениями
Exec=/home/mon/httpshare/start-server.sh
Terminal=false
X-GNOME-Autostart-enabled=true
Categories=Network;
Icon=applications-graphics
EOF

echo 'Создаем необходимые директории...'
mkdir -p public/images

echo 'Останавливаем старый сервер, если запущен...'
./stop-server.sh

echo 'Запускаем сервер для тестирования...'
./start-server.sh

echo 'Ждем запуска сервера...'
sleep 3

echo 'Проверяем работу сервера...'
./check-status.sh
"

echo ""
echo "4. Настраиваем удаленный доступ..."

# Получаем IP-адрес машины
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "IP-адрес машины: $IP_ADDRESS"

# Настраиваем файрвол
if command -v ufw >/dev/null; then
    echo "Настраиваем файрвол (ufw)..."
    ufw allow 8080/tcp
    echo "✅ Порт 8080 открыт в файрволе"
else
    echo "⚠️  ufw не установлен. Установите его:"
    echo "   sudo apt install ufw"
    echo "   sudo ufw enable"
    echo "   sudo ufw allow 8080/tcp"
fi

# Настраиваем iptables
if command -v iptables >/dev/null; then
    echo "Настраиваем iptables..."
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    echo "✅ Правило iptables добавлено"
fi

echo ""
echo "=== Установка завершена! ==="
echo ""
echo "✅ Проект скопирован в: /home/mon/httpshare"
echo "✅ Права установлены для пользователя mon"
echo "✅ Node.js и feh установлены"
echo "✅ Автозапуск настроен"
echo "✅ Сервер запущен и протестирован"
echo ""
echo "🌐 Сервер доступен по адресам:"
echo "   Локально:  http://localhost:8080"
echo "   Удаленно:  http://$IP_ADDRESS:8080"
echo ""
echo "🔧 Управление сервером:"
echo "   Статус:    sudo -u mon /home/mon/httpshare/check-status.sh"
echo "   Остановка: sudo -u mon /home/mon/httpshare/stop-server.sh"
echo "   Запуск:    sudo -u mon /home/mon/httpshare/start-server.sh"
echo ""
echo "📋 Логи: /home/mon/httpshare/server.log"
echo ""
echo "🔒 Токен для управления: SECRET123"
echo ""
echo "✅ Сервер будет автоматически запускаться при входе пользователя mon"
echo ""
echo "Для проверки работы выполните:"
echo "  curl http://localhost:8080/api/images" 
