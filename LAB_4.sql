/*Серверный вывод результатов*/
SET SERVEROUTPUT ON;

-- * Вспомогательная таблица
CREATE TABLE buildings_vspomog (
    buildkey      NUMBER,
    typeobj       VARCHAR2(15) NOT NULL,
    clientkey     INTEGER NOT NULL,
    teamkey       INTEGER NOT NULL,
    contraktdate  DATE NOT NULL,
    enddate       DATE NOT NULL,
    contractprice NUMBER(38, 2)
);

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
            line_atr.contractprice
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
        dbms_output.put_line('В этом месяце нет строительств');
END;
/ 


--!-------------------------------------------------------------------------------------------------------
-- * Создать функцию, подсчитывающую, сколько было затрацено на материалы 
--!-------------------------------------------------------------------------------------------------------
