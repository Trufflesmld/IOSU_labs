--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Пакет 
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
--Create a new Package

CREATE PACKAGE pack IS

  -- Add a procedure
    PROCEDURE buildings_current_month;

    PROCEDURE buildings_current_month (
        month_num IN NUMBER,
        year_num  IN NUMBER
    );

  -- Add a function
    FUNCTION all_money_of_build (
        bk buildings.buildkey%TYPE
    ) RETURN stuf.price_of_stuf%TYPE;

    FUNCTION all_money_of_stage_in_build (
        bk     buildings.buildkey%TYPE,
        stagek stages.stagekey%TYPE
    ) RETURN stuf.price_of_stuf%TYPE;

END pack;
/

--Create a new Package Body

CREATE OR REPLACE PACKAGE BODY pack IS

--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * Создать процедуру, копирующую строки с информацией о строительстве в текущем месяце во вспомогательную таблицу. Подсчитать количество извлеченных строк.
--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE buildings_current_month IS

        counter_buildings NUMBER;
        line_atr          buildings%rowtype;
        CURSOR required_buildings IS
        SELECT
            *
        FROM
            buildings
        WHERE
            buildings.enddate > (
                SELECT
                    sysdate
                FROM
                    dual
            )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    buildings_vspomog
                WHERE
                    buildings_vspomog.buildkey = buildings.buildkey
            );

        err1 EXCEPTION;
    BEGIN
        OPEN required_buildings;
        FETCH required_buildings INTO line_atr;
        IF required_buildings%notfound THEN
            RAISE err1;
        END IF;
        LOOP
            EXIT WHEN required_buildings%notfound;
            counter_buildings := required_buildings%rowcount;
            INSERT INTO buildings_vspomog VALUES (
                line_atr.buildkey,
                line_atr.typeobj,
                line_atr.clientkey,
                line_atr.teamkey,
                line_atr.contraktdate,
                line_atr.enddate,
                line_atr.contractprice,
                to_char(
                    sysdate, 'mm.yyyy'
                )
            );

            FETCH required_buildings INTO line_atr;
        END LOOP;

        COMMIT;
        CLOSE required_buildings;
        dbms_output.put_line('Количество объектов:' || counter_buildings);
    EXCEPTION
        WHEN err1 THEN
            dbms_output.put_line('В этом месяце нет строительств или они уже добавлены в вспомогательную таблицу');
    END buildings_current_month;
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Перегруз 
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
    PROCEDURE buildings_current_month (
        month_num IN NUMBER,
        year_num  IN NUMBER
    ) IS

        counter_buildings NUMBER;
        line_atr          buildings%rowtype;
        CURSOR required_buildings IS
        SELECT
            *
        FROM
            buildings
        WHERE
            to_char(
                buildings.enddate
            ) > to_date(
                to_char(month_num
                        || '.'
                        || year_num), 'mm.yyyy'
            )
            AND buildings.contraktdate < ( to_date(
                to_char(month_num + 1
                        || '.'
                        || year_num), 'mm.yyyy'
            ) - 1 )
            AND NOT EXISTS (
                SELECT
                    1
                FROM
                    buildings_vspomog
                WHERE
                    buildings_vspomog.buildkey = buildings.buildkey
            );

        err1 EXCEPTION;
    BEGIN
        OPEN required_buildings;
        FETCH required_buildings INTO line_atr;
        IF required_buildings%notfound THEN
            RAISE err1;
        END IF;
        LOOP
            EXIT WHEN required_buildings%notfound;
            counter_buildings := required_buildings%rowcount;
            INSERT INTO buildings_vspomog VALUES (
                line_atr.buildkey,
                line_atr.typeobj,
                line_atr.clientkey,
                line_atr.teamkey,
                line_atr.contraktdate,
                line_atr.enddate,
                line_atr.contractprice,
                to_char(month_num
                        || '.'
                        || year_num)
            );

            FETCH required_buildings INTO line_atr;
        END LOOP;

        COMMIT;
        CLOSE required_buildings;
        dbms_output.put_line('Количество объектов:' || counter_buildings);
    EXCEPTION
        WHEN err1 THEN
            dbms_output.put_line('В этом месяце нет строительств или они уже добавлены в вспомогательную таблицу');
    END buildings_current_month;




