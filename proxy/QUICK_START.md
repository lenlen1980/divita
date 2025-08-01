# DIVITA Proxy - Быстрый старт

## 🚀 Для новых членов команды

### Первые шаги:

1. **Подключение к серверу:**
   ```bash
   ssh root@divita.ae
   cd /var/www/html/proxy
   ```

2. **Проверка текущего состояния:**
   ```bash
   ./scripts/monitor.sh
   ./scripts/test-proxy.sh
   ```

3. **Просмотр логов:**
   ```bash
   # Последние ошибки
   tail -20 logs/error.log
   
   # Последние запросы
   tail -20 logs/access.log
   ```

### Основные директории:
- `/var/www/html/` - корневая директория проекта
- `/var/www/html/proxy/` - конфигурация и скрипты прокси
- `/var/www/html/assets/` - локальные копии ресурсов
- `/etc/nginx/sites-available/` - конфигурация Nginx

### Ключевые команды:
- `nginx -t` - проверка конфигурации Nginx
- `systemctl reload nginx` - перезагрузка Nginx
- `systemctl status nginx` - статус Nginx

### В случае проблем:
1. Проверьте README.md для детальной информации
2. Используйте скрипты из директории scripts/
3. Проверьте логи в logs/

