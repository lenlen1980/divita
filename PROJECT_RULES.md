# Правила проекта DIVITA - Настройка проксирования
ЗАХОДИМ НА СЕРВЕР, НА СЕРВЕРЕ В РАБОЧУЮ ПАПКУ. ВСЮ РАБОТУ ВЕДЕМ ТАМ

## Описание задачи
Настройка проксирования внешних ресурсов на сервере divita.ae для обхода блокировок в России.
Цель: обеспечить доступ к заблокированным CDN, шрифтам, API и другим критичным для работы веб-приложения ресурсам.

## Серверная информация
- **Хост**: `root@divita.ae`
- **Рабочая директория**: `/var/www/html`
- **Назначение**: Проксирование заблокированных ресурсов
- **ОС**: Ubuntu/Debian (предположительно)
- **Веб-сервер**: Nginx
- **SSL**: Let's Encrypt (рекомендуется)

## Структура проекта на сервере

```
/var/www/html/
├── proxy/                    # Основная директория проксирования
│   ├── config/              # Конфигурационные файлы
│   │   ├── nginx.conf       # Конфигурация Nginx
│   │   ├── blocked-domains.txt # Список заблокированных доменов
│   │   └── allowed-origins.txt # Разрешенные источники
│   ├── logs/                # Логи проксирования
│   │   ├── access.log       # Логи доступа
│   │   ├── error.log        # Логи ошибок
│   │   └── proxy.log        # Специфичные логи прокси
│   ├── cache/               # Кэш ресурсов
│   └── scripts/             # Скрипты управления
│       ├── deploy.sh        # Скрипт деплоя
│       ├── update-config.sh # Обновление конфигурации
│       └── monitor.sh       # Мониторинг работы прокси
├── assets/                  # Статичные ресурсы проекта
│   ├── css/
│   ├── js/
│   └── fonts/
└── index.html              # Главная страница
```

## Технические требования

### 1. Nginx конфигурация
- Настроить reverse proxy для заблокированных доменов
- Использовать upstream блоки для балансировки нагрузки
- Настроить кэширование для оптимизации
- Обеспечить корректную передачу заголовков

### 2. Домены для проксирования
Приоритетные домены для настройки прокси:
- Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`)
- CDN ресурсы (jsDelivr, unpkg, cdnjs)
- Социальные сети API (если необходимо)
- Аналитические сервисы

### 3. Безопасность
- Ограничить доступ только к необходимым ресурсам
- Настроить rate limiting
- Блокировать подозрительные запросы
- Логировать все обращения

### 4. Производительность
- Настроить gzip сжатие
- Использовать браузерное кэширование
- Оптимизировать размер буферов
- Мониторить использование ресурсов

## Правила разработки и деплоя

### 1. Процедура деплоя
```bash
# Подключение к серверу
ssh root@divita.ae

# Переход в рабочую директорию
cd /var/www/html

# Обновление конфигурации
./scripts/update-config.sh

# Перезагрузка Nginx
systemctl reload nginx

# Проверка статуса
systemctl status nginx
```

### 2. Тестирование
- Проверить доступность всех проксируемых ресурсов
- Тестировать производительность загрузки
- Проверить корректность кэширования
- Мониторить логи на предмет ошибок

### 3. Мониторинг
- Регулярно проверять логи ошибок
- Мониторить использование дискового пространства (кэш)
- Отслеживать время отклика прокси
- Проверять актуальность списка заблокированных доменов

## План реализации (поэтапно)

### Этап 1: Анализ и подготовка (День 1)
1. **Подключение к серверу и анализ**
   ```bash
   ssh ssh@divita.ae
   sudo nginx -t  # Проверка текущей конфигурации
   sudo systemctl status nginx
   ls -la /var/www/html/
   ```

2. **Создание структуры директорий**
   ```bash
   cd /var/www/html
   sudo mkdir -p proxy/{config,logs,cache,scripts}
   sudo mkdir -p assets/{css,js,fonts}
   sudo chown -R www-data:www-data .
   ```

3. **Анализ заблокированных ресурсов в текущем проекте**
   - Проверить `index.html` на использование внешних CDN
   - Выявить Google Fonts, JavaScript библиотеки
   - Составить список критичных ресурсов

### Этап 2: Базовая настройка прокси (День 2)
1. **Создание конфигурации Nginx**
2. **Настройка SSL сертификатов**
3. **Тестирование базового проксирования**

### Этап 3: Оптимизация и мониторинг (День 3)
1. **Настройка кэширования**
2. **Создание скриптов мониторинга**
3. **Настройка логирования**

## Конфигурационные файлы

### 1. Полная конфигурация Nginx (`/etc/nginx/sites-available/divita-proxy`)
```nginx
# Кэш для прокси
proxy_cache_path /var/www/html/proxy/cache levels=1:2 keys_zone=proxy_cache:10m max_size=1g inactive=60m use_temp_path=off;

