/*Серверный вывод результатов*/
SET
    SERVEROUTPUT ON;

CREATE TABLE buildings_vspomog(
    buildKey NUMBER,
    typeObj VARCHAR2(15) NOT NULL,
    clientKey INTEGER NOT NULL,
    teamKey INTEGER NOT NULL,
    contraktDate DATE NOT NULL,
    endDate DATE NOT NULL,
    contractPrice number(38, 2)
);

/*
 *Создать процедуру, копирующую строки с информацией о строительстве в текущем месяце во вспомогательную таблицу. Подсчитать количество извлеченных строк.*/
CREATE
OR REPLACE PROCEDURE buildings_current_month IS Today DATE DEFAULT SYSDATE;

counter_buildings number;

line_atr buildings % ROWTYPE;

cursor required_buildings IS
SELECT
    *
FROM
    buildings
WHERE
    buildings.endDate > (
        SELECT
            sysdate
        FROM
            dual
    );

err EXCEPTION;

BEGIN OPEN required_buildings;

IF required_buildings % notfound THEN RAISE err;
end if;

LOOP FETCH required_buildings INTO line_atr;

EXIT
WHEN required_buildings % notfound;

counter_buildings := required_buildings % rowcount;

INSERT INTO
    buildings_vspomog
VALUES
    (
        line_atr.buildKey,
        line_atr.typeObj,
        line_atr.clientKey,
        line_atr.teamKey,
        line_atr.contraktDate,
        line_atr.endDate,
        line_atr.contractPrice
    );

END LOOP;

close required_buildings;

DBMS_OUTPUT.PUT_LINE('Количество: ' || counter_buildings);

EXCEPTION
WHEN STORAGE_ERROR THEN RAISE_APPLICATION_ERROR(-6500, 'Не хватает оперативной памяти!');

WHEN err THEN DBMS_OUTPUT.PUT_LINE('В этом месяце нет строительств');

END;

/
/* 
 *Создать функцию, подсчитывающую, сколько этапов выполнено по каждому объекту. Вернуть количество объектов, по которым завершены все этапы.*/