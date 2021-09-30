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
    );

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

/*Обновляемое представление*/
CREATE VIEW clients_view AS
SELECT
    *
FROM
    clients;
to_char(sysdate, 'd hh24')

SELECT 2+2 from dual where to_char(sysdate, 'd');