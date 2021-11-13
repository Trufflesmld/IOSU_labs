--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Uспользуя встроенный динамический SQL, процедуру создания в БД нового объекта (представления или таблицы) на основе существующей таблицы. 
-- * Uмя нового объекта должно формироваться динамически и проверяться на существование в словаре данных. 
-- * В качестве входных параметров указать тип нового объекта, исходную таблицу, столбцы и количество строк, которые будут использоваться в запросе.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE new_object_bd (
    type_of   IN VARCHAR2,
    ref_tab   IN VARCHAR2,
    col_list  IN VARCHAR2 DEFAULT NULL,
    rec_count IN INTEGER DEFAULT NULL
) IS

    new_obj_name    VARCHAR2(100);
    select_rec      VARCHAR2(200);
    columns_str     VARCHAR2(100);
    counter_records INTEGER;
    number_records  INTEGER;
BEGIN
    IF upper(type_of) NOT IN ( 'VIEW', 'TABLE' ) THEN
        raise_application_error(
                               -20001,
                               'Указанный тип не является таблицей или представлением'
        );
    END IF;

    IF NOT check_exist_table(ref_tab) THEN
        raise_application_error(
                               -20002,
                               'Таблицы не существует'
        );
    END IF;
    IF col_list IS NULL THEN
        columns_str := ' * ';
    ELSE
        IF NOT check_exist_column_in_table(
                                          ref_tab,
                                          col_list
               ) THEN
            raise_application_error(
                                   -20003,
                                   'Не существует столбца'
            );
        END IF;

        columns_str := col_list;
    END IF;

    EXECUTE IMMEDIATE 'SELECT count(1) FROM ' || ref_tab
    INTO counter_records;
    IF rec_count IS NULL THEN
        number_records := counter_records;
    ELSE
        IF counter_records < rec_count THEN
            raise_application_error(
                                   -20004,
                                   'У таблицы на данный момент существует '
                                   || counter_records
                                   || ' записей. Указано '
                                   || rec_count
                                   || ' записей'
            );
        END IF;

        number_records := rec_count;
    END IF;

    new_obj_name := create_unique_name(
                                      ref_tab,
                                      type_of
                    );
    select_rec := 'SELECT '
                  || columns_str
                  || ' FROM '
                  || ref_tab
                  || ' WHERE rownum <= '
                  || number_records;

    CASE upper(type_of)
        WHEN 'VIEW' THEN
            select_rec := select_rec;
        WHEN 'TABLE' THEN
            select_rec := '('
                          || select_rec
                          || ')';
    END CASE;

    EXECUTE IMMEDIATE 'CREATE '
                      || type_of
                      || ' '
                      || new_obj_name
                      || ' AS '
                      || select_rec;

END;
/

CREATE OR REPLACE FUNCTION check_exist_table (
    tab_name IN VARCHAR2
) RETURN BOOLEAN IS
    tab INTEGER;
BEGIN
    SELECT
        1
    INTO tab
    FROM
        user_tables
    WHERE
        table_name = upper(tab_name);

    RETURN true;
EXCEPTION
    WHEN no_data_found THEN
        RETURN false;
END;
/

CREATE OR REPLACE FUNCTION check_exist_column_in_table (
    tab_name IN VARCHAR2,
    col_list IN VARCHAR2
) RETURN BOOLEAN IS

    l_tablen BINARY_INTEGER;
    l_tab    dbms_utility.uncl_array;
    CURSOR names_existing IS
    SELECT
        column_name
    FROM
        user_tab_columns
    WHERE
        table_name = upper(tab_name);

    match    BOOLEAN;
BEGIN
    dbms_utility.comma_to_table(
                               list   => col_list,
                               tablen => l_tablen,
                               tab    => l_tab
    );

    FOR i IN 1..l_tablen LOOP
        FOR name_exist IN names_existing LOOP
            IF upper(trim(l_tab(i))) = name_exist.column_name THEN
                match := true;
                EXIT;
            ELSE
                match := false;
            END IF;
        END LOOP;

        IF NOT match THEN
            RETURN false;
        END IF;
    END LOOP;

    RETURN true;
END;
/

BEGIN
    new_object_bd(
                 type_of   => 'table',
                 ref_tab   => 'buildings'
    );
END;
/

BEGIN
    IF check_exist_column_in_table(
                                  'BUILDINGS',
                                  'BUILDKEY, TYPEOBJ, hhahha'
       ) THEN
        dbms_output.put_line('1+');
    END IF;
    IF NOT check_exist_column_in_table(
                                      'BUILDINGS',
                                      'kek'
           ) THEN
        dbms_output.put_line('2+');
    END IF;

END;
/

dbms_output.put_line('Нет такой таблицы или поля');
