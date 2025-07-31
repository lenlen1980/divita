import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import logging
import time
import re

# Настройка логирования
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Настройки для запросов
REQUEST_TIMEOUT = 30
MAX_RETRIES = 3
RETRY_DELAY = 2

from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

# Глобальный список обработанных файлов для избежания зацикливания
processed_files = set()

def download_file(url, download_folder):
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'}
    
    # Skip data URIs, blob URIs, and other non-downloadable URLs
    if url.startswith(('data:', 'blob:', 'javascript:', 'mailto:', '#')):
        logging.info(f"Skipping non-downloadable URL: {url[:50]}...")
        return None
    
    try:
        # Extract filename from URL and clean it
        filename = url.split('/')[-1].split('?')[0]  # Remove parameters
        if not filename or '.' not in filename:
            # If no proper filename, generate one based on URL
            parsed_url = urlparse(url)
            filename = parsed_url.path.replace('/', '_').strip('_')
            if not filename:
                filename = 'resource'
            # Add extension based on content type if possible
            session = requests.Session()
            retries = Retry(total=MAX_RETRIES, backoff_factor=RETRY_DELAY, status_forcelist=[429, 500, 502, 503, 504])
            session.mount('http://', HTTPAdapter(max_retries=retries))
            session.mount('https://', HTTPAdapter(max_retries=retries))
            
            try:
                response = session.head(url, timeout=REQUEST_TIMEOUT, headers=headers)  # Use HEAD to check content type
                content_type = response.headers.get('content-type', '')
                if 'css' in content_type:
                    filename += '.css'
                elif 'javascript' in content_type or 'js' in content_type:
                    filename += '.js'
                elif 'image' in content_type:
                    if 'png' in content_type:
                        filename += '.png'
                    elif 'jpg' in content_type or 'jpeg' in content_type:
                        filename += '.jpg'
                    else:
                        filename += '.img'
            except:
                pass  # If HEAD request fails, continue without extension

        # Clean filename for Windows
        filename = re.sub(r'[<>:"/\\|?*]', '_', filename)

        file_path = os.path.join(download_folder, filename)

        # Check if the file already exists
        if os.path.exists(file_path):
            logging.info(f"File already exists, skipping download: {filename}")
            return file_path

        # Setup session with retries
        session = requests.Session()
        retries = Retry(total=MAX_RETRIES, backoff_factor=RETRY_DELAY, status_forcelist=[429, 500, 502, 503, 504])
        session.mount('http://', HTTPAdapter(max_retries=retries))
        session.mount('https://', HTTPAdapter(max_retries=retries))
        
        response = session.get(url, timeout=REQUEST_TIMEOUT, headers=headers)
        response.raise_for_status()  # Raises HTTPError if the response code was 4xx or 5xx

        if response.status_code == 200:
            with open(file_path, 'wb') as file:
                file.write(response.content)
            logging.info(f"Successfully downloaded: {url} -> {filename}")
            return file_path
        else:
            logging.warning(f"Failed to download {url}: HTTP {response.status_code}")
            
    except Exception as e:
        logging.error(f"Error downloading {url}: {e}")
    return None

def replace_links_in_html(html_content, download_folder):
    soup = BeautifulSoup(html_content, 'html.parser')
    processed_links = 0
    updated_links = 0

    # Process link, img, and script tags
    for tag in soup.find_all(['link', 'img', 'script']):
        url_attr = 'src' if tag.name in ['script', 'img'] else 'href'
        url = tag.get(url_attr)
        if url and (url.startswith('http://') or url.startswith('https://')):
            processed_links += 1
            logging.info(f"Processing {tag.name} tag with URL: {url}")
            local_file_path = download_file(url, download_folder)
            if local_file_path:
                tag[url_attr] = f"{os.path.basename(download_folder)}/{os.path.basename(local_file_path)}"
                updated_links += 1
                logging.info(f"Updated {tag.name} link to local file: {os.path.basename(local_file_path)}")

    # Process CSS inside <style> tags
    import re
    css_urls_processed = 0
    for style_tag in soup.find_all('style'):
        if style_tag.string:
            css_content = style_tag.string
            # Find all URLs in CSS
            url_pattern = r'url\(([^)]*https?://[^)]+)\)'
            urls = re.findall(url_pattern, css_content)
            
            for url in urls:
                # Clean the URL (remove quotes)
                clean_url = url.strip('"\'')
                css_urls_processed += 1
                logging.info(f"Processing CSS URL: {clean_url}")
                local_file_path = download_file(clean_url, download_folder)
                if local_file_path:
                    # Replace the URL in CSS
                    css_content = css_content.replace(url, f"{os.path.basename(download_folder)}/{os.path.basename(local_file_path)}")
                    logging.info(f"Updated CSS URL to local file: {os.path.basename(local_file_path)}")
            
            style_tag.string = css_content

    logging.info(f"Processing complete: {processed_links} external links processed, {updated_links} updated to local files")
    if css_urls_processed > 0:
        logging.info(f"Also processed {css_urls_processed} CSS URLs")
    
    return str(soup)

def process_downloaded_file(file_path, download_folder, force_process=False, depth=0, max_depth=3):
    """Рекурсивно обрабатывает загруженный файл, ища в нем внешние ссылки"""
    if file_path in processed_files or depth > max_depth:
        logging.info(f"File already processed, skipping: {os.path.basename(file_path)}")
        return
    
    processed_files.add(file_path)
    logging.info(f"Processing downloaded file: {os.path.basename(file_path)}")
    
    try:
        # Определяем тип файла по расширению
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext in ['.css', '.js', '.mjs']:
            process_text_file(file_path, download_folder, force_process, depth, max_depth)
        elif file_ext in ['.html', '.htm']:
            process_html_file(file_path, download_folder, force_process)
        else:
            logging.info(f"File type not supported for processing: {file_ext}")
    
    except Exception as e:
        logging.error(f"Error processing file {file_path}: {e}")

