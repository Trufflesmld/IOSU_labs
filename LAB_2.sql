SET
    linesize 500;

/*«Текущие этапы работы» (условная выборка);*/
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
/*c внутренним соединением*/
SELECT
    buildKey,
    typeobj,
    stagekey,
    stagename
FROM
    buildings
    INNER JOIN (
        SELECT
            *
        FROM
            B_S
            INNER JOIN stages USING (stagekey)
    ) USING (buildKey);

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
SELECT
    stagename
FROM
    stages
UNION
SELECT
    stufname
FROM
    stuf;

/*чтото наваял*/
SELECT
    DISTINCT typeobj,
    stagekey
FROM
    buildings
    INNER JOIN S_S USING(buildkey)
UNION
SELECT
    stufname,
    stagekey
FROM
    stuf
    INNER JOIN S_S USING(stufkey);

/*«Количество построенных объектов по кварталам» (запрос по полю с типом дата)*/
SELECT
    TO_CHAR(enddate, 'q') AS quarter,
    COUNT(buildKey) AS Finished_buildings
FROM
    buildings
GROUP BY
    TO_CHAR(enddate, 'q');

/*Список заказчиков у которых объект "ТипN"  *IN* */
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

/* Заказчик который сделал самый дорогой заказ  *ALL/ANY* */
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

/* Список стройматериала который был задействован на объекте   *EXISTS/NOT EXISTS **/
SELECT
    stufKey,
    stufName
FROM
    stuf
WHERE
    EXISTS (
        SELECT
            *
        FROM
            S_S
        WHERE
            S_S.stufKey = stuf.stufKey
            AND buildkey = & buildkey
    );

/*Сводная таблица Этап материал со стройматериалом и его колвом на складе*/
/*Внешнее соединение*/
SELECT
    *
FROM
    S_S FULL
    JOIN stuf USING(stufkey);