#!/usr/bin/env bash

set -e

# Проверка, что все необходимые параметры заданы
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "❌ Использование: $0 DOMAIN OUTPUT_DIR DAYS"
  exit 1
fi

DOMAIN="$1"
OUTPUT_DIR="$2"
DAYS="$3"

# Файлы ключа и сертификата
KEY_FILE="$OUTPUT_DIR/self-signed.key"
CRT_FILE="$OUTPUT_DIR/self-signed.crt"

echo "🔍 Проверка наличия сертификата для домена $DOMAIN ..."
if [ -f "$CRT_FILE" ]; then
  notAfter=$(openssl x509 -in "$CRT_FILE" -enddate -noout | cut -d= -f2-)
  expires=$(date -d "$notAfter" +%s)
  now=$(date +%s)

  if [ "$now" -lt "$expires" ]; then
    echo "✔️ Найден действующий сертификат, истекает: $notAfter."
    echo "⏳ Перевыпуск не требуется."
    exit 0
  else
    echo "⚠️ Сертификат просрочен (истёк: $notAfter), требуется перевыпуск."
  fi
else 
  echo "ℹ️ Сертификат не найден. Приступаем к генерации нового сертификата."
fi

echo "🔐 Генерация нового самоподписанного сертификата для $DOMAIN на $DAYS дней..."

openssl req -x509 -nodes -days "$DAYS" \
  -newkey rsa:2048 \
  -keyout "$KEY_FILE" \
  -out "$CRT_FILE" \
  -subj "/CN=${DOMAIN}/O=SelfSigned/C=US"

chmod 600 "$KEY_FILE"
chmod 600 "$CRT_FILE"

echo "✅ Сертификат успешно сгенерирован!"
echo "   🔑 Ключ сохранён в: $KEY_FILE"
echo "   📄 Сертификат сохранён в: $CRT_FILE"