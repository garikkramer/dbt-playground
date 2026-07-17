-- ==========================================
-- TPC-H Query 1
-- ==========================================
-- Постановка задачи для разработчика:
-- Разработайте отчет об итогах ценообразования (Pricing Summary Report) для позиций заказов (таблица `lineitem`), отгруженных до указанной даты (в текущем примере: '1998-09-02').
-- Необходимо сгруппировать данные по флагам возврата (`l_returnflag`) и статусу доставки (`l_linestatus`).
-- 
-- Для каждой группы рассчитайте следующие метрики:
-- 1. Общее количество заказанных деталей (`sum_qty`).
-- 2. Суммарную базовую стоимость без учета скидок (`sum_base_price`).
-- 3. Суммарную стоимость с учетом скидки (`sum_disc_price`).
-- 4. Суммарную стоимость с учетом скидки и налога (`sum_charge`).
-- 5. Среднее количество деталей в одной позиции (`avg_qty`).
-- 6. Среднюю цену позиции (`avg_price`).
-- 7. Средний размер предоставленной скидки (`avg_disc`).
-- 8. Общее количество отгруженных позиций (`count_order`).
-- 
-- Результат отсортируйте по флагам `l_returnflag` и `l_linestatus` в алфавитном порядке.

SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity) AS sum_qty,
    sum(l_extendedprice) AS sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) AS sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    avg(l_quantity) AS avg_qty,
    avg(l_extendedprice) AS avg_price,
    avg(l_discount) AS avg_disc,
    count(*) AS count_order
FROM
    lineitem
WHERE
    l_shipdate <= CAST('1998-09-02' AS date)
GROUP BY
    l_returnflag,
    l_linestatus
ORDER BY
    l_returnflag,
    l_linestatus;


-- ==========================================
-- TPC-H Query 2
-- ==========================================
-- Постановка задачи для разработчика:
-- Найдите поставщиков в определенном регионе (в примере: 'EUROPE'), которые предлагают минимальную цену (`ps_supplycost`) на детали конкретного размера (размер = 15) и типа (тип заканчивается на 'BRASS').
-- 
-- Требуется вывести:
-- - Баланс счета поставщика (`s_acctbal`)
-- - Имя поставщика (`s_name`)
-- - Название страны поставщика (`n_name`)
-- - Идентификатор детали (`p_partkey`)
-- - Производителя детали (`p_mfgr`)
-- - Адрес поставщика (`s_address`)
-- - Телефон поставщика (`s_phone`)
-- - Комментарий к поставщику (`s_comment`)
-- 
-- Сортировка: по балансу счета (по убыванию), названию страны (по возрастанию), имени поставщика (по возрастанию) и идентификатору детали.
-- Ограничьте вывод первыми 100 записями.

SELECT
    s_acctbal,
    s_name,
    n_name,
    p_partkey,
    p_mfgr,
    s_address,
    s_phone,
    s_comment
FROM
    part,
    supplier,
    partsupp,
    nation,
    region
WHERE
    p_partkey = ps_partkey
    AND s_suppkey = ps_suppkey
    AND p_size = 15
    AND p_type LIKE '%BRASS'
    AND s_nationkey = n_nationkey
    AND n_regionkey = r_regionkey
    AND r_name = 'EUROPE'
    AND ps_supplycost = (
        SELECT
            min(ps_supplycost)
        FROM
            partsupp,
            supplier,
            nation,
            region
        WHERE
            p_partkey = ps_partkey
            AND s_suppkey = ps_suppkey
            AND s_nationkey = n_nationkey
            AND n_regionkey = r_regionkey
            AND r_name = 'EUROPE')
ORDER BY
    s_acctbal DESC,
    n_name,
    s_name,
    p_partkey
LIMIT 100;


-- ==========================================
-- TPC-H Query 3
-- ==========================================
-- Постановка задачи для разработчика:
-- Определите приоритеты доставки для невыполненных заказов (Shipping Priority Query). Необходимо найти ТОП-10 заказов, которые принесли наибольший доход в определенном сегменте рынка клиентов (в примере: 'BUILDING').
-- Заказы должны быть созданы строго до заданной даты ('1995-03-15'), а их доставка (хотя бы одной позиции) должна быть запланирована или осуществлена после этой же даты.
-- 
-- Выведите:
-- - Идентификатор заказа (`l_orderkey`)
-- - Рассчитанный доход (`revenue` = сумма стоимости со скидкой)
-- - Дату заказа (`o_orderdate`)
-- - Приоритет отгрузки заказа (`o_shippriority`)
-- 
-- Отсортируйте результат по убыванию дохода, а при равенстве доходов — по дате заказа (по возрастанию).

