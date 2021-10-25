SET linesize 500;

/*«Текущие этапы работы» (условная выборка); +*/
SELECT
    B_S.*,
    b.typeobj,
    s.stagename
FROM
    B_S,
    Stages s,
    buildings b
WHERE
    B_S.stagekey = s.stagekey
    AND B_S.buildKey = b.buildKey;

/*ИЛИ*/
/*c внутренним соединением +*/
-- SELECT
--     buildKey,
--     typeobj,
--     stagekey,
--     stagename
-- FROM
--     buildings
--     INNER JOIN (
--         SELECT
--             *
--         FROM
--             B_S
--             INNER JOIN stages USING (stagekey)
--     ) USING (buildKey);

/*«Сроки строительства объектов» / Кол-во затраченного материала на объект (итоговый запрос); +*/
SELECT
    b.buildKey,
    SUM(neededstuf) AS total_stuff
FROM
    buildings b,
    S_S
WHERE
    b.buildKey = S_S.buildKey
GROUP BY
    b.buildKey;

/*«Объекты заданного процента завершенности» (параметрический запрос); +*/
SELECT
    B_S.*,
    s.stagename
FROM
    B_S,
    Stages s
WHERE
    B_S.stagekey = s.stagekey
    AND B_S.stagekey = & y_stagekey;

/*«Общий список объектов и стройматериалов с указанием количества этапов» (запрос на объединение);*/
/*Сколько всего было построено по типам и сколько стройматериалов всего было использовано*/
SELECT
    typeobj,
    total
FROM
    objectstypes
    JOIN (
        SELECT
            typeobj,
            count(typeobj) AS total
        FROM
            buildings
        GROUP BY
            typeobj
    ) USING(typeobj)
UNION
SELECT
    stufName,
    all_needed
FROM
    stuf
    JOIN(
        SELECT
            stufKey,
            SUM(neededstuf) AS all_needed
        FROM
            S_S
        GROUP BY
            stufKey
    ) USING(stufKey);

/*«Количество построенных объектов по кварталам» (запрос по полю с типом дата) +*/
SELECT
    TO_CHAR(enddate, 'q') AS quarter,
    COUNT(buildKey) AS Finished_buildings
FROM
    buildings
WHERE
    endDate < (
        SELECT
            sysdate
        FROM
            dual
    )
GROUP BY
    TO_CHAR(enddate, 'q');

/*Список заказчиков у которых объект "ТипN"  *IN* +*/
SELECT
    *
FROM
    clients
WHERE
    clientkey IN (
        SELECT
            clientkey
        FROM
            buildings
        WHERE
            typeobj = 'Тип&typeobj'
    );

/* Запрос на любимого клиента!  *ALL/ANY* +*/
SELECT
    c.*,
    b.contractPrice
FROM
    clients c,
    buildings b
WHERE
    b.contractPrice >= ALL (
        SELECT
            contractPrice
        FROM
            buildings
    )
    AND c.clientKey = b.clientKey;

/* Список стройматериала который был задействован на объекте   *EXISTS/NOT EXISTS * +*/
SELECT
    stufKey,
    stufName
FROM
    stuf
WHERE
    EXISTS (
        SELECT
            1
        FROM
            S_S
        WHERE
            S_S.stufKey = stuf.stufKey
            AND buildkey = & buildkey
    );

/*Внешнее соединение +*/
SELECT
    *
FROM
    teams
    LEFT JOIN buildings USING(teamkey);

/*вывести бригадиров у которых общая стоимость выполненых объектов больше средней*/
SELECT
    lead,
    total_money
FROM
    teams
    JOIN (
        SELECT
            teamkey,
            sum(contractprice) AS total_money
        FROM
            buildings
        GROUP BY
            teamkey
        HAVING
            sum(contractprice) >= (
                SELECT
                    avg(contractprice)
                FROM
                    buildings
            )
        ORDER BY
            sum(contractprice) DESC
    ) USING(teamkey);


--* Обновление
UPDATE
    teams
SET
    STRENGTH = CASE
        WHEN teamkey = 1 THEN 8
        WHEN teamkey = 2 THEN 8
        ELSE STRENGTH
    END;