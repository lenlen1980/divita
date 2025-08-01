// Тест влияния отсутствующих source maps на отладку
console.log("=== Тест Source Maps ===");

// Проверим, что происходит в DevTools без .map файлов
const testFunction = () => {
    console.log("Эта функция будет видна в DevTools");
    debugger; // Точка останова для тестирования
    return "test";
};

// Вызовем функцию
testFunction();

console.log("Если вы видите номера строк в DevTools - отладка работает");
console.log("Если видите минифицированный код - source maps не работают");
