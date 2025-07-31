#!/usr/bin/env python3
import re
import sys
import os

def replace_external_urls(content):
    """Заменяет внешние URL на проксированные"""
    
    # Словарь замен
    replacements = {
        'https://framerusercontent.com/': '/proxy/framer/',
        'https://fonts.googleapis.com/': '/proxy/fonts/api/',
        'https://fonts.gstatic.com/': '/proxy/fonts/static/',
        'https://cdn.jsdelivr.net/': '/proxy/jsdelivr/',
        'https://unpkg.com/': '/proxy/unpkg/',
        'https://cdnjs.cloudflare.com/': '/proxy/cdnjs/',
        'https://my.atlist.com/': '/proxy/atlist/'
    }
    
    # Выполняем замены
    for old_url, new_url in replacements.items():
        count = content.count(old_url)
        if count > 0:
            content = content.replace(old_url, new_url)
            print(f"Replaced {count} occurrences: {old_url} -> {new_url}")
    
    # Специальная обработка для iframe allow атрибута
    content = re.sub(
        r'allow="geolocation \'self\' https://my\.atlist\.com"',
        'allow="geolocation \'self\' /proxy/atlist"',
        content
    )
    
    return content

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 replace-urls-v2.py <file>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    # Читаем файл
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Создаем резервную копию
    backup_name = f"{filename}.backup.v2"
    with open(backup_name, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created backup: {backup_name}")
    
    # Заменяем URL
    new_content = replace_external_urls(content)
    
    # Сохраняем результат
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Updated: {filename}")

if __name__ == "__main__":
    main()
