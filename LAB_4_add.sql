-- Серверный вывод результатов
SET SERVEROUTPUT ON;

-- Вспомогательная таблица
CREATE TABLE buildings_vspomog (
    buildkey       NUMBER,
    typeobj        VARCHAR2(15) NOT NULL,
    clientkey      INTEGER NOT NULL,
    teamkey        INTEGER NOT NULL,
    contraktdate   DATE NOT NULL,
    enddate        DATE NOT NULL,
    contractprice  NUMBER(38, 2),
    selected_month VARCHAR2(10),
    PRIMARY KEY ( buildkey,
                  selected_month )
); -- TODO в отчет

--!----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * Создать процедуру, копирующую строки с информацией о строительстве в текущем месяце во вспомогательную таблицу. Подсчитать количество извлеченных строк.
--!----------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE buildings_current_month IS

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

    CURSOR exist_months IS
    SELECT
        selected_month
    FROM
        buildings_vspomog
    ORDER BY
        selected_month;

    err EXCEPTION;
BEGIN
    OPEN required_buildings;
    FETCH required_buildings INTO line_atr;
    IF required_buildings%notfound THEN
        RAISE err;
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
    WHEN storage_error THEN
        raise_application_error(
                               -6500,
                               'Не хватает оперативной памяти!'
        );
    WHEN err THEN
        dbms_output.put_line('В этом месяце нет строительств или они уже добавлены в вспомогательную таблицу');
END;
/ 

--!-------------------------------------------------------------------------------------------------------
-- * Создать функцию, подсчитывающую, сколько было затрачено на материалы 
--!-------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION all_money_of_build (
    bk buildings.buildkey%TYPE
) RETURN stuf.price_of_stuf%TYPE IS

    allmoney       stuf.price_of_stuf%TYPE DEFAULT 0;
    CURSOR curs_stufkey_needed IS
    SELECT
        stufkey,
        neededstuf
    FROM
        s_s
    WHERE
        s_s.buildkey = bk;

    stufkey_needed curs_stufkey_needed%rowtype;
    price_stuf     stuf.price_of_stuf%TYPE;
    err EXCEPTION;
BEGIN
    OPEN curs_stufkey_needed;
    FETCH curs_stufkey_needed INTO stufkey_needed;
    IF curs_stufkey_needed%notfound THEN
        RAISE err;
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

        allmoney := allmoney + price_stuf * stufkey_needed.neededstuf;
        FETCH curs_stufkey_needed INTO stufkey_needed;
    END LOOP;

    RETURN allmoney;
EXCEPTION
    WHEN timeout_on_resource THEN
        raise_application_error(
                               -20002,
                               'Превышен интервал ожидания'
        );
    WHEN value_error THEN
        raise_application_error(
                               -20004,
                               'Ошибка в операции преобразования или математической операции!'
        );
    WHEN err THEN
        dbms_output.put_line('По этому строительству пока что нет заказов на материалы');
END all_money_of_build;
/

SELECT
    all_money_of_build(
        5
    )
FROM
    dual;

--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Локальная программа (считает деньги по каждому этапу)
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION all_money_of_stage_in_build (
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
    err EXCEPTION;
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
        RAISE err;
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
        raise_application_error(
                               100,
                               'Превышен интервал ожидания'
        );
    WHEN value_error THEN
        raise_application_error(
                               -20004,
                               'Ошибка в операции преобразования или математической операции!'
        );
    WHEN err THEN
        dbms_output.put_line('По этому строительству пока что нет заказов на материалы');
END all_money_of_stage_in_build;
/

SELECT
    all_money_of_stage_in_build(
        5, 41
    )
FROM
    dual;

    
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Функция + локалка
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION all_money_of_build (
    bk buildings.buildkey%TYPE
) RETURN stuf.price_of_stuf%TYPE IS

    allmoney    stuf.price_of_stuf%TYPE DEFAULT 0;
    CURSOR curs_build_stage IS
    SELECT
        *
    FROM
        b_s
    WHERE
        b_s.buildkey = bk;

    build_stage curs_build_stage%rowtype;
    err EXCEPTION;
BEGIN
    OPEN curs_build_stage;
    FETCH curs_build_stage INTO build_stage;
    IF curs_build_stage%notfound THEN
        RAISE err;
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
    WHEN timeout_on_resource THEN
        raise_application_error(
                               -20002,
                               'Превышен интервал ожидания'
        );
    WHEN value_error THEN
        raise_application_error(
                               -20004,
                               'Ошибка в операции преобразования или математической операции!'
        );
    WHEN err THEN
        dbms_output.put_line('По этому строительству пока что нет заказов на материалы');
END all_money_of_build;
/

SELECT
    all_money_of_build(
        5
    )
FROM
    dual;




--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Перегруз 
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE buildings_current_month (
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
                AND buildings_vspomog.selected_month = to_char(month_num
                                                               || '.'
                                                               || year_num)
        );

    err EXCEPTION;
BEGIN
    OPEN required_buildings;
    FETCH required_buildings INTO line_atr;
    IF required_buildings%notfound THEN
        RAISE err;
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
    WHEN storage_error THEN
        raise_application_error(
                               -6500,
                               'Не хватает оперативной памяти!'
        );
    WHEN err THEN
        dbms_output.put_line('В этом месяце нет строительств или они уже добавлены в вспомогательную таблицу');
END;
/ 