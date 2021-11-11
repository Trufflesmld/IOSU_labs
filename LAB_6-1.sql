--!-----------------------------------------------------------------------------------------------------------------------------------------------------------
--* Написать с помощью пакета DBMS_SQL динамическую процедуру или функцию, в которой заранее неизвестен текст команды SELECT.
--* Предусмотреть возможность вывода разных результатов, в зависимости от количества передаваемых параметров.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE random_select (
    name_tab  IN VARCHAR2,
    col_list  IN VARCHAR2 DEFAULT NULL,
    where_str IN VARCHAR2 DEFAULT NULL
) IS

    where_str_close  VARCHAR2(500);
    query_string     VARCHAR2(500);
    columns_str      VARCHAR2(100);
    v_cursor_id      INTEGER;
    l_feedback       INTEGER;
    col_value        VARCHAR2(2000);
    l_number_value   NUMBER;
    l_date_value     DATE;
    l_one_row_string VARCHAR2(2000);
    header           VARCHAR2(2000);
    l_tablen         BINARY_INTEGER;
    l_tab            dbms_utility.uncl_array;
    TYPE columns_tt IS
        TABLE OF all_tab_columns.column_name%TYPE INDEX BY PLS_INTEGER;
    columns_arr      columns_tt;
BEGIN
    IF NOT check_exist_table(name_tab) THEN
        raise_application_error(
                               -20002,
                               'Таблицы не существует'
        );
    END IF;
    query_string := 'FROM ' || name_tab;
    IF col_list IS NULL THEN
        SELECT
            column_name
        BULK COLLECT
        INTO columns_arr
        FROM
            all_tab_columns
        WHERE
            owner = user
            AND table_name = upper(name_tab);

        columns_str := NULL;
        FOR i IN columns_arr.first..columns_arr.last LOOP
            columns_str := columns_str
                           || columns_arr(i)
                           || ', ';
        END LOOP;

        columns_str := trim(TRAILING ',' FROM trim(TRAILING ' ' FROM columns_str));
    ELSE
        IF NOT check_exist_column_in_table(
                                          name_tab,
                                          col_list
               ) THEN
            raise_application_error(
                                   -20003,
                                   'Не существует столбца'
            );
        END IF;

        columns_str := col_list;
    END IF;

    dbms_utility.comma_to_table(
                               list   => columns_str,
                               tablen => l_tablen,
                               tab    => l_tab
    );

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
    v_cursor_id := dbms_sql.open_cursor;
    dbms_sql.parse(
                  v_cursor_id,
                  query_string,
                  dbms_sql.native
    );
    FOR i IN 1..l_tablen LOOP
        dbms_sql.define_column(
                              v_cursor_id,
                              i,
                              'a',
                              20
        );
    END LOOP;

    FOR i IN 1..l_tablen LOOP
        header := header
                  || ' | '
                  || trim(l_tab(i));
    END LOOP;

    dbms_output.put_line('Uнформация таблицы ' || name_tab);
    dbms_output.put_line(header || ' |');
    l_feedback := dbms_sql.execute(v_cursor_id);
    LOOP
        l_one_row_string := '';
        l_feedback := dbms_sql.fetch_rows(v_cursor_id);
        EXIT WHEN l_feedback = 0;
        FOR i IN 1..l_tablen LOOP
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
                 name_tab  => 'buildings',
                 where_str => 'order by buildkey'
    );
END;
/
