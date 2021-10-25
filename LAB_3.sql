/*Горизонтальное представление*/
CREATE OR REPLACE VIEW teams_type_2 AS
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
        )
WITH CHECK OPTION CONSTRAINT type_2;

/*не работает*/
INSERT INTO teams_type_2 VALUES (
    teams_seq.NEXTVAL,
    'lol kek cheburek',
    14
);

/*работает*/
UPDATE teams_type_2
SET
    strength = 9
WHERE
    teamkey = 2;

/*не работает*/
DELETE FROM teams_type_2
WHERE
    lead = 'Остапенко �?горь Николаевич';

/*Вертикальное/смешанное представление*/
CREATE OR REPLACE VIEW buildings_view AS
    SELECT
        buildkey,
        typeobj,
        lead,
        fname
        || ' '
        || lname AS client_name,
        contraktdate,
        enddate,
        contractprice
    FROM
        buildings
        JOIN teams USING ( teamkey )
        JOIN clients USING ( clientkey );

/*не работает*/
UPDATE buildings_view
SET
    lead = 'lol kek'
WHERE
    buildkey = 6;


/*не работает*/
INSERT INTO buildings_view (
    typeobj,
    lead,
    client_name,
    enddate,
    contractprice
) VALUES (
    'Тип1',
    'lol',
    'kek',
    TO_DATE('15.08.21', 'dd.mm.yy'),
    100.75
);

/*не работает*/
DELETE FROM buildings_view
WHERE
    lead = 'Остапенко �?горь Николаевич';

DELETE FROM buildings_view
WHERE
    buildkey = '6';

/*Обновляемое представление*/
CREATE OR REPLACE VIEW clients_view AS
    SELECT
        *
    FROM
        clients
    WHERE
        (
            SELECT
                to_number(
                    to_char(
                        sysdate, 'd'
                    )
                )
            FROM
                dual
        ) BETWEEN 2 AND 6
        AND (
            SELECT
                to_number(
                    to_char(
                        sysdate, 'hh24'
                    )
                )
            FROM
                dual
        ) BETWEEN 9 AND 16
WITH CHECK OPTION;
