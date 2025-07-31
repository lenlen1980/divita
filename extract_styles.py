#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import os

def extract_styles_from_html(html_file_path, css_file_path, js_file_path):
    """
    Извлекает CSS стили из HTML файла и сохраняет их в отдельный CSS файл.
    Удаляет блок <style> из HTML и добавляет ссылку на внешний CSS файл.
    """
    
    # Проверяем существование HTML файла
    if not os.path.exists(html_file_path):
        print(f"Ошибка: Файл {html_file_path} не найден!")
        return False
    
    try:
        # Читаем HTML файл
        with open(html_file_path, 'r', encoding='utf-8') as file:
            html_content = file.read()
        
        # Ищем ВСЕ блоки стилей с помощью регулярного выражения (учитываем многострочность)
        style_pattern = r'\u003cstyle[^\u003e]*\u003e(.*?)\u003c/style\u003e'
        style_matches = re.findall(style_pattern, html_content, re.DOTALL)
        
        css_extracted = False
        if not style_matches:
            print("Блоки \u003cstyle\u003e не найдены в HTML файле.")
        else:
            css_extracted = True
        
        if css_extracted:
            print(f"Найдено {len(style_matches)} блоков стилей")
            
            # Объединяем содержимое всех блоков стилей
            css_content = '\n\n'.join([style.strip() for style in style_matches])

            print(f"Всего извлечено строк CSS: {css_content.count('\\n') + 1}")
            
            # Сохраняем CSS в отдельный файл
            with open(css_file_path, 'w', encoding='utf-8') as css_file:
                css_file.write(css_content)
            
            print(f"CSS стили успешно извлечены в файл: {css_file_path}")
        
        # Извлекаем все скрипты
        script_pattern = r'\u003cscript[^\u003e]*\u003e(.*?)\u003c/script\u003e'
        script_matches = re.findall(script_pattern, html_content, re.DOTALL)

        if script_matches:
            print(f"Найдено {len(script_matches)} скриптов")
            js_content = '\n\n'.join([script.strip() for script in script_matches])
            with open(js_file_path, 'w', encoding='utf-8') as js_file:
                js_file.write(js_content)
            print(f"JavaScript скрипты успешно извлечены в файл: {js_file_path}")
            print(f"Всего извлечено строк JS: {js_content.count('\\n') + 1}")
        else:
            print("Блоки \u003cscript\u003e не найдены в HTML файле.")

        # Удаляем блок \u003cscript\u003e из HTML
        html_content = re.sub(script_pattern, '', html_content, flags=re.DOTALL)
        
        # Удаляем блок <style> из HTML
        html_content_without_styles = re.sub(style_pattern, '', html_content, flags=re.DOTALL)
        
        # Проверяем, есть ли уже ссылка на CSS файл
        link_pattern = r'<link[^>]*rel=["\']stylesheet["\'][^>]*href=["\']styles\.css["\'][^>]*>'
        if not re.search(link_pattern, html_content_without_styles):
            # Добавляем ссылку на CSS файл в секцию <head>
            css_link = '<link rel="stylesheet" href="styles.css">'
            html_content_without_styles = re.sub(r'</head>', f'{css_link}\n</head>', html_content_without_styles)
            print("Добавлена ссылка на внешний CSS файл")
        else:
            print("Ссылка на CSS файл уже присутствует")
        
        # Сохраняем обновленный HTML файл
        with open(html_file_path, 'w', encoding='utf-8') as file:
            file.write(html_content_without_styles)
        
        print(f"HTML файл успешно обновлен: {html_file_path}")
        
        return True
        
    except Exception as e:
        print(f"Ошибка при обработке файлов: {str(e)}")
        return False

def main():
    # Пути к файлам
    html_file = "index.html"
    css_file = "styles.css"
    js_file = "scripts.js"
    
    print("Начинаем извлечение CSS стилей и JS скриптов...")
    print(f"HTML файл: {html_file}")
    print(f"CSS файл: {css_file}")
    print(f"JS файл: {js_file}")
    print("-" * 50)
    
    success = extract_styles_from_html(html_file, css_file, js_file)
    
    if success:
        print("-" * 50)
        print("✅ Операция завершена успешно!")
        print(f"• CSS стили извлечены в файл: {css_file}")
        print(f"• JavaScript скрипты извлечены в файл: {js_file}")
        print(f"• HTML файл обновлен: {html_file}")
    else:
        print("-" * 50)
        print("❌ Операция завершена с ошибками!")

if __name__ == "__main__":
    main()
