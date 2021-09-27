SET
    linesize 500
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

/*«Общий список объектов и стройматериалов с указанием количества этапов» (запрос на объединение); не вывез*/
SELECT
    stagename
FROM
    stages
UNION
SELECT
    stufname
FROM
    stuf;

/*«Количество построенных объектов по кварталам» (запрос по полю с типом дата)*/
SELECT
    TO_CHAR(enddate, 'q') AS quarter,
    COUNT(buildKey) AS Finished_buildings
FROM
    buildings
GROUP BY
    TO_CHAR(enddate, 'q');