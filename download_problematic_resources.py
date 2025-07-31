#!/usr/bin/env python3
import os
import re
import requests
from bs4 import BeautifulSoup
import logging
from urllib.parse import urljoin, urlparse
import time

# Настройка логирования
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Настройки
DOWNLOAD_FOLDER = 'assets/external'
REQUEST_TIMEOUT = 30
MAX_RETRIES = 3
RETRY_DELAY = 2

# Домены, которые не удалось проксировать
PROBLEMATIC_DOMAINS = [
    'framerusercontent.com',
    'my.atlist.com'
]

def ensure_directory(path):
    """Создает директорию если она не существует"""
    if not os.path.exists(path):
        os.makedirs(path)
        logging.info(f"Created directory: {path}")

def get_domain_folder(url):
    """Возвращает папку для домена"""
    parsed = urlparse(url)
    domain = parsed.netloc.replace('www.', '')
    return os.path.join(DOWNLOAD_FOLDER, domain.replace('.', '_'))

def download_file(url, base_folder):
    """Загружает файл и сохраняет с сохранением структуры URL"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        
        response = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        response.raise_for_status()
        
        # Парсим URL для создания структуры папок
        parsed = urlparse(url)
        path_parts = parsed.path.strip('/').split('/')
        
        # Создаем структуру папок
        folder_path = base_folder
        for part in path_parts[:-1]:
            folder_path = os.path.join(folder_path, part)
        ensure_directory(folder_path)
        
        # Определяем имя файла
        filename = path_parts[-1] if path_parts[-1] else 'index.html'
        if '.' not in filename:
            # Добавляем расширение на основе content-type
            content_type = response.headers.get('content-type', '')
            if 'css' in content_type:
                filename += '.css'
            elif 'javascript' in content_type:
                filename += '.js'
            elif 'json' in content_type:
                filename += '.json'
            elif 'image' in content_type:
                if 'png' in content_type:
                    filename += '.png'
                elif 'jpeg' in content_type or 'jpg' in content_type:
                    filename += '.jpg'
                elif 'svg' in content_type:
                    filename += '.svg'
                elif 'webp' in content_type:
                    filename += '.webp'
        
        file_path = os.path.join(folder_path, filename)
        
        # Сохраняем файл
        with open(file_path, 'wb') as f:
            f.write(response.content)
        
        logging.info(f"Downloaded: {url} -> {file_path}")
        return file_path
        
    except Exception as e:
        logging.error(f"Failed to download {url}: {e}")
        return None

def find_problematic_urls(html_file):
    """Находит все URL с проблемных доменов в HTML файле"""
    with open(html_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    urls = set()
    
    # Ищем прокси URL которые указывают на проблемные домены
    proxy_patterns = [
        r'/proxy/framer/([^"\'>\s]+)',
        r'/proxy/atlist/([^"\'>\s]+)'
    ]
    
    for pattern in proxy_patterns:
        matches = re.findall(pattern, content)
        for match in matches:
            if pattern.startswith('/proxy/framer/'):
                urls.add(f'https://framerusercontent.com/{match}')
            elif pattern.startswith('/proxy/atlist/'):
                urls.add(f'https://my.atlist.com/{match}')
    
    # Также ищем прямые ссылки если остались
    for domain in PROBLEMATIC_DOMAINS:
        pattern = rf'https?://{re.escape(domain)}/[^"\'>\s]+'
        matches = re.findall(pattern, content)
        urls.update(matches)
    
    return list(urls)

def update_html_with_local_paths(html_file, downloaded_files):
    """Обновляет HTML файл, заменяя URL на локальные пути"""
    with open(html_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Создаем бэкап
    backup_file = f"{html_file}.backup.local"
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    logging.info(f"Created backup: {backup_file}")
    
    # Заменяем URL
    for original_url, local_path in downloaded_files.items():
        # Преобразуем локальный путь в относительный URL
        relative_path = '/' + local_path.replace('\\', '/')
        
        # Заменяем прокси URL
        if 'framerusercontent.com' in original_url:
            proxy_url = original_url.replace('https://framerusercontent.com/', '/proxy/framer/')
            content = content.replace(proxy_url, relative_path)
        elif 'my.atlist.com' in original_url:
            proxy_url = original_url.replace('https://my.atlist.com/', '/proxy/atlist/')
            content = content.replace(proxy_url, relative_path)
        
        # Также заменяем прямые URL если есть
        content = content.replace(original_url, relative_path)
    
    # Сохраняем обновленный файл
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    logging.info(f"Updated {html_file} with local paths")

def main():
    logging.info("Starting download of problematic resources...")
    
    # Создаем основную папку
    ensure_directory(DOWNLOAD_FOLDER)
    
    # Находим все проблемные URL
    urls = find_problematic_urls('index.html')
    logging.info(f"Found {len(urls)} problematic URLs")
    
    # Загружаем файлы
    downloaded_files = {}
    for url in urls:
        domain_folder = get_domain_folder(url)
        ensure_directory(domain_folder)
        
        local_path = download_file(url, domain_folder)
        if local_path:
            downloaded_files[url] = local_path
            time.sleep(0.5)  # Небольшая задержка между запросами
    
    logging.info(f"Successfully downloaded {len(downloaded_files)} files")
    
    # Обновляем HTML
    if downloaded_files:
        update_html_with_local_paths('index.html', downloaded_files)
    
    logging.info("Download complete!")
    
    # Выводим статистику
    print("\n=== Download Statistics ===")
    print(f"Total URLs found: {len(urls)}")
    print(f"Successfully downloaded: {len(downloaded_files)}")
    print(f"Failed: {len(urls) - len(downloaded_files)}")
    
    if len(downloaded_files) < len(urls):
        print("\nFailed URLs:")
        for url in urls:
            if url not in downloaded_files:
                print(f"  - {url}")

if __name__ == '__main__':
    main()
