--!-----------------------------------------------------------------------------------------------------------------------------------------------------
--* У каждой бригады может быть только одно акутальное строительство 
--* + 
--* Если уже было два заказа, то стоимость уменьшивестя на 3%
--!-----------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER teams_employment_and_down_price_trig BEFORE
    INSERT ON buildings
    FOR EACH ROW
    WHEN ( sysdate <= new.contraktdate )
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


--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
--* Отслеживать последовательное выполнение этапов по каждому объекту строительства 
--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER sequence_of_stages_trig BEFORE
    INSERT ON build_stage
    FOR EACH ROW
DECLARE
    old_stage INTEGER;
BEGIN
    SELECT
        MAX(stagekey)
    INTO old_stage
    FROM
        b_s
    WHERE
        buildkey = :new.buildkey;

    IF :new.stagekey - old_stage != 1 THEN
        raise_application_error(
                               -20002,
                               'Введенный этап строительства не соответсвует ожидаемому. Код ожидаемого этапа выполнения => ' ||(
                               old_stage + 1)
        );
    END IF;

END;
/

INSERT INTO b_s (
    buildkey,
    stagekey
) VALUES (
    21,
    45
);

--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
--* Если происходит замена бригады на строительстве,
--* а у этой бригады уже есть активное своё стрительство,
--* то дата конца контракта своего строительства увеличивается на месяц
--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER buildings_compound FOR
    UPDATE OF teamkey ON buildings
COMPOUND TRIGGER
    active_team      BOOLEAN;
    CURSOR busy_teams_curs IS
    SELECT
        buildkey,
        teamkey
    FROM
        buildings
    WHERE
        sysdate BETWEEN contraktdate AND enddate
    UNION
    SELECT
        buildkey,
        teamkey
    FROM
        buildings
    WHERE
        sysdate < contraktdate;

    TYPE active_buildings_arr IS
        TABLE OF INTEGER INDEX BY PLS_INTEGER;
    active_buildings active_buildings_arr;
    build_active     INTEGER;
    need_build       INTEGER;
    BEFORE STATEMENT IS BEGIN
        FOR busy_teams IN busy_teams_curs LOOP
            active_buildings(busy_teams.buildkey) := busy_teams.teamkey;
        END LOOP;
    END BEFORE STATEMENT;
    BEFORE EACH ROW IS BEGIN
        dbms_output.put_line('im here');
        build_active := active_buildings.first;
        WHILE build_active IS NOT NULL LOOP
            IF :new.teamkey = active_buildings(build_active) THEN
                active_team := true;
                need_build := build_active;
            END IF;

            build_active := active_buildings.next(build_active);
        END LOOP;

        dbms_output.put_line('im here ended');
    END BEFORE EACH ROW;
    AFTER STATEMENT IS BEGIN
        IF active_team THEN
            UPDATE buildings
            SET
                enddate = enddate + 30
            WHERE
                buildkey = need_build;

        END IF;
    END AFTER STATEMENT;
END;
/

-- Update rows in a Table

UPDATE buildings
SET
    teamkey = 1
WHERE
    buildkey = 21;

CREATE OR REPLACE TRIGGER buildings_compound FOR
    UPDATE OF teamkey ON buildings
COMPOUND TRIGGER
    active_team BOOLEAN;
    BEFORE EACH ROW IS BEGIN
        dbms_output.put_line('im here');
        IF :new.teamkey = 1 THEN
            active_team := true;
        END IF;
        dbms_output.put_line('im here ended');
    END BEFORE EACH ROW;
    AFTER STATEMENT IS BEGIN
        IF active_team THEN
            UPDATE buildings
            SET
                enddate = enddate + 30
            WHERE
                buildkey = 22;

        END IF;
    END AFTER STATEMENT;
END;
/
