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
        'https://cdnjs.cloudflare.com/': '/proxy/cdnjs/'
    }
    
    # Выполняем замены
    for old_url, new_url in replacements.items():
        content = content.replace(old_url, new_url)
        print(f"Replaced: {old_url} -> {new_url}")
    
    return content

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 replace-urls.py <file>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    # Читаем файл
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Создаем резервную копию
    backup_name = f"{filename}.backup"
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
