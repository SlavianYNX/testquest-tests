#!/bin/bash
# Скрипт запуска автотестов TestQuest — Калькулятор смет для Linux/macOS
# Использование: BASE_URL=https://testquest.pryaniky.com ./run-tests.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Базовый URL по умолчанию
BASE_URL="${BASE_URL:-https://testquest.pryaniky.com}"

echo "=============================================="
echo "TestQuest — Калькулятор смет: Запуск тестов"
echo "=============================================="
echo ""
echo "BASE_URL: ${BASE_URL}"
echo ""

# Переход в директорию скрипта
cd "$(dirname "$0")"

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Ошибка: Python 3 не найден${NC}"
    echo "Установите Python 3.8 или выше"
    exit 1
fi

PYTHON_CMD="python3"

# Проверка версии Python
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Версия Python: ${PYTHON_VERSION}"

# Создание виртуального окружения если нет
if [ ! -d "venv" ]; then
    echo ""
    echo -e "${YELLOW}Создание виртуального окружения...${NC}"
    $PYTHON_CMD -m venv venv
fi

# Активация виртуального окружения
echo -e "${YELLOW}Активация виртуального окружения...${NC}"
source venv/bin/activate

# Установка зависимостей
echo ""
echo -e "${YELLOW}Установка зависимостей...${NC}"
pip install --quiet --upgrade pip
pip install --quiet -r tests/requirements.txt

# Установка браузеров Playwright
echo ""
echo -e "${YELLOW}Проверка браузеров Playwright...${NC}"
playwright install chromium 2>/dev/null || true

# Запуск тестов
echo ""
echo "=============================================="
echo "Запуск тестов pytest..."
echo "=============================================="
echo ""

export BASE_URL="${BASE_URL}"

# Запуск с подробным выводом
pytest tests/test_calculator.py \
    -v \
    --tb=short \
    --browser=chromium || TEST_EXIT_CODE=$?

# Сохранение кода выхода
TEST_EXIT_CODE=${TEST_EXIT_CODE:-$?}

echo ""
echo "=============================================="
echo "РЕЗУЛЬТАТ"
echo "=============================================="

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}RESULT: PASSED${NC}"
    echo "Все тесты пройдены успешно!"
else
    echo -e "${RED}RESULT: FAILED${NC}"
    echo "Некоторые тесты не прошли. Проверьте вывод выше."
fi

echo ""
echo "Код выхода: ${TEST_EXIT_CODE}"
echo "Отчёт: test-report.html"
echo ""

# Деактивация виртуального окружения
deactivate

exit $TEST_EXIT_CODE
