#!/usr/bin/env bash

set -e

CONFIG_DIR="/etc/nginx/sites-enabled"
MODULE_DIR="/opt/modules"

echo "🔧 Проверяю установку переменных"
# Проверка обязательных переменных
if [ -z "$LISTEN_ADDR" ]; then
    export LISTEN_ADDR="0.0.0.0"
    echo "⚠️ Переменная LISTEN_ADDR не была установлена. Назначено значение по умолчанию: $LISTEN_ADDR"
else
    echo "✅ Переменная LISTEN_ADDR уже установлена: $LISTEN_ADDR"
fi 

if [ -z "$HTTP_PORT" ]; then
    export HTTP_PORT=80
    echo "⚠️ Переменная HTTP_PORT не была установлена. Назначено значение по умолчанию: $HTTP_PORT"
else
    echo "✅ Переменная HTTP_PORT уже установлена: $HTTP_PORT"
fi 

if [ -z "$HTTPS_PORT" ]; then
    export HTTPS_PORT=443
    echo "⚠️ Переменная HTTPS_PORT не была установлена. Назначено значение по умолчанию: $HTTPS_PORT"
else
    echo "✅ Переменная HTTPS_PORT уже установлена: $HTTPS_PORT"
fi 
if [ -z "$CERT_DAYS" ]; then
    export CERT_DAYS=365
    echo "⚠️ Переменная CERT_DAYS не была установлена. Назначено значение по умолчанию: $CERT_DAYS"
else
    echo "✅ Переменная CERT_DAYS уже установлена: $CERT_DAYS"
fi 
if [ -z "$SSL_MODE" ]; then
    export SSL_MODE="no"
    echo "⚠️ Переменная SSL_MODE не была установлена. Назначено значение по умолчанию: $SSL_MODE"
else
    echo "✅ Переменная SSL_MODE уже установлена: $SSL_MODE"
fi 



echo "🔧 Запуск модулей генерации конфигурации..." 
for module in "$MODULE_DIR"/*.sh; do
  echo "📦 Запускаю модуль: $module"
  . "$module"
done

echo "✅ Конфигурация готова."

echo "✅ Запускаем демон cron в фоне"
service cron start

echo "📦 Запуск Nginx"
nginx -t && nginx -g 'daemon off;'