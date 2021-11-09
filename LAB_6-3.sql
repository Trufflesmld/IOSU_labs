--!-----------------------------------------------------------------------------------------------------------------------------------------------------
--* Создать процедуру, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
--* Процедура подсчитывает и выводит на экран статистику по этой таблице: 
--* количество записей, имя поля, количество различных значений поля, количество null-значений.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE stat_proc (
    tab_name IN VARCHAR2,
    col_name IN VARCHAR2
) IS

    selected_col   VARCHAR2(100);
    selected_tab   VARCHAR2(100);
    count_rec      INTEGER DEFAULT 0;
    count_rec_null INTEGER DEFAULT 0;
    count_rec_uniq INTEGER DEFAULT 0;
BEGIN
    SELECT
        column_name,
        table_name
    INTO
        selected_col,
        selected_tab
    FROM
        all_tab_columns
    WHERE
        owner = user
        AND table_name = upper(tab_name)
        AND column_name = upper(col_name);

    EXECUTE IMMEDIATE 'SELECT count(1) FROM ' || selected_tab
    INTO count_rec;
    EXECUTE IMMEDIATE 'SELECT count(1) FROM '
                      || selected_tab
                      || ' WHERE '
                      || selected_col
                      || ' IS NULL'
    INTO count_rec_null;
    EXECUTE IMMEDIATE 'SELECT count(distinct '
                      || selected_col
                      || ') FROM '
                      || selected_tab
    INTO count_rec_uniq;
    dbms_output.put_line('Uмя поля: ' || selected_col);
    dbms_output.put_line('Количество записей: ' || count_rec);
    dbms_output.put_line('Количество различных значений поля: ' || count_rec_uniq);
    dbms_output.put_line('Количество null-значений: ' || count_rec_null);
EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('Нет такой таблицы или поля');
END;
/

BEGIN
    stat_proc(
             'buildings',
             'contractprice'
    );
END;
/