# Upstream блоки для заблокированных сервисов
upstream google_fonts_api {
    server fonts.googleapis.com:443;
    keepalive 32;
}

upstream google_fonts_static {
    server fonts.gstatic.com:443;
    keepalive 32;
}

upstream jsdelivr_cdn {
    server cdn.jsdelivr.net:443;
    keepalive 32;
}

upstream unpkg_cdn {
    server unpkg.com:443;
    keepalive 32;
}

# HTTP сервер (редирект на HTTPS)
server {
    listen 80;
    server_name divita.ae www.divita.ae;
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name divita.ae www.divita.ae;
    
    # SSL конфигурация
    ssl_certificate /etc/letsencrypt/live/divita.ae/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/divita.ae/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Основные настройки
    root /var/www/html;
    index index.html;
    
    # Логирование
    access_log /var/www/html/proxy/logs/access.log;
    error_log /var/www/html/proxy/logs/error.log;
    
    # Основной сайт
    location / {
        try_files $uri $uri/ =404;
        add_header X-Proxy-Cache $upstream_cache_status;
    }
    
    # Проксирование Google Fonts API
    location /proxy/fonts/api/ {
        proxy_pass https://google_fonts_api/;
        proxy_set_header Host fonts.googleapis.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Кэширование
        proxy_cache proxy_cache;
        proxy_cache_valid 200 1d;
        proxy_cache_key $uri;
        add_header X-Proxy-Cache $upstream_cache_status;
        
        # CORS заголовки
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    }
    
    # Проксирование Google Fonts статичных файлов
    location /proxy/fonts/static/ {
        proxy_pass https://google_fonts_static/;
        proxy_set_header Host fonts.gstatic.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Долгое кэширование для шрифтов
        proxy_cache proxy_cache;
        proxy_cache_valid 200 30d;
        proxy_cache_key $uri;
        add_header X-Proxy-Cache $upstream_cache_status;
        
        # CORS заголовки
        add_header Access-Control-Allow-Origin *;
        
        # Кэширование в браузере
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Проксирование jsDelivr CDN
    location /proxy/jsdelivr/ {
        proxy_pass https://jsdelivr_cdn/;
        proxy_set_header Host cdn.jsdelivr.net;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_cache proxy_cache;
        proxy_cache_valid 200 7d;
        proxy_cache_key $uri;
        add_header X-Proxy-Cache $upstream_cache_status;
        
        add_header Access-Control-Allow-Origin *;
        expires 7d;
    }
    
    # Проксирование unpkg CDN
    location /proxy/unpkg/ {
        proxy_pass https://unpkg_cdn/;
        proxy_set_header Host unpkg.com;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_cache proxy_cache;
        proxy_cache_valid 200 7d;
        proxy_cache_key $uri;
        add_header X-Proxy-Cache $upstream_cache_status;
        
        add_header Access-Control-Allow-Origin *;
        expires 7d;
    }
    
    # Статус страница прокси
    location /proxy/status {
        access_log off;
        return 200 "Proxy Status: OK\n";
        add_header Content-Type text/plain;
    }
    
    # Безопасность
    location ~ /\.ht {
        deny all;
    }
    
    location /proxy/logs/ {
        deny all;
    }
    
    location /proxy/config/ {
        deny all;
    }
}
```

### 2. Список заблокированных доменов (`proxy/config/blocked-domains.txt`)
```
fonts.googleapis.com
fonts.gstatic.com
cdn.jsdelivr.net
unpkg.com
cdnjs.cloudflare.com
facebook.com
instagram.com
twitter.com
youtube.com
google-analytics.com
googletagmanager.com
```

### 3. Конфигурация разрешенных источников (`proxy/config/allowed-origins.txt`)
```
https://divita.ae
http://divita.ae
https://www.divita.ae
http://www.divita.ae
localhost
127.0.0.1
```

### Скрипт мониторинга
```bash
#!/bin/bash
# monitor.sh - Проверка работоспособности прокси

PROXY_DOMAINS=(
    "divita.ae/fonts/"
    "divita.ae/api/"
)

for domain in "${PROXY_DOMAINS[@]}"; do
    if curl -s -o /dev/null -w "%{http_code}" "http://$domain" | grep -q "200"; then
        echo "✓ $domain - OK"
    else
        echo "✗ $domain - ERROR"
    fi
done
```

## Соглашения по коду

### 1. Именование файлов
- Конфигурационные файлы: `kebab-case.conf`
- Скрипты: `kebab-case.sh`
- Логи: `service-type.log`

### 2. Комментарии
- Все конфигурационные блоки должны быть прокомментированы
- Скрипты должны содержать описание назначения
- Критичные настройки должны иметь подробные комментарии

### 3. Версионирование
- Все изменения конфигурации версионировать через git
- Создавать бэкапы перед значительными изменениями
- Документировать все изменения в CHANGELOG.md
