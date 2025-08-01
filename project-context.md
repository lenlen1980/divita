# Контекст проекта DIVITA

## Описание проекта
Веб-проект DIVITA, использующий Framer для создания интерактивного интерфейса. В настоящее время весь код находится в едином файле `index.html`.

## Текущее состояние

### Структура файлов
```
divita/
└── index.html (основной и единственный файл)
```

### Анализ index.html
Файл содержит:
- HTML-разметку с метатегами и структурой страницы
- Встроенный JavaScript скрипт для обработки локализации (строки 24-80)
- Встроенные CSS стили:
  - Breakpoint CSS (строки 81-107) 
  - Основные стили Framer компонентов (строки 108-1509+)
  - Стили шрифтов Inter с различными весами
  - Стили для текстовых компонентов
  - Стили для интерактивных элементов
- Inline стили и компоненты Framer

## Задача рефакторинга

### Цель
Переразбить монолитный `index.html` файл на отдельные модули для улучшения структуры проекта, maintainability и организации кода.

### Планируемая структура
```
divita/
├── index.html (очищенный основной файл)
├── assets/
│   ├── css/
│   │   ├── main.css (основные стили)
│   │   ├── breakpoints.css (медиа-запросы)
│   │   ├── fonts.css (стили шрифтов)
│   │   ├── components.css (стили компонентов)
│   │   └── framer.css (специфичные стили Framer)
│   └── js/
│       ├── main.js (основная логика)
│       ├── localization.js (скрипт локализации)
│       └── utils.js (вспомогательные функции)
└── project-context.md (этот файл)
```

### Задачи для выполнения

#### 1. Создание структуры папок
- [x] `assets/css/` - для CSS файлов
- [x] `assets/js/` - для JavaScript файлов

#### 2. Извлечение и организация CSS
- [ ] **breakpoints.css** - медиа-запросы для адаптивности (строки 81-107)
- [ ] **fonts.css** - все @font-face декларации для шрифта Inter (строки 148-435)
- [ ] **main.css** - базовые стили (html, body, reset стили, строки 112-147, 436-443)
- [ ] **components.css** - стили для Framer компонентов (строки 444-1509+)
- [ ] **framer.css** - специфичные стили фреймворка

#### 3. Извлечение и организация JavaScript
- [ ] **localization.js** - скрипт обработки локализации (строки 24-80)
- [ ] **main.js** - основная логика приложения
- [ ] **utils.js** - вспомогательные функции при необходимости

#### 4. Обновление index.html
- [ ] Удаление встроенных стилей и скриптов
- [ ] Добавление ссылок на внешние CSS файлы
- [ ] Добавление ссылок на внешние JS файлы
- [ ] Сохранение всех метатегов и структуры
- [ ] Проверка корректности путей

### Требования к рефакторингу

#### Приоритеты
1. **Сохранение функциональности** - все должно работать как раньше
2. **Читаемость кода** - разделение ответственности между файлами
3. **Поддерживаемость** - упрощение дальнейшей разработки
4. **Производительность** - оптимизация загрузки ресурсов

#### Технические требования
- Сохранить все существующие стили без изменений
- Поддержать все медиа-запросы и адаптивность
- Сохранить функциональность локализации
- Обеспечить корректную загрузку шрифтов
- Валидный HTML5 код

#### Соглашения по именованию
- CSS файлы: kebab-case (main.css, breakpoints.css)
- JS файлы: camelCase или kebab-case (main.js, localization.js)
- Папки: lowercase (css, js, assets)

### Примечания
- Проект использует Framer фреймворк
- Шрифт Inter загружается с внешних CDN
- Есть система локализации на JavaScript
- Используются CSS custom properties (CSS переменные)
- Адаптивный дизайн с breakpoints

### Ожидаемый результат
После рефакторинга получим:
- Чистый и читаемый index.html
- Организованную структуру CSS стилей по модулям
- Выделенную JavaScript логику
- Улучшенную поддерживаемость кода
- Возможность для дальнейшего расширения проекта