--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Локальная программа (считает деньги по каждому этапу)
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
    FUNCTION all_money_of_stage_in_build (
        bk     buildings.buildkey%TYPE,
        stagek stages.stagekey%TYPE
    ) RETURN stuf.price_of_stuf%TYPE IS

        allmoney_of_stage stuf.price_of_stuf%TYPE DEFAULT 0;
        CURSOR curs_stufkey_needed IS
        SELECT
            stufkey,
            neededstuf
        FROM
            s_s
        WHERE
            s_s.buildkey = bk
            AND s_s.stagekey = stagek;

        stufkey_needed    curs_stufkey_needed%rowtype;
        price_stuf        stuf.price_of_stuf%TYPE;
        name_of_stage     stages.stagename%TYPE;
        err1 EXCEPTION;
    BEGIN
        SELECT
            stagename
        INTO name_of_stage
        FROM
            stages
        WHERE
            stages.stagekey = stagek;

        OPEN curs_stufkey_needed;
        FETCH curs_stufkey_needed INTO stufkey_needed;
        IF curs_stufkey_needed%notfound THEN
            RAISE err1;
        END IF;
        LOOP
            EXIT WHEN curs_stufkey_needed%notfound;
            SELECT
                price_of_stuf
            INTO price_stuf
            FROM
                stuf
            WHERE
                stuf.stufkey = stufkey_needed.stufkey;

            allmoney_of_stage := allmoney_of_stage + price_stuf * stufkey_needed.neededstuf;
            FETCH curs_stufkey_needed INTO stufkey_needed;
        END LOOP;

        RETURN allmoney_of_stage;
    EXCEPTION
        WHEN no_data_found THEN
            dbms_output.put_line('Некорректный этап');
            RETURN NULL;
        WHEN err1 THEN
            dbms_output.put_line('По запрашиваемому этапу строительства нет информации');
            RETURN NULL;
    END all_money_of_stage_in_build;
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Функция + локалка
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
    FUNCTION all_money_of_build (
        bk buildings.buildkey%TYPE
    ) RETURN stuf.price_of_stuf%TYPE IS

        allmoney    stuf.price_of_stuf%TYPE DEFAULT 0;
        CURSOR curs_build_stage IS
        SELECT
            *
        FROM
            b_s
        WHERE
            b_s.buildkey = bk
            AND EXISTS (
                SELECT
                    1
                FROM
                    buildings
                WHERE
                    buildings.buildkey = bk
            );

        build_stage curs_build_stage%rowtype;
        err1 EXCEPTION;
    BEGIN
        OPEN curs_build_stage;
        FETCH curs_build_stage INTO build_stage;
        IF curs_build_stage%notfound THEN
            RAISE err1;
        END IF;
        LOOP
            EXIT WHEN curs_build_stage%notfound;
            allmoney := allmoney + all_money_of_stage_in_build(
                                                              build_stage.buildkey,
                                                              build_stage.stagekey
                                   );
            FETCH curs_build_stage INTO build_stage;
        END LOOP;

        RETURN allmoney;
    EXCEPTION
        WHEN err1 THEN
            dbms_output.put_line('Такого строительства не существует');
            RETURN NULL;
    END all_money_of_build;

END pack;
/




--!--------------------------------------------------------------------------------------------------------------------------------------
--* Анонимный блок
--!--------------------------------------------------------------------------------------------------------------------------------------
BEGIN
    dbms_output.put_line('Процедура нормальная:');
    pack.buildings_current_month;
    INSERT INTO buildings (
        typeobj,
        clientkey,
        teamkey,
        contraktdate,
        enddate,
        contractprice
    ) VALUES (
        'Тип3',
        3,
        3,
        TO_DATE('22.05.21', 'dd.mm.yy'),
        TO_DATE('26.12.21', 'dd.mm.yy'),
        100000
    );

    COMMIT;
    dbms_output.put_line('Процедура (если какие-то строительства месяца добавлены, но появилось новое):');
    pack.buildings_current_month;
    dbms_output.put_line('Процедура (если все записи по данному месяцу существуют в вспомогательной таблице):');
    pack.buildings_current_month;
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('Функция нормальная:');
    dbms_output.put_line('Затраченные средства на строительство 5 - ' || pack.all_money_of_build(5));
    dbms_output.put_line('Функция в исключении своём:');
    dbms_output.put_line(pack.all_money_of_build(100));
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('Функция локалка:');
    dbms_output.put_line('Затраченные средства на строительство 5 на этапе 3 - '
                         || pack.all_money_of_stage_in_build(
                                                            5,
                                                            43
                            ));
    dbms_output.put_line('Функция локалка в исключении програмном:');
    dbms_output.put_line(pack.all_money_of_stage_in_build(
                                                         5,
                                                         75
                         ));
    dbms_output.put_line('Функция локалка в исключении своём:');
    dbms_output.put_line(pack.all_money_of_stage_in_build(
                                                         21,
                                                         47
                         ));
    dbms_output.put_line('--------------------------------------------------------------------------------');
    dbms_output.put_line('Процедура перегруз нормальная:');
    pack.buildings_current_month(
                                4,
                                2021
    );
END;
/


-- TODO: В отчет код пакета + анонимный блок + вывод