def process_text_file(file_path, download_folder, force_process=False, depth=0, max_depth=3):
    """Обрабатывает текстовые файлы (CSS, JS), заменяя внешние ссылки"""
    try:
        # Попробуем разные кодировки
        encodings = ['utf-8', 'utf-8-sig', 'cp1251', 'latin-1']
        content = None
        
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as file:
                    content = file.read()
                    break
            except UnicodeDecodeError:
                continue
        
        if content is None:
            logging.warning(f"Could not read file with any encoding: {file_path}")
            return
        
        original_content = content
        urls_found = 0
        
        # Найти все HTTP/HTTPS ссылки в тексте
        url_patterns = [
            r'url\(["\']?(https?://[^)\s"\'>]+)["\']?\)',  # CSS url()
            r'["\']?(https?://[^"\'>\s]+)["\']?',  # В кавычках
            r'(https?://[^\s"\'>\)\(]+)',  # Обычные URL
        ]
        
        for pattern in url_patterns:
            urls = re.findall(pattern, content)
            for url in urls:
                if url.startswith('http'):
                    urls_found += 1
                    logging.info(f"Found external URL in {os.path.basename(file_path)}: {url}")
                    local_file_path = download_file(url, download_folder)
                    if local_file_path:
                        # Заменяем все вхождения URL на локальный путь
                        relative_path = f"{os.path.basename(download_folder)}/{os.path.basename(local_file_path)}"
                        content = content.replace(url, relative_path)
                        logging.info(f"Replaced URL with local path: {relative_path}")
                        
                        # Рекурсивно обрабатываем новый файл (только если не достигли максимальной глубины)
                        if depth < max_depth:
                            process_downloaded_file(local_file_path, download_folder, False, depth+1, max_depth)
        
        # Сохраняем файл только если были изменения
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(content)
            logging.info(f"Updated file: {os.path.basename(file_path)} ({urls_found} URLs processed)")
        else:
            logging.info(f"No changes needed in file: {os.path.basename(file_path)}")
            
    except Exception as e:
        logging.error(f"Error processing text file {file_path}: {e}")

def process_html_file(file_path, download_folder, force_process=False):
    """Обрабатывает HTML файлы"""
    try:
        # Читаем HTML файл
        encodings = ['utf-8', 'utf-8-sig', 'cp1251', 'latin-1']
        html_content = None
        
        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as file:
                    html_content = file.read()
                    break
            except UnicodeDecodeError:
                continue
        
        if html_content is None:
            logging.warning(f"Could not read HTML file with any encoding: {file_path}")
            return
        
        # Обрабатываем HTML
        updated_html = replace_links_in_html(html_content, download_folder)
        
        # Сохраняем обновленный HTML
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(updated_html)
        
        logging.info(f"Processed HTML file: {os.path.basename(file_path)}")
        
    except Exception as e:
        logging.error(f"Error processing HTML file {file_path}: {e}")

def process_all_downloaded_files(download_folder, force_process=False):
    """Обрабатывает все файлы в папке загрузок, ища в них внешние ссылки"""
    if not os.path.exists(download_folder):
        logging.warning(f"Download folder does not exist: {download_folder}")
        return
    
    logging.info(f"Processing all files in download folder: {download_folder}")
    
    # Получаем список всех файлов в папке
    for root, dirs, files in os.walk(download_folder):
        for file in files:
            file_path = os.path.join(root, file)
            logging.info(f"Found file: {file}")
            process_downloaded_file(file_path, download_folder, force_process)
    
    logging.info("Finished processing all downloaded files")

def main(html_file, download_folder, force_process=False):
    logging.info(f"Starting resource download script for: {html_file}")
    
    if not os.path.exists(download_folder):
        os.makedirs(download_folder)
        logging.info(f"Created download folder: {download_folder}")
    else:
        logging.info(f"Using existing download folder: {download_folder}")

    # Try different encodings
    encodings = ['utf-8', 'cp1251', 'latin-1', 'utf-16']
    html_content = None
    
    for encoding in encodings:
        try:
            with open(html_file, 'r', encoding=encoding) as file:
                html_content = file.read()
                logging.info(f"Successfully read HTML file with encoding: {encoding}")
                break
        except UnicodeDecodeError:
            logging.warning(f"Failed to read file with encoding: {encoding}")
            continue
    
    if html_content is None:
        logging.error("Could not read the HTML file with any of the tried encodings")
        return

    logging.info("Starting HTML link processing...")
    updated_html = replace_links_in_html(html_content, download_folder)

    with open(html_file, 'w', encoding='utf-8') as file:
        file.write(updated_html)
    
    logging.info(f"HTML file updated successfully: {html_file}")
    
    # Дополнительная обработка всех скачанных файлов
    if force_process:
        logging.info("\n=== Starting additional processing of all downloaded files ===")
        process_all_downloaded_files(download_folder, force_process)
    
    logging.info("Script execution completed!")

if __name__ == '__main__':
    html_file = 'index.html'  # Replace with your HTML file name
    download_folder = 'downloaded_resources'
    force_process = True  # Изменить на False, если вы хотите избежать повторной обработки
    main(html_file, download_folder, force_process)
