--!-----------------------------------------------------------------------------------------------------------------------------------------------------
--* У каждой бригады может быть только одно акутальное строительство 
--* + 
--* Если уже было два заказа, то стоимость уменьшивестя на 3%
--!-----------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER teams_employment_and_down_price_trig BEFORE
    INSERT ON buildings
    FOR EACH ROW
DECLARE
    count_build INTEGER DEFAULT 0;
    CURSOR busy_teams_curs IS
    SELECT
        teamkey,
        contraktdate,
        enddate
    FROM
        buildings
    WHERE
        sysdate BETWEEN contraktdate AND enddate
    UNION
    SELECT
        teamkey,
        contraktdate,
        enddate
    FROM
        buildings
    WHERE
        sysdate < contraktdate;

BEGIN
    IF sysdate < :new.contraktdate THEN
        FOR busy_teams IN busy_teams_curs LOOP
            IF
                :new.teamkey = busy_teams.teamkey
                AND :new.contraktdate < busy_teams.enddate
            THEN
                raise_application_error(
                                       -20001,
                                       'Бригада занята'
                );
            END IF;
        END LOOP;
    END IF;

    SELECT
        COUNT(1)
    INTO count_build
    FROM
        buildings
    WHERE
        clientkey = :new.clientkey;

    IF count_build > 2 THEN
        :new.contractprice := :new.contractprice * 0.97;
    END IF;

END;
/

INSERT INTO buildings (
    typeobj,
    clientkey,
    teamkey,
    contraktdate,
    enddate,
    contractprice
) VALUES (
    'Тип1',
    6,
    2,
    TO_DATE('23.11.21', 'dd.mm.yy'),
    TO_DATE('15.12.21', 'dd.mm.yy'),
    100
);
