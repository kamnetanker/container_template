#!/usr/bin/env bash


if [ ! -f "/etc/config-templates/nginx.conf.template" ]; then
  echo "❌ Шаблон nginx.conf.template не найден!"
  exit 1
fi 




if [ "$SSL_MODE" = "self" ]; then
  echo "🔧 Режим SSL: самоподписной сертификат выбран."
  # Конфигурация nginx для работы с самоподписным сертификатом
  export SSL_CONFIG="
    listen ${LISTEN_ADDR}:${HTTPS_PORT} ssl;
    ssl_certificate /etc/nginx/ssl/self-signed.crt;
    ssl_certificate_key /etc/nginx/ssl/self-signed.key;
  " 
  envsubst < "/etc/config-templates/nginx.conf.template" > "/etc/nginx/sites-enabled/default.conf"

  # Создание директории для хранения сертификатов
  echo "📁 Создаём директорию для сертификатов: /etc/nginx/ssl" 
  mkdir -p /etc/nginx/ssl
  # Запуск скрипта выпуска сертификата
  echo "🔐 Запуск генерации самоподписного сертификата для домена: ${DOMAIN}"
  /opt/ssl/self-signed.sh "${DOMAIN}" "/etc/nginx/ssl" "${CERT_DAYS}" 
  # Настраиваем задание cron для автоматического обновления сертификатов ежедневно.
  echo "⏰ Настраиваем cron-задачу для автообновления сертификатов каждые 30 дней"
  echo "0 0 */30 * * /opt/ssl/self-signed.sh \"${DOMAIN}\" \"/etc/nginx/ssl\" \"${CERT_DAYS}\" " > /etc/cron.d/self-renew
  chmod 644 /etc/cron.d/self-renew
  crontab /etc/cron.d/self-renew

elif [ "$SSL_MODE" = "certbot" ]; then
  echo "🔧 Проверяю установку обязательной переменной для certbot"
  if [ -z "$EMAIL" ]; then
      export EMAIL="email@email.com"
      echo "⚠️ Переменная EMAIL не была установлена. Назначено значение по умолчанию: $EMAIL"
  else
      echo "✅ Переменная EMAIL уже установлена: $EMAIL"
  fi 
  echo "🔧 Режим SSL: Certbot выбран."
  # Конфигурация nginx для работы с certbot
  export SSL_CONFIG="
    listen ${LISTEN_ADDR}:${HTTPS_PORT} ssl;
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  "
  envsubst < "/etc/config-templates/nginx.conf.template" > "/etc/nginx/sites-enabled/default.conf"

  # Если сертификаты для домена ещё не получены, запрашиваем их
  if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "⚠️ Сертификат для $DOMAIN не найден. Запускаем получение сертификата..."
    certbot --nginx --non-interactive --agree-tos --email "$EMAIL" -d "$DOMAIN"
  else
    echo "✅ Сертификаты для домена $DOMAIN уже получены."
  fi

  # Настраиваем задание cron для автоматического обновления сертификатов ежедневно.
  echo "⏰ Настраиваем cron-задачу для ежедневного обновления сертификатов"
  echo "0 0 * * * certbot renew --quiet --post-hook \"nginx -s reload\"" > /etc/cron.d/certbot-renew
  chmod 644 /etc/cron.d/certbot-renew
  crontab /etc/cron.d/certbot-renew
else
  echo "ℹ️ SSL_MODE не указан или не поддерживается. Используем конфигурацию без SSL."
  export SSL_CONFIG=""
  envsubst < "/etc/config-templates/nginx.conf.template" > "/etc/nginx/sites-enabled/default.conf"
fi
