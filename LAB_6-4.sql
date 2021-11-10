--!-------------------------------------------------------------------------------------------------------------------------------------------------------------
--* Написать программу, которая позволит для двух указанных в параметрах таблиц существующей БД определить, есть ли между ними связь «один ко многим».
--* Если связь есть, то на основе родительской таблицы создать новую, в которой будут присутствовать все поля старой и одно новое поле с типом коллекции, 
--* в котором при переносе данных помещаются все связанные записи из дочерней таблицы.
--!--------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_one_to_many (
    parent_tab IN VARCHAR2,
    child_tab  IN VARCHAR2
) RETURN BOOLEAN IS
    ref_tab_name VARCHAR2(100) DEFAULT NULL;
BEGIN
    EXECUTE IMMEDIATE 'SELECT 
                        cons_r.table_name r_table_name
                    FROM 
                        user_constraints cons
                    LEFT JOIN user_constraints cons_r ON cons_r.constraint_name = cons.r_constraint_name
                    WHERE
                        cons.constraint_type = ''R''
                        AND cons.table_name = '''
                      || upper(child_tab)
                      || ''' AND cons_r.table_name = '''
                      || upper(parent_tab)
                      || ''''
    INTO ref_tab_name;

    RETURN true;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END;
/

CREATE FUNCTION create_unique_name (
    str1 IN VARCHAR2,
    str2 IN VARCHAR2
) RETURN VARCHAR2 IS
    result_name VARCHAR2(100);
    unique_id   NUMBER;
BEGIN
    unique_id := to_number(replace(
                                  to_char(sysdate - TO_DATE('23.10.2000', 'dd.mm.yyyy')),
                                  '.'
                           ));

    result_name := str1
                   || '_'
                   || str2
                   || '_'
                   || unique_id;
    RETURN result_name;
END;
/

CREATE OR REPLACE PROCEDURE parent_child_tab (
    parent_tab IN VARCHAR2,
    child_tab  IN VARCHAR2
) IS
rec_select VARCHAR2(200);
    select_rec_parent VARCHAR2(200);
    select_rec_child  VARCHAR2(200);
    table_name        VARCHAR2(100);
    type_object_name  VARCHAR2(100);
    type_table_name   VARCHAR2(100);
    column_name       VARCHAR2(100);
    ref_column        VARCHAR2(100);
    CURSOR tab_columns_curs IS
    SELECT
        column_name,
        data_type,
        data_length
    FROM
        user_tab_columns
    WHERE
        table_name = upper(child_tab);
TYPE ref_cur IS REF CURSOR;
BEGIN
    IF NOT check_exist_table(parent_tab) OR NOT check_exist_table(child_tab) THEN
        raise_application_error(
                               -20000,
                               'Не существует какой-то из таблиц'
        );
    END IF;

    IF NOT check_one_to_many(
                            parent_tab,
                            child_tab
           ) THEN
        raise_application_error(
                               -20001,
                               'Нет связи one-to-many'
        );
    END IF;

    table_name := create_unique_name(
                                    parent_tab,
                                    child_tab
                  );
    select_rec_parent := 'SELECT * FROM ' || parent_tab;
    select_rec_parent := '('
                         || select_rec_parent
                         || ')';
    EXECUTE IMMEDIATE 'CREATE TABLE '                        --Таблица которая имеет поля и данные родителя
                      || table_name
                      || ' AS '
                      || select_rec_parent;
    -- Создание записи чтобы создать объект с записями из дочерней
    type_object_name := create_unique_name(
                                          child_tab,
                                          'type_object'
                        );
    FOR tab_columns IN tab_columns_curs LOOP
        IF tab_columns.data_type = 'VARCHAR2' THEN
            select_rec_child := select_rec_child
                                || tab_columns.column_name
                                || ' '
                                || tab_columns.data_type
                                || '('
                                || tab_columns.data_length
                                || '), ';

        ELSE
            select_rec_child := select_rec_child
                                || tab_columns.column_name
                                || ' '
                                || tab_columns.data_type
                                || ', ';
        END IF;
    END LOOP;

    select_rec_child := trim(TRAILING ',' FROM trim(TRAILING ' ' FROM select_rec_child));
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE '
                      || type_object_name
                      || ' is OBJECT ( '
                      || select_rec_child
                      || ' )';
    -- Создание записи чтобы создать объект с записями из дочерней
    type_table_name := create_unique_name(
                                         child_tab,
                                         'type_table'
                       );
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE '
                      || type_table_name
                      || ' is TABLE OF '
                      || type_object_name;
    -- Добавления поля коллекции в новую таблицу
    column_name := child_tab || '_column';
    EXECUTE IMMEDIATE 'ALTER TABLE '
                      || table_name
                      || ' ADD '
                      || column_name
                      || ' '
                      || type_table_name
                      || ' NESTED TABLE '
                      || column_name
                      || ' STORE AS '
                      || table_name
                      || '_'
                      || column_name;
    -- Заполнение
    EXECUTE IMMEDIATE 'SELECT
                            cols_r.column_name r_column_name
                        FROM
                            user_constraints  cons
                        LEFT JOIN user_cons_columns cols ON cols.constraint_name = cons.constraint_name
                        LEFT JOIN user_constraints  cons_r ON cons_r.constraint_name = cons.r_constraint_name
                        LEFT JOIN user_cons_columns cols_r ON cols_r.constraint_name = cons.r_constraint_name
                        WHERE
                            cons.constraint_type = ''R''
                            AND cons.table_name = upper(:child)
                            AND cons_r.table_name = upper(:parent)'
    INTO ref_column  --Поле по которому связаны таблицы
        USING child_tab, parent_tab; 
END;
/

BEGIN
    parent_child_tab(
                    'TEAMS',
                    'Buildings'
    );
END;
/

-- UPDATE teams_buildings_7688005451388888888888888888888888888889
-- SET
--     buildings = buildings_type_table_7688005451388888888888888888888888888889(
--         buildings_type_object_7688005451388888888888888888888888888889(
--             1, 'Тип2', 2, 2, TO_DATE('24.03.21', 'dd.mm.yy'), TO_DATE('17.07.2021', 'dd.mm.yy'), 1000.75, 11
--         ),
--         buildings_type_object_7688005451388888888888888888888888888889(
--             1, 'Тип2', 2, 2, TO_DATE('24.03.21', 'dd.mm.yy'), TO_DATE('17.07.2021', 'dd.mm.yy'), 1000.75, 18
--         )
--     )
-- WHERE
--     teamkey = 1;

-- SELECT
--     column_name,
--     data_type,
--     data_length
-- FROM
--     user_tab_columns
-- WHERE
--     table_name = 'BUILDINGS';

-- SELECT
--     t.teamkey,
--     t.lead,
--     t.strength,
--     cc.*
-- FROM
--     teams_buildings_7688005451388888888888888888888888888889 t,
--     TABLE ( t.buildings )                                    cc;

SELECT
    cols_r.column_name r_column_name
FROM
    user_constraints  cons
    LEFT JOIN user_cons_columns cols ON cols.constraint_name = cons.constraint_name
    LEFT JOIN user_constraints  cons_r ON cons_r.constraint_name = cons.r_constraint_name
    LEFT JOIN user_cons_columns cols_r ON cols_r.constraint_name = cons.r_constraint_name
WHERE
    cons.constraint_type = 'R'
    AND cons.table_name = ':child'
    AND cons_r.table_name = ':parent';
