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

# Проверка наличия Python (несколько способов для разных сред)
PYTHON_CMD=""

# Способ 1: command -v
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
# Способ 2: which
elif which python3 &> /dev/null; then
    PYTHON_CMD="$(which python3)"
# Способ 3: прямая проверка стандартных путей
elif [ -x "/usr/bin/python3" ]; then
    PYTHON_CMD="/usr/bin/python3"
elif [ -x "/usr/local/bin/python3" ]; then
    PYTHON_CMD="/usr/local/bin/python3"
fi

if [ -z "$PYTHON_CMD" ]; then
    echo -e "${RED}Ошибка: Python 3 не найден${NC}"
    echo "Установите Python 3.8 или выше"
    exit 1
fi

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

# Запуск с подробным выводом и генерацией отчёта
pytest tests/test_calculator.py \
    -v \
    --tb=short \
    --browser=chromium \
    --html=test-report.html \
    --self-contained-html \
    -rs || TEST_EXIT_CODE=$?

# Сохранение кода выхода
TEST_EXIT_CODE=${TEST_EXIT_CODE:-$?}

echo ""
echo "=============================================="
echo "ИТОГОВЫЙ ОТЧЁТ"
echo "=============================================="

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ ВСЕ ТЕСТЫ ПРОЙДЕНЫ${NC}"
    echo "Статус: PASSED"
else
    echo -e "${RED}✗ ТЕСТЫ НЕ ПРОЙДЕНЫ${NC}"
    echo "Статус: FAILED"
    echo ""
    echo "Сводка ошибок:"
    echo "----------------------------------------------"
fi

echo ""
echo "Код выхода: ${TEST_EXIT_CODE}"
echo "Полный отчёт: test-report.html"
echo "=============================================="
echo ""

# Деактивация виртуального окружения
deactivate

exit $TEST_EXIT_CODE