SELECT
    l_orderkey,
    sum(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderdate,
    o_shippriority
FROM
    customer,
    orders,
    lineitem
WHERE
    c_mktsegment = 'BUILDING'
    AND c_custkey = o_custkey
    AND l_orderkey = o_orderkey
    AND o_orderdate < CAST('1995-03-15' AS date)
    AND l_shipdate > CAST('1995-03-15' AS date)
GROUP BY
    l_orderkey,
    o_orderdate,
    o_shippriority
ORDER BY
    revenue DESC,
    o_orderdate
LIMIT 10;


-- ==========================================
-- TPC-H Query 4
-- ==========================================
-- Постановка задачи для разработчика:
-- Проанализируйте приоритеты заказов (Order Priority Query) за определенный квартал (с '1993-07-01' по '1993-10-01').
-- Требуется подсчитать количество заказов, сгруппированных по их приоритету (`o_orderpriority`), в которых хотя бы одна позиция товара была доставлена клиенту позже обещанного срока (`l_commitdate < l_receiptdate`).
-- 
-- Результат должен быть отсортирован по приоритету заказа в алфавитном порядке.

SELECT
    o_orderpriority,
    count(*) AS order_count
FROM
    orders
WHERE
    o_orderdate >= CAST('1993-07-01' AS date)
    AND o_orderdate < CAST('1993-10-01' AS date)
    AND EXISTS (
        SELECT
            *
        FROM
            lineitem
        WHERE
            l_orderkey = o_orderkey
            AND l_commitdate < l_receiptdate)
GROUP BY
    o_orderpriority
ORDER BY
    o_orderpriority;


-- ==========================================
-- TPC-H Query 5
-- ==========================================
-- Постановка задачи для разработчика:
-- Рассчитайте объем выручки, полученной от местных поставщиков (Local Supplier Volume Query) в пределах одного географического региона (в примере: 'ASIA') за указанный год (с '1994-01-01' по '1995-01-01').
-- Покупатель и поставщик должны находиться в одной стране, принадлежащей указанному региону.
-- 
-- Выведите:
-- - Название страны (`n_name`)
-- - Общую выручку со скидкой (`revenue`)
-- 
-- Сгруппируйте данные по странам и отсортируйте по выручке в порядке убывания.

SELECT
    n_name,
    sum(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    customer,
    orders,
    lineitem,
    supplier,
    nation,
    region
WHERE
    c_custkey = o_custkey
    AND l_orderkey = o_orderkey
    AND l_suppkey = s_suppkey
    AND c_nationkey = s_nationkey
    AND s_nationkey = n_nationkey
    AND n_regionkey = r_regionkey
    AND r_name = 'ASIA'
    AND o_orderdate >= CAST('1994-01-01' AS date)
    AND o_orderdate < CAST('1995-01-01' AS date)
GROUP BY
    n_name
ORDER BY
    revenue DESC;


-- ==========================================
-- TPC-H Query 6
-- ==========================================
-- Постановка задачи для разработчика:
-- Постройте запрос для прогнозирования изменения выручки (Forecasting Revenue Change) при изменении политики скидок.
-- Необходимо подсчитать общую сумму скидок (`l_extendedprice * l_discount`) для всех позиций товаров, отгруженных в течение конкретного года (в примере: '1994'), у которых:
-- 1. Процент скидки находится в диапазоне от 5% до 7% включительно (0.06 +/- 0.01).
-- 2. Количество товара в позиции строго меньше 24.

SELECT
    sum(l_extendedprice * l_discount) AS revenue
FROM
    lineitem
WHERE
    l_shipdate >= CAST('1994-01-01' AS date)
    AND l_shipdate < CAST('1995-01-01' AS date)
    AND l_discount BETWEEN 0.05
    AND 0.07
    AND l_quantity < 24;


-- ==========================================
-- TPC-H Query 7
-- ==========================================
-- Постановка задачи для разработчика:
-- Проанализируйте двусторонний объем перевозок (Volume Shipping Query) между двумя конкретными странами (в примере: 'FRANCE' и 'GERMANY') за 1995 и 1996 годы.
-- Учитывайте как поставки из Франции в Германию, так и из Германии во Францию.
-- 
-- Выведите:
-- - Страну-отправителя (`supp_nation`)
-- - Страну-получателя (`cust_nation`)
-- - Год отгрузки товара (`l_year`)
-- - Суммарную выручку со скидкой (`revenue`)
-- 
-- Сгруппируйте и отсортируйте результат по стране-отправителю, стране-получателю и году.

SELECT
    supp_nation,
    cust_nation,
    l_year,
    sum(volume) AS revenue
FROM (
    SELECT
        n1.n_name AS supp_nation,
        n2.n_name AS cust_nation,
        extract(year FROM l_shipdate) AS l_year,
        l_extendedprice * (1 - l_discount) AS volume
    FROM
        supplier,
        lineitem,
        orders,
        customer,
        nation n1,
        nation n2
    WHERE
        s_suppkey = l_suppkey
        AND o_orderkey = l_orderkey
        AND c_custkey = o_custkey
        AND s_nationkey = n1.n_nationkey
        AND c_nationkey = n2.n_nationkey
        AND ((n1.n_name = 'FRANCE'
                AND n2.n_name = 'GERMANY')
            OR (n1.n_name = 'GERMANY'
                AND n2.n_name = 'FRANCE'))
        AND l_shipdate BETWEEN CAST('1995-01-01' AS date)
        AND CAST('1996-12-31' AS date)) AS shipping
GROUP BY
    supp_nation,
    cust_nation,
    l_year
ORDER BY
    supp_nation,
    cust_nation,
    l_year;


-- ==========================================
-- TPC-H Query 8
-- ==========================================
-- Постановка задачи для разработчика:
-- Определите долю национального рынка (National Market Share Query) конкретной страны (в примере: 'BRAZIL') в рамках определенного региона ('AMERICA') для деталей конкретного типа ('ECONOMY ANODIZED STEEL') за 1995 и 1996 годы.
-- Доля рассчитывается как отношение стоимости деталей, поставленных из указанной страны покупателям из указанного региона, к общей стоимости деталей этого типа, поставленных любыми странами покупателям из этого же региона.
-- 
-- Выведите:
-- - Год заказа (`o_year`)
-- - Долю рынка (`mkt_share`) в виде коэффициента от 0 до 1.
-- 
-- Отсортируйте по году заказа.

SELECT
    o_year,
    sum(
        CASE WHEN nation = 'BRAZIL' THEN
            volume
        ELSE
            0
        END) / sum(volume) AS mkt_share
FROM (
    SELECT
        extract(year FROM o_orderdate) AS o_year,
        l_extendedprice * (1 - l_discount) AS volume,
        n2.n_name AS nation
    FROM
        part,
        supplier,
        lineitem,
        orders,
        customer,
        nation n1,
        nation n2,
        region
    WHERE
        p_partkey = l_partkey
        AND s_suppkey = l_suppkey
        AND l_orderkey = o_orderkey
        AND o_custkey = c_custkey
        AND c_nationkey = n1.n_nationkey
        AND n1.n_regionkey = r_regionkey
        AND r_name = 'AMERICA'
        AND s_nationkey = n2.n_nationkey
        AND o_orderdate BETWEEN CAST('1995-01-01' AS date)
        AND CAST('1996-12-31' AS date)
        AND p_type = 'ECONOMY ANODIZED STEEL') AS all_nations
GROUP BY
    o_year
ORDER BY
    o_year;


-- ==========================================
-- TPC-H Query 9
-- ==========================================
-- Постановка задачи для разработчика:
-- Рассчитайте годовую чистую прибыль (Product Type Profit Measure) от продаж деталей, название которых содержит определенное слово (в примере: 'green').
-- Прибыль рассчитывается как разница между ценой продажи со скидкой (`l_extendedprice * (1 - l_discount)`) и стоимостью закупки у поставщика (`ps_supplycost * l_quantity`).
-- 
-- Результат сгруппируйте по:
-- - Стране поставщика (`nation`)
-- - Году заказа (`o_year`)
-- 
-- Отсортируйте по названию страны (по возрастанию), а внутри страны — по году (по убыванию).

SELECT
    nation,
    o_year,
    sum(amount) AS sum_profit
FROM (
    SELECT
        n_name AS nation,
        extract(year FROM o_orderdate) AS o_year,
        l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity AS amount
    FROM
        part,
        supplier,
        lineitem,
        partsupp,
        orders,
        nation
    WHERE
        s_suppkey = l_suppkey
        AND ps_suppkey = l_suppkey
        AND ps_partkey = l_partkey
        AND p_partkey = l_partkey
        AND o_orderkey = l_orderkey
        AND s_nationkey = n_nationkey
        AND p_name LIKE '%green%') AS profit
GROUP BY
    nation,
    o_year
ORDER BY
    nation,
    o_year DESC;


-- ==========================================
-- TPC-H Query 10
-- ==========================================
-- Постановка задачи для разработчика:
-- Сформируйте отчет по возвратам товаров клиентами (Returned Item Reporting Query) за определенный квартал (с '1993-10-01' по '1994-01-01').
-- Нам нужно найти клиентов, которые принесли наибольшие потери из-за возвращенных товаров (позиции со статусом возврата `l_returnflag = 'R'`).
-- 
-- Выведите ТОП-20 клиентов, для каждого указав:
-- - Идентификатор (`c_custkey`) и имя (`c_name`)
-- - Общую сумму потерь (`revenue` = сумма стоимости возвращенных позиций со скидкой)
-- - Баланс счета (`c_acctbal`)
-- - Название страны (`n_name`), адрес (`c_address`), телефон (`c_phone`) и комментарий (`c_comment`)
-- 
-- Отсортируйте клиентов по убыванию суммы потерь.

SELECT
    c_custkey,
    c_name,
    sum(l_extendedprice * (1 - l_discount)) AS revenue,
    c_acctbal,
    n_name,
    c_address,
    c_phone,
    c_comment
FROM
    customer,
    orders,
    lineitem,
    nation
WHERE
    c_custkey = o_custkey
    AND l_orderkey = o_orderkey
    AND o_orderdate >= CAST('1993-10-01' AS date)
    AND o_orderdate < CAST('1994-01-01' AS date)
    AND l_returnflag = 'R'
    AND c_nationkey = n_nationkey
GROUP BY
    c_custkey,
    c_name,
    c_acctbal,
    c_phone,
    n_name,
    c_address,
    c_comment
ORDER BY
    revenue DESC
LIMIT 20;


-- ==========================================
-- TPC-H Query 11
-- ==========================================
-- Постановка задачи для разработчика:
-- Разработайте запрос для анализа критически важных запасов на складах (Important Stock Identification Query).
-- Необходимо найти все детали, находящиеся на складах поставщиков определенной страны (в примере: 'GERMANY'), суммарная стоимость запасов которых (`ps_supplycost * ps_availqty`) превышает заданную долю (в примере: 0.0001 от общей стоимости всех запасов в этой стране).
-- 
-- Выведите:
-- - Идентификатор детали (`ps_partkey`)
-- - Общую стоимость ее запасов в этой стране (`value`)
-- 
-- Отсортируйте список по стоимости запасов в порядке убывания.

SELECT
    ps_partkey,
    sum(ps_supplycost * ps_availqty) AS value
FROM
    partsupp,
    supplier,
    nation
WHERE
    ps_suppkey = s_suppkey
    AND s_nationkey = n_nationkey
    AND n_name = 'GERMANY'
GROUP BY
    ps_partkey
HAVING
    sum(ps_supplycost * ps_availqty) > (
        SELECT
            sum(ps_supplycost * ps_availqty) * 0.0001000000
        FROM
            partsupp,
            supplier,
            nation
        WHERE
            ps_suppkey = s_suppkey
            AND s_nationkey = n_nationkey
            AND n_name = 'GERMANY')
ORDER BY
    value DESC;


-- ==========================================
-- TPC-H Query 12
-- ==========================================
-- Постановка задачи для разработчика:
-- Изучите влияние различных режимов доставки (Shipping Modes and Order Priority Query) на задержку выполнения заказов с высоким и низким приоритетом.
-- Необходимо рассмотреть заказы, доставленные определенными видами транспорта (в примере: 'MAIL' и 'SHIP') в интервале с '1994-01-01' по '1995-01-01', у которых дата фактического получения (`l_receiptdate`) оказалась позже обещанной даты отгрузки (`l_commitdate`), но при этом товар был отправлен вовремя (`l_shipdate < l_commitdate`).
-- 
-- Сгруппируйте позиции по типу доставки (`l_shipmode`) и посчитайте количество позиций для двух групп приоритетов:
-- 1. Высокий приоритет (`high_line_count`): заказы с приоритетом '1-URGENT' или '2-HIGH'.
-- 2. Низкий приоритет (`low_line_count`): все остальные приоритеты заказов.
-- 
-- Отсортируйте результат по типу доставки.

SELECT
    l_shipmode,
    sum(
        CASE WHEN o_orderpriority = '1-URGENT'
            OR o_orderpriority = '2-HIGH' THEN
            1
        ELSE
            0
        END) AS high_line_count,
    sum(
        CASE WHEN o_orderpriority <> '1-URGENT'
            AND o_orderpriority <> '2-HIGH' THEN
            1
        ELSE
            0
        END) AS low_line_count
FROM
    orders,
    lineitem
WHERE
    o_orderkey = l_orderkey
    AND l_shipmode IN ('MAIL', 'SHIP')
    AND l_commitdate < l_receiptdate
    AND l_shipdate < l_commitdate
    AND l_receiptdate >= CAST('1994-01-01' AS date)
    AND l_receiptdate < CAST('1995-01-01' AS date)
GROUP BY
    l_shipmode
ORDER BY
    l_shipmode;


-- ==========================================
-- TPC-H Query 13
-- ==========================================
-- Постановка задачи для разработчика:
-- Проанализируйте распределение клиентов по количеству сделанных ими заказов (Customer Distribution Query).
-- Необходимо выяснить, сколько клиентов не сделали ни одного заказа, сколько сделали ровно 1 заказ, 2 заказа и т.д.
-- При анализе исключите заказы, комментарии которых содержат словосочетание 'special' и 'requests' в указанном порядке (используйте маску `%special%requests%`).
-- 
-- Выведите:
-- - Количество заказов на одного клиента (`c_count`)
-- - Количество клиентов с таким числом заказов (`custdist`)
-- 
-- Отсортируйте результат по количеству клиентов (по убыванию), а при равенстве — по количеству заказов (по убыванию).

SELECT
    c_count,
    count(*) AS custdist
FROM (
    SELECT
        c_custkey,
        count(o_orderkey)
    FROM
        customer
    LEFT OUTER JOIN orders ON c_custkey = o_custkey
    AND o_comment NOT LIKE '%special%requests%'
GROUP BY
    c_custkey) AS c_orders (c_custkey,
        c_count)
GROUP BY
    c_count
ORDER BY
    custdist DESC,
    c_count DESC;


-- ==========================================
-- TPC-H Query 14
-- ==========================================
-- Постановка задачи для разработчика:
-- Оцените эффективность маркетинговых и промо-акций за конкретный месяц (в примере: сентябрь 1995 года).
-- Необходимо рассчитать процент выручки от промо-товаров в общей выручке компании за этот период. Промо-товарами считаются детали, тип которых начинается со слова 'PROMO' (`p_type LIKE 'PROMO%'`).
-- 
-- Выведите одну метрику:
-- - Доля промо-выручки в процентах (`promo_revenue`).

SELECT
    100.00 * sum(
        CASE WHEN p_type LIKE 'PROMO%' THEN
            l_extendedprice * (1 - l_discount)
        ELSE
            0
        END) / sum(l_extendedprice * (1 - l_discount)) AS promo_revenue
FROM
    lineitem,
    part
WHERE
    l_partkey = p_partkey
    AND l_shipdate >= date '1995-09-01'
    AND l_shipdate < CAST('1995-10-01' AS date);


-- ==========================================
-- TPC-H Query 15
-- ==========================================
-- Постановка задачи для разработчика:
-- Определите лучшего поставщика (Top Supplier Query) за конкретный квартал (с '1996-01-01' по '1996-04-01').
-- Лучшим считается поставщик, который сгенерировал максимальную выручку (`total_revenue` = сумма стоимости отгруженных позиций со скидкой).
-- 
-- Для решения задачи:
-- 1. Создайте временное представление (VIEW) или обобщенное табличное выражение (CTE) для расчета выручки каждого поставщика за указанный период.
-- 2. Найдите поставщика(ов) с максимальной выручкой.
-- 3. Выведите: идентификатор поставщика (`s_suppkey`), имя (`s_name`), адрес (`s_address`), телефон (`s_phone`) и общую выручку (`total_revenue`).
-- 4. После выполнения запроса убедитесь, что временное представление удалено.

WITH revenue AS (
    SELECT
        l_suppkey AS supplier_no,
        sum(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM
        lineitem
    WHERE
        l_shipdate >= CAST('1996-01-01' AS date)
      AND l_shipdate < CAST('1996-04-01' AS date)
    GROUP BY
        supplier_no
)
SELECT
    s_suppkey,
    s_name,
    s_address,
    s_phone,
    total_revenue
FROM
    supplier,
    revenue
WHERE
    s_suppkey = supplier_no
    AND total_revenue = (
        SELECT
            max(total_revenue)
        FROM revenue)
ORDER BY
    s_suppkey;


-- ==========================================
-- TPC-H Query 16
-- ==========================================
-- Постановка задачи для разработчика:
-- Проанализируйте ассортимент деталей и связи с поставщиками (Parts/Supplier Relationship Query).
-- Необходимо найти количество уникальных поставщиков, поставляющих детали со следующими характеристиками:
-- 1. Деталь НЕ произведена брендом 'Brand#45'.
-- 2. Тип детали НЕ содержит фразу 'MEDIUM POLISHED'.
-- 3. Размер детали соответствует одному из заданных значений: 49, 14, 23, 45, 19, 3, 36, 9.
-- 4. Поставщик не должен иметь жалоб от клиентов (в его комментарии `s_comment` отсутствует шаблон `Customer%Complaints`).
-- 
-- Выведите:
-- - Бренд детали (`p_brand`)
-- - Тип детали (`p_type`)
-- - Размер детали (`p_size`)
-- - Количество уникальных подходящих поставщиков (`supplier_cnt`)
-- 
-- Сгруппируйте по бренду, типу и размеру. Сортировка: по количеству поставщиков (по убыванию), затем по бренду, типу и размеру (по возрастанию).

SELECT
    p_brand,
    p_type,
    p_size,
    count(DISTINCT ps_suppkey) AS supplier_cnt
FROM
    partsupp,
    part
WHERE
    p_partkey = ps_partkey
    AND p_brand <> 'Brand#45'
    AND p_type NOT LIKE 'MEDIUM POLISHED%'
    AND p_size IN (49, 14, 23, 45, 19, 3, 36, 9)
    AND ps_suppkey NOT IN (
        SELECT
            s_suppkey
        FROM
            supplier
        WHERE
            s_comment LIKE '%Customer%Complaints%')
GROUP BY
    p_brand,
    p_type,
    p_size
ORDER BY
    supplier_cnt DESC,
    p_brand,
    p_type,
    p_size;


-- ==========================================
-- TPC-H Query 17
-- ==========================================
-- Постановка задачи для разработчика:
-- Рассчитайте упущенную выгоду от обслуживания мелкооптовых заказов (Small-Quantity Revenue Query) на детали определенного бренда и упаковки (в примере: бренд 'Brand#23' и упаковка 'MED BOX').
-- Мелкооптовыми считаются заказы, в которых количество деталей данной позиции меньше 20% от среднего объема заказа для этой детали во всей базе данных.
-- 
-- Требуется рассчитать среднегодовую упущенную выручку (сумму стоимости мелкооптовых позиций со скидкой, деленную на 7 лет эксплуатации системы). Выведите полученную сумму как `avg_yearly`.

SELECT
    sum(l_extendedprice) / 7.0 AS avg_yearly
FROM
    lineitem,
    part
WHERE
    p_partkey = l_partkey
    AND p_brand = 'Brand#23'
    AND p_container = 'MED BOX'
    AND l_quantity < (
        SELECT
            0.2 * avg(l_quantity)
        FROM
            lineitem
        WHERE
            l_partkey = p_partkey);


-- ==========================================
-- TPC-H Query 18
-- ==========================================
-- Постановка задачи для разработчика:
-- Найдите крупных клиентов (Large Volume Customer Query), которые когда-либо оформляли заказы с общим объемом позиций более 300 единиц.
-- 
-- Выведите:
-- - Имя клиента (`c_name`)
-- - Идентификатор клиента (`c_custkey`)
-- - Идентификатор заказа (`o_orderkey`)
-- - Дату заказа (`o_orderdate`)
-- - Общую стоимость заказа (`o_totalprice`)
-- - Общее количество деталей в этом заказе (`sum(l_quantity)`)
-- 
-- Сортировка: по общей стоимости заказа (по убыванию), затем по дате заказа (по возрастанию).

SELECT
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice,
    sum(l_quantity)
FROM
    customer,
    orders,
    lineitem
WHERE
    o_orderkey IN (
        SELECT
            l_orderkey
        FROM
            lineitem
        GROUP BY
            l_orderkey
        HAVING
            sum(l_quantity) > 300)
    AND c_custkey = o_custkey
    AND o_orderkey = l_orderkey
GROUP BY
    c_name,
    c_custkey,
    o_orderkey,
    o_orderdate,
    o_totalprice
ORDER BY
    o_totalprice DESC,
    o_orderdate
LIMIT 100;


-- ==========================================
-- TPC-H Query 19
-- ==========================================
-- Постановка задачи для разработчика:
-- Разработайте оптимизированный запрос для расчета выручки со скидкой по специальным предложениям (Discounted Revenue Query).
-- Необходимо подсчитать выручку от заказов на детали, удовлетворяющие одному из трех сложных наборов условий (комбинации бренда, упаковки, количества и размеров), доставляемых авиационным транспортом (`l_shipmode` в ('AIR', 'AIR REG')) и упакованных в защитную упаковку (`l_shipinstruct = 'DELIVER IN PERSON'`).
-- 
-- Оптимизируйте запрос, используя операторы OR для объединения условий по трем группам деталей.

SELECT
    sum(l_extendedprice * (1 - l_discount)) AS revenue
FROM
    lineitem,
    part
WHERE (p_partkey = l_partkey
    AND p_brand = 'Brand#12'
    AND p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    AND l_quantity >= 1
    AND l_quantity <= 1 + 10
    AND p_size BETWEEN 1 AND 5
    AND l_shipmode IN ('AIR', 'AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON')
    OR (p_partkey = l_partkey
        AND p_brand = 'Brand#23'
        AND p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
        AND l_quantity >= 10
        AND l_quantity <= 10 + 10
        AND p_size BETWEEN 1 AND 10
        AND l_shipmode IN ('AIR', 'AIR REG')
        AND l_shipinstruct = 'DELIVER IN PERSON')
    OR (p_partkey = l_partkey
        AND p_brand = 'Brand#34'
        AND p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
        AND l_quantity >= 20
        AND l_quantity <= 20 + 10
        AND p_size BETWEEN 1 AND 15
        AND l_shipmode IN ('AIR', 'AIR REG')
        AND l_shipinstruct = 'DELIVER IN PERSON');


-- ==========================================
-- TPC-H Query 20
-- ==========================================
-- Постановка задачи для разработчика:
-- Найдите потенциальных кандидатов для промо-кампании среди поставщиков (Potential Part Promotion Query).
-- Нам нужны поставщики из конкретной страны (в примере: 'CANADA'), которые имеют на складах значительный запас определенной детали (название начинается на 'forest%').
-- Значительным запасом считается ситуация, когда доступный объем детали на складе поставщика (`ps_availqty`) превышает 50% от суммарного объема этой детали, отгруженного этим поставщиком в заказах за указанный год (в примере: 1994).
-- 
-- Выведите имя поставщика (`s_name`) и адрес (`s_address`). Отсортируйте по имени поставщика.

SELECT
    s_name,
    s_address
FROM
    supplier,
    nation
WHERE
    s_suppkey IN (
        SELECT
            ps_suppkey
        FROM
            partsupp
        WHERE
            ps_partkey IN (
                SELECT
                    p_partkey
                FROM
                    part
                WHERE
                    p_name LIKE 'forest%')
                AND ps_availqty > (
                    SELECT
                        0.5 * sum(l_quantity)
                    FROM
                        lineitem
                    WHERE
                        l_partkey = ps_partkey
                        AND l_suppkey = ps_suppkey
                        AND l_shipdate >= CAST('1994-01-01' AS date)
                        AND l_shipdate < CAST('1995-01-01' AS date)))
            AND s_nationkey = n_nationkey
            AND n_name = 'CANADA'
        ORDER BY
            s_name;


-- ==========================================
-- TPC-H Query 21
-- ==========================================
-- Постановка задачи для разработчика:
-- Выявите поставщиков, которые систематически задерживали поставки многокомпонентных заказов (Suppliers Who Kept Orders Waiting Query).
-- Требуется найти поставщиков из определенной страны (в примере: 'SAUDI ARABIA'), у которых позиция в заказе была доставлена позже обещанного срока (`l_receiptdate > l_commitdate`), при условии, что:
-- 1. В заказе было несколько позиций от разных поставщиков.
-- 2. Данный поставщик оказался единственным, кто просрочил доставку в рамках этого заказа.
-- 
-- Выведите ТОП-100 поставщиков по количеству таких инцидентов (`numwait`), указав имя поставщика (`s_name`).
-- Сортируйте по убыванию числа просрочек, затем по имени поставщика.

SELECT
    s_name,
    count(*) AS numwait
FROM
    supplier,
    lineitem l1,
    orders,
    nation
WHERE
    s_suppkey = l1.l_suppkey
    AND o_orderkey = l1.l_orderkey
    AND o_orderstatus = 'F'
    AND l1.l_receiptdate > l1.l_commitdate
    AND EXISTS (
        SELECT
            *
        FROM
            lineitem l2
        WHERE
            l2.l_orderkey = l1.l_orderkey
            AND l2.l_suppkey <> l1.l_suppkey)
    AND NOT EXISTS (
        SELECT
            *
        FROM
            lineitem l3
        WHERE
            l3.l_orderkey = l1.l_orderkey
            AND l3.l_suppkey <> l1.l_suppkey
            AND l3.l_receiptdate > l3.l_commitdate)
    AND s_nationkey = n_nationkey
    AND n_name = 'SAUDI ARABIA'
GROUP BY
    s_name
ORDER BY
    numwait DESC,
    s_name
LIMIT 100;


-- ==========================================
-- TPC-H Query 22
-- ==========================================
-- Постановка задачи для разработчика:
-- Найдите потенциальные возможности для глобальных продаж (Global Sales Opportunity Query).
-- Требуется определить количество потенциальных клиентов в определенных странах (коды телефонов: '13', '31', '23', '29', '30', '18', '17'), которые:
-- 1. Еще ни разу не совершали заказов.
-- 2. Баланс их аккаунта (`c_acctbal`) строго больше среднего положительного баланса клиентов в этих же странах.
-- 
-- Выведите:
-- - Код страны (первые 2 цифры телефона)
-- - Количество таких клиентов (`numcust`)
-- - Общую сумму балансов их счетов (`totacctbal`)
-- 
-- Сгруппируйте и отсортируйте результат по коду страны.

SELECT
    cntrycode,
    count(*) AS numcust,
    sum(c_acctbal) AS totacctbal
FROM (
    SELECT
        substring(c_phone FROM 1 FOR 2) AS cntrycode,
        c_acctbal
    FROM
        customer
    WHERE
        substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17')
        AND c_acctbal > (
            SELECT
                avg(c_acctbal)
            FROM
                customer
            WHERE
                c_acctbal > 0.00
                AND substring(c_phone FROM 1 FOR 2) IN ('13', '31', '23', '29', '30', '18', '17'))
            AND NOT EXISTS (
                SELECT
                    *
                FROM
                    orders
                WHERE
                    o_custkey = c_custkey)) AS custsale
GROUP BY
    cntrycode
ORDER BY
    cntrycode;


