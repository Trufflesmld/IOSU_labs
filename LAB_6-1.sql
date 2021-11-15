--!-----------------------------------------------------------------------------------------------------------------------------------------------------------
--* Написать с помощью пакета DBMS_SQL динамическую процедуру или функцию, в которой заранее неизвестен текст команды SELECT.
--* Предусмотреть возможность вывода разных результатов, в зависимости от количества передаваемых параметров.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE random_select (
    name_tab  IN VARCHAR2,
    col_list  IN VARCHAR2 DEFAULT NULL,
    where_str IN VARCHAR2 DEFAULT NULL
) IS

    where_str_close      VARCHAR2(500);
    query_string         VARCHAR2(500);
    columns_str          VARCHAR2(500);
    v_cursor_id          INTEGER;
    l_feedback           INTEGER;
    col_value            VARCHAR2(2000);
    l_one_row_string     VARCHAR2(2000);
    header               VARCHAR2(2000);
    counter_true_columns INTEGER DEFAULT 0;
    l_cols_tablen        BINARY_INTEGER;
    l_cols_tab           dbms_utility.uncl_array;
    l_tables_tablen      BINARY_INTEGER;
    l_tables_tab         dbms_utility.uncl_array;
    TYPE columns_tt IS
        TABLE OF all_tab_columns%rowtype INDEX BY PLS_INTEGER;
    columns_arr          columns_tt;
BEGIN
    dbms_utility.comma_to_table(
                               list   => name_tab,
                               tablen => l_tables_tablen,
                               tab    => l_tables_tab
    );

    FOR j IN 1..l_tables_tablen LOOP
        IF NOT check_exist_table(trim(l_tables_tab(j))) THEN
            raise_application_error(
                                   -20002,
                                   'Таблицы '
                                   || trim(l_tables_tab(j))
                                   || ' не существует'
            );

        END IF;
    END LOOP;

    query_string := 'FROM ' || name_tab;
    SELECT
        *
    BULK COLLECT
    INTO columns_arr
    FROM
        all_tab_columns
    WHERE
        owner = user;

    IF col_list IS NULL THEN
        columns_str := NULL;
        FOR i IN columns_arr.first..columns_arr.last LOOP
            FOR j IN 1..l_tables_tablen LOOP
                IF columns_arr(i).table_name = upper(trim(l_tables_tab(j))) THEN
                    columns_str := columns_str
                                   || columns_arr(i).column_name
                                   || ', ';
                END IF;
            END LOOP;
        END LOOP;

        columns_str := trim(TRAILING ',' FROM trim(TRAILING ' ' FROM columns_str));
        dbms_utility.comma_to_table(
                               list   => columns_str,
                               tablen => l_cols_tablen,
                               tab    => l_cols_tab
    );
    columns_str := '*';
    ELSE
        dbms_utility.comma_to_table(
                                   list   => col_list,
                                   tablen => l_cols_tablen,
                                   tab    => l_cols_tab
        );

        FOR i IN columns_arr.first..columns_arr.last LOOP
            FOR j IN 1..l_tables_tablen LOOP
                FOR k IN 1..l_cols_tablen LOOP
                    IF
                        columns_arr(i).table_name = upper(trim(l_tables_tab(j)))
                        AND columns_arr(i).column_name = upper(trim(l_cols_tab(k)))
                    THEN
                        counter_true_columns := counter_true_columns + 1;
                    END IF;
                END LOOP;
            END LOOP;
        END LOOP;

        IF NOT ( counter_true_columns = l_cols_tablen ) THEN
            raise_application_error(
                                   -20500,
                                   'Поле определено не однозначным образом или какое-то из полей не принадлежит указанным таблицам'
            );
        END IF;
        columns_str := col_list;
        dbms_utility.comma_to_table(
                               list   => columns_str,
                               tablen => l_cols_tablen,
                               tab    => l_cols_tab
    );
    END IF;

    
    query_string := 'SELECT '
                    || columns_str
                    || ' '
                    || query_string;
    where_str_close := ltrim(upper(where_str));
    IF where_str_close IS NOT NULL THEN
        IF (
            where_str_close NOT LIKE 'GROUP BY%'
            AND where_str_close NOT LIKE 'ORDER BY%'
        ) THEN
            where_str_close := 'WHERE ' || ltrim(
                                                where_str_close,
                                                'WHERE'
                                           );
        END IF;
    END IF;

    query_string := query_string
                    || ' '
                    || where_str_close;
    query_string := upper(query_string);
    dbms_output.put_line(query_string);
    v_cursor_id := dbms_sql.open_cursor;
    dbms_sql.parse(
                  v_cursor_id,
                  query_string,
                  dbms_sql.native
    );
    FOR i IN 1..l_cols_tablen LOOP
        dbms_sql.define_column(
                              v_cursor_id,
                              i,
                              'a',
                              20
        );
    END LOOP;

    FOR i IN 1..l_cols_tablen LOOP
        header := header
                  || ' | '
                  || trim(l_cols_tab(i));
    END LOOP;

    dbms_output.put_line('Uнформация таблицы ' || name_tab);
    dbms_output.put_line(header || ' |');
    l_feedback := dbms_sql.execute(v_cursor_id);
    LOOP
        l_one_row_string := '';
        l_feedback := dbms_sql.fetch_rows(v_cursor_id);
        EXIT WHEN l_feedback = 0;
        FOR i IN 1..l_cols_tablen LOOP
            dbms_sql.column_value(
                                 v_cursor_id,
                                 i,
                                 col_value
            );
            col_value := to_char(col_value);
            l_one_row_string := l_one_row_string
                                || ' | '
                                || col_value;
        END LOOP;

        dbms_output.put_line(l_one_row_string || ' |');
    END LOOP;

    dbms_sql.close_cursor(v_cursor_id);
EXCEPTION
    WHEN OTHERS THEN
        dbms_sql.close_cursor(v_cursor_id);
        RAISE;
END;
/

BEGIN
    random_select(
                 name_tab => 'teams, buildings'
    );
END;
/
