FROM debian:bookworm-slim

# Установка зависимостей
RUN apt update && \
    apt install -y nginx-light bash gettext openssl \
    cron curl python3-certbot-nginx certbot && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/nginx/sites-enabled /etc/nginx/conf.d

# Убираем дефолтный конфиг сайта nginx
RUN rm /etc/nginx/sites-enabled/default

RUN mkdir -p /etc/config-templates
COPY config-templates/nginx.conf.template /etc/config-templates
COPY modules/ /opt/modules/
RUN chmod +x -R /opt/modules
COPY ssl/ /opt/ssl/
RUN chmod +x -R /opt/ssl

COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80 443

CMD ["/init.sh"]