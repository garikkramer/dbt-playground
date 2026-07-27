# Прототип On-Premise BI: Lightdash + dbt-core (Вариант 3)

Данный каталог содержит готовый прототип локального/On-Premise развертывания **Lightdash** — открытого BI-инструмента, созданного специально для нативной работы с `dbt-core`.

---

## 🎯 Преимущества Lightdash для dbt-core

1. **Автоматическое считывание семантики из dbt**: Lightdash напрямую парсит `schema.yml` и `dbt_project.yml`. Все `dimensions`, `metrics` и описания моделей из вашей dbt-сборки мгновенно становятся доступны в BI без повторного описания.
2. **Полный On-Premise**: Не требует подключения к dbt Cloud или внешним SaaS-сервисам.
3. **Версионирование в Git**: Все изменения и дашборды привязаны к вашей кодовой базе dbt.

---

## 🚀 Быстрый запуск

### 1. Запуск стека через Docker Compose

Из текущей директории `bi/` выполните скрипт запуска:

```bash
./start_bi.sh
```

Или вручную через docker-compose:

```bash
cp .env.example .env
docker compose up -d
```

Сервис будет доступен по адресу: **[http://localhost:8080](http://localhost:8080)**

---

### 2. Первая настройка и подключение `dbt-project`

1. Перейдите по адресу **`http://localhost:8080`**.
2. Создайте учетную запись администратора.
3. В мастере создания проекта (Create Project):
   - **Connection Type**: Выберите тип вашей целевой СУБД (в нашем случае `DuckDB` или `Postgres/Trino/Snowflake`).
   - **dbt project setup**: 
     - При локальном развертывании в Docker проекте путь к скомпилированному dbt-проекту смонтирован в контейнер: `/usr/app/dbt_project`.
     - Либо укажите ссылку на ваш **Git-репозиторий** с dbt-проектом.
4. После сохранения Lightdash автоматически просканирует метаданные из `target/manifest.json` и `target/catalog.json` (сгенерированные командой `dbt compile` / `dbt docs generate`).

---

### 3. Описание метрик в dbt (`schema.yml`)

Для того чтобы поля и метрики отображались в Lightdash, они описываются стандартным образом в `schema.yml` dbt-моделей:

```yaml
version: 2

models:
  - name: q9_semantic
    description: "Агрегированные данные по выручке и заказам TPC-H"
    columns:
      - name: nation
        description: "Страна клиентоориентированных продаж"
        meta:
          dimension:
            type: string

      - name: o_year
        description: "Год заказа"
        meta:
          dimension:
            type: number

      - name: amount
        description: "Сумма продаж"
        meta:
          metrics:
            total_amount:
              type: sum
              description: "Суммарная выручка"
            avg_amount:
              type: average
              description: "Средний чек"
```

---

## 🛠 Полезные команды

- **Просмотр логов Lightdash**:
  ```bash
  docker compose logs -f lightdash
  ```

- **Остановка прототипа**:
  ```bash
  docker compose down
  ```

- **Очистка данных (включая БД метаданных Lightdash)**:
  ```bash
  docker compose down -v
  ```
