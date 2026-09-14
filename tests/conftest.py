"""
Фикстуры для тестов калькулятора смет TestQuest.
"""
import os
import pytest
from playwright.sync_api import sync_playwright, Page


@pytest.fixture(scope="session")
def base_url():
    """Получение базового URL из переменной окружения или использование значения по умолчанию."""
    return os.environ.get("BASE_URL", "https://testquest.pryaniky.com")


@pytest.fixture(scope="session")
def browser_type():
    """Тип браузера для запуска (chromium, firefox, webkit)."""
    return os.environ.get("BROWSER_TYPE", "chromium")


@pytest.fixture(scope="session")
def headless():
    """Запуск браузера в headless режиме."""
    return os.environ.get("HEADLESS", "true").lower() == "true"


@pytest.fixture(scope="session")
def playwright_instance():
    """Создание экземпляра Playwright."""
    with sync_playwright() as p:
        yield p


@pytest.fixture(scope="session")
def browser(playwright_instance, browser_type, headless):
    """Создание браузера."""
    launch_args = {"headless": headless}
    
    if browser_type == "firefox":
        browser = playwright_instance.firefox.launch(**launch_args)
    elif browser_type == "webkit":
        browser = playwright_instance.webkit.launch(**launch_args)
    else:
        browser = playwright_instance.chromium.launch(**launch_args)
    yield browser
    browser.close()


@pytest.fixture(scope="session")
def context(browser):
    """Создание контекста браузера."""
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        ignore_https_errors=True,
    )
    yield context
    context.close()


@pytest.fixture
def page(context):
    """Создание новой страницы для каждого теста."""
    page = context.new_page()
    yield page
    page.close()


@pytest.fixture
def calculator_page(page, base_url):
    """Переход на страницу калькулятора и ожидание загрузки."""
    page.goto(base_url, timeout=30000)
    
    # Ждём появления навигации
    page.wait_for_selector('a.nav-item[data-page="calculator"]', timeout=10000)
    
    # Клик на вкладку калькулятора
    page.click('a.nav-item[data-page="calculator"]')
    
    # Ждём пока блок калькулятора станет видимым
    page.wait_for_function("""
        () => {
            const el = document.querySelector('#page-calculator');
            return el && !el.hidden;
        }
    """, timeout=10000)
    
    # Дополнительная задержка для полной загрузки
    page.wait_for_timeout(2000)
    
    yield page
