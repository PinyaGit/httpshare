#!/bin/bash

# Скрипт для установки systemd сервиса
# Запускать с правами sudo

echo "Устанавливаем systemd сервис для HTTPShare..."

# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "ОШИБКА: Этот скрипт должен быть запущен с правами sudo"
    exit 1
fi

# Проверяем, что пользователь mon существует
if ! id "mon" &>/dev/null; then
    echo "ОШИБКА: Пользователь 'mon' не найден"
    exit 1
fi

# Копируем сервис файл
cp systemd-service/httpshare.service /etc/systemd/system/

# Перезагружаем systemd
systemctl daemon-reload

# Включаем автозапуск сервиса
systemctl enable httpshare.service

echo "Systemd сервис установлен!"
echo ""
echo "Команды для управления сервисом:"
echo "  sudo systemctl start httpshare    # Запустить сервер"
echo "  sudo systemctl stop httpshare     # Остановить сервер"
echo "  sudo systemctl restart httpshare  # Перезапустить сервер"
echo "  sudo systemctl status httpshare   # Проверить статус"
echo "  sudo journalctl -u httpshare -f   # Просмотр логов"
echo ""
echo "Сервер будет автоматически запускаться при загрузке системы" 