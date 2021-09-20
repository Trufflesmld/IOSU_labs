/*«Текущие этапы работы» (условная выборка);*/
SELECT
    B_S.*,
    s.stagename
FROM
    B_S,
    Stages s
WHERE
    B_S.stagekey = s.stagekey;

/*«Сроки строительства объектов» / Кол-во затраченного материала на объект (итоговый запрос);*/
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

/*«Объекты заданного процента завершенности» (параметрический запрос);*/
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

/*«Количество построенных объектов по кварталам» сделанных во втором квартале (запрос по полю с типом дата)*/
ALTER SESSION SET NLS_DATE_FORMAT = 'DD.MM.YY HH24:MI:SS';
SELECT COUNT(buildKey) AS Finished_buildings FROM buildings WHERE TO_CHAR(enddate, 'MM') BETWEEN &init_month  AND &end_month;

