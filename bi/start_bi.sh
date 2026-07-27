#!/usr/bin/env bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "=== 🚀 Подготовка прототипа Lightdash (Option 3: Open-Source BI for dbt-core) ==="

if [ ! -f .env ]; then
    echo "📋 Создание файла конфигурации .env на основе .env.example..."
    cp .env.example .env
    # Сгенерировать случайный LIGHTDASH_SECRET если openssl доступен
    if command -v openssl >/dev/null 2>&1; then
        RANDOM_SECRET=$(openssl rand -hex 16)
        sed -i '' "s/super_secret_lightdash_key_32_chars_long_minimum/$RANDOM_SECRET/g" .env 2>/dev/null || true
    fi
fi

echo "🐳 Запуск Docker контейнеров Lightdash и PostgreSQL..."
docker compose up -d

echo ""
echo "⏳ Ожидание запуска Lightdash web UI..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8080/api/v1/health >/dev/null 2>&1; then
        echo "✅ Lightdash успешно запущен и доступен по адресу: http://localhost:8080"
        echo ""
        echo "📌 Шаги для первого входа:"
        echo " 1. Откройте http://localhost:8080 в браузере."
        echo " 2. Зарегистрируйте первый аккаунт администратора."
        echo " 3. Создайте проект и подключите локальный dbt проект (укажите путь /usr/app/dbt_project или подключите Git)."
        echo " 4. Все метрики и dimensions из YML-файлов dbt будут автоматически импортированы!"
        exit 0
    fi
    echo "   Ожидание ответа от http://localhost:8080... ($attempt/$max_attempts)"
    sleep 3
    attempt=$((attempt+1))
done

echo "⚠️  Контейнеры запущены, но веб-интерфейс ещё инициализируется. Проверьте статус командой: docker compose logs -f"
