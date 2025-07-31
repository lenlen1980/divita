#!/usr/bin/env python3
"""
CSS Rewriter для замены внешних ссылок на локальные прокси
"""
import re

def rewrite_google_fonts_css(css_content):
    """Заменяет ссылки fonts.gstatic.com на локальный прокси"""
    modified_css = re.sub(
        r'https://fonts\.gstatic\.com/', 
        'https://divita.ae/proxy/fonts/static/', 
        css_content
    )
    return modified_css

def rewrite_cdn_links(css_content):
    """Заменяет другие CDN ссылки на локальные прокси"""
    # JSDelivr
    modified_css = re.sub(
        r'https://cdn\.jsdelivr\.net/', 
        'https://divita.ae/proxy/jsdelivr/', 
        css_content
    )
    
    # Unpkg
    modified_css = re.sub(
        r'https://unpkg\.com/', 
        'https://divita.ae/proxy/unpkg/', 
        modified_css
    )
    
    return modified_css

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python3 css-rewriter.py <css_content>")
        sys.exit(1)
    
    css_content = sys.argv[1]
    rewritten_css = rewrite_google_fonts_css(css_content)
    rewritten_css = rewrite_cdn_links(rewritten_css)
    
    print(rewritten_css)
