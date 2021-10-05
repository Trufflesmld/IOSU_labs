/*Горизонтальное представление*/
CREATE
OR REPLACE VIEW TEAMS_TYPE_2 AS
SELECT
    *
FROM
    teams
WHERE
    teamkey IN (
        SELECT
            teamkey
        FROM
            buildings
        WHERE
            typeobj = 'Тип2'
    ) WITH CHECK OPTION CONSTRAINT TYPE_2;

/*не работает*/
INSERT INTO
    teams_type_2
VALUES
    (teams_seq.nextval, 'lol kek cheburek', 14);

/*работает*/
UPDATE
    teams_type_2
SET
    strength = 9
WHERE
    teamkey = 2;

/*не работает*/
DELETE FROM
    teams_type_2
WHERE
    lead = 'Остапенко Игорь Николаевич';

/*Вертикальное/смешанное представление*/
CREATE
OR REPLACE VIEW buildings_view AS
SELECT
    buildKey,
    typeobj,
    lead,
    fname || ' ' || lname AS clent_name,
    contraktdate,
    enddate,
    CONTRACTPRICE
FROM
    buildings
    JOIN teams USING (teamkey)
    JOIN clients USING (clientkey) WITH READ ONLY;

/*не работает*/
UPDATE
    buildings_view
SET
    lead = 'lol kek'
WHERE
    buildKey = 6;.

/*не работает*/
INSERT INTO
    buildings_view (
        typeObj,
        lead,
        client_name,
        contraktDate,
        endDate,
        CONTRACTPRICE
    )
VALUES
    (
        'Тип1',
        'lol',
        'kek',
        to_date('23.06.21', 'dd.mm.yy'),
        to_date('15.08.21', 'dd.mm.yy'),
        100.75
    );

/*не работает*/
DELETE FROM
    buildings_view
WHERE
    lead = 'Остапенко Игорь Николаевич';

/*Обновляемое представление*/
CREATE
OR REPLACE VIEW clients_view AS
SELECT
    *
FROM
    clients
WHERE
    (
        SELECT
            to_number(to_char(sysdate, 'd'))
        FROM
            dual
    ) BETWEEN 2
    AND 6
    AND (
        SELECT
            to_number(to_char(sysdate, 'hh24'))
        FROM
            dual
    ) BETWEEN 9
    AND 17;