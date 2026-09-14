@echo off
REM Скрипт запуска автотестов TestQuest — Калькулятор смет для Windows
REM Использование: set BASE_URL=https://testquest.pryaniky.com && run-tests.bat

setlocal enabledelayedexpansion

echo ==============================================
echo TestQuest — Калькулятор смет: Запуск тестов
echo ==============================================
echo.

REM Базовый URL по умолчанию
if "%BASE_URL%"=="" set BASE_URL=https://testquest.pryaniky.com
echo BASE_URL: %BASE_URL%
echo.

REM Переход в директорию скрипта
cd /d "%~dp0"

REM Проверка наличия Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python не найден
    echo Установите Python 3.8 или выше
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo Версия Python: %PYTHON_VERSION%

REM Создание виртуального окружения если нет
if not exist "venv" (
    echo.
    echo [INFO] Создание виртуального окружения...
    python -m venv venv
)

REM Активация виртуального окружения
echo [INFO] Активация виртуального окружения...
call venv\Scripts\activate.bat

REM Установка зависимостей
echo.
echo [INFO] Установка зависимостей...
pip install --quiet --upgrade pip
pip install --quiet -r tests\requirements.txt

REM Установка браузеров Playwright
echo.
echo [INFO] Проверка браузеров Playwright...
playwright install chromium

REM Запуск тестов
echo.
echo ==============================================
echo Запуск тестов pytest...
echo ==============================================
echo.

set BASE_URL=%BASE_URL%

REM Запуск с подробным выводом
pytest tests\test_calculator.py ^
    -v ^
    --tb=short ^
    --browser=chromium

set TEST_EXIT_CODE=%errorlevel%

echo.
echo ==============================================
echo РЕЗУЛЬТАТ
echo ==============================================

if %TEST_EXIT_CODE% equ 0 (
    echo RESULT: PASSED
    echo Все тесты пройдены успешно!
) else (
    echo RESULT: FAILED
    echo Некоторые тесты не прошли. Проверьте вывод выше.
)

echo.
echo Код выхода: %TEST_EXIT_CODE%
echo Отчёт: test-report.html
echo.

REM Деактивация виртуального окружения
call deactivate

exit /b %TEST_EXIT_CODE%
