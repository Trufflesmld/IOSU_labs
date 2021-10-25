--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * DML-триггер, регистрирующий изменение данных (вставку, обновление, удаление) Таблица TEAMS
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE log_dml (
    oper_name   CHAR(1),
    pk_key      NUMBER,
    column_name VARCHAR2(20),
    old_value   VARCHAR2(60),
    new_value   VARCHAR2(60),
    username    VARCHAR2(50),
    dateoper    DATE
);

CREATE OR REPLACE PROCEDURE logging_dml (
    voper_name   IN CHAR,
    vpk_key      IN NUMBER,
    vcolumn_name IN VARCHAR2,
    vold_value   IN VARCHAR2,
    vnew_value   IN VARCHAR2
) IS
    PRAGMA autonomous_transaction;
    date_and_time DATE;
BEGIN
    IF vold_value <> vnew_value OR voper_name IN ( 'I', 'D' ) THEN
        SELECT
            to_char(sysdate)
        INTO date_and_time
        FROM
            dual;

        INSERT INTO log_dml (
            oper_name,
            pk_key,
            column_name,
            old_value,
            new_value,
            username,
            dateoper
        ) VALUES (
            voper_name,
            vpk_key,
            vcolumn_name,
            vold_value,
            vnew_value,
            user,
            date_and_time
        );

        COMMIT;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER teams_log AFTER
    INSERT OR UPDATE OR DELETE ON teams
    FOR EACH ROW
DECLARE
    op CHAR(1) := 'I';
BEGIN
    CASE
        WHEN inserting THEN
            op := 'I';
            logging_dml(
                       op,
                       :new.teamkey,
                       'lead',
                       NULL,
                       :new.lead
            );

            logging_dml(
                       op,
                       :new.teamkey,
                       'strength',
                       NULL,
                       :new.strength
            );

        WHEN updating('lead') OR updating('strength') THEN
            op := 'U';
            logging_dml(
                       op,
                       :new.teamkey,
                       'lead',
                       NULL,
                       NULL
            );
            logging_dml(
                       op,
                       :new.teamkey,
                       'strength',
                       :old.strength,
                       :new.strength
            );

        WHEN deleting THEN
            op := 'D';
            logging_dml(
                       op,
                       :old.teamkey,
                       'lead',
                       :old.lead,
                       NULL
            );

            logging_dml(
                       op,
                       :old.teamkey,
                       'strength',
                       :old.strength,
                       NULL
            );

        ELSE
            NULL;
    END CASE;
END teams_log;
/

BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO teams VALUES (teams_seq.NEXTVAL, ''Олешко Владислав Юрьевич'', 10)';
    EXECUTE IMMEDIATE 'DELETE FROM teams WHERE teamkey > 50';
    EXECUTE IMMEDIATE 'UPDATE teams SET strength = 6 WHERE teamkey = 21';
    EXECUTE IMMEDIATE 'UPDATE teams SET strength = 9 WHERE teamkey = 21';
END;
/

--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * DDL-триггер, протоколирующий действия пользователей 
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE log_ddl (
    oper_name VARCHAR2(20),
    obj_name  VARCHAR2(20),
    obj_type  VARCHAR2(20),
    username  VARCHAR2(20),
    dateoper  DATE
);

CREATE OR REPLACE PROCEDURE logging_ddl (
    voper_name IN VARCHAR2,
    vobj_name  IN VARCHAR2,
    vobj_type  IN VARCHAR2
) IS
    PRAGMA autonomous_transaction;
BEGIN
    IF voper_name IN ( 'CREATE', 'ALTER', 'DROP' ) THEN
        INSERT INTO log_ddl (
            oper_name,
            obj_name,
            obj_type,
            username,
            dateoper
        ) VALUES (
            voper_name,
            vobj_name,
            vobj_type,
            user,
            sysdate
        );

        COMMIT;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER user_operations_log BEFORE CREATE OR ALTER OR DROP ON SCHEMA BEGIN
    IF to_number(
        to_char(
            sysdate, 'HH24'
        )
    ) BETWEEN 8 AND 20 THEN
        CASE ora_sysevent
            WHEN 'CREATE' THEN
                logging_ddl(
                           ora_sysevent,
                           ora_dict_obj_name,
                           ora_dict_obj_type
                );
            WHEN 'ALTER' THEN
                logging_ddl(
                           ora_sysevent,
                           ora_dict_obj_name,
                           ora_dict_obj_type
                );
            WHEN 'DROP' THEN
                logging_ddl(
                           ora_sysevent,
                           ora_dict_obj_name,
                           ora_dict_obj_type
                );
            ELSE
                NULL;
        END CASE;

    ELSE
        raise_application_error(
                               -20000,
                               'Вы попали во временной промежуток, когда запрещено выполнять DDL операции.'
        );
    END IF;
END user_operations_log;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE test_tb (numm INTEGER)';
    EXECUTE IMMEDIATE 'ALTER TABLE test_tb MODIFY numm CHAR(1)';
    EXECUTE IMMEDIATE 'DROP TABLE test_tb';
END;
/

SELECT
    *
FROM
    log_ddl;
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Системный триггер, добавляющий запись во вспомогательную таблицу LOG3, когда пользователь подключается или отключается.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------


CREATE TABLE log_connection (
    user_name         VARCHAR2(30),
    status_connection VARCHAR2(10),
    date_log          DATE,
    row_count         INTEGER
);

CREATE OR REPLACE TRIGGER trig_logon AFTER LOGON ON SCHEMA DECLARE
    row_count NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO row_count
    FROM
        buildings;

    INSERT INTO log_connection VALUES (
        ora_login_user,
        ora_sysevent,
        sysdate,
        row_count
    );

    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD.MM.YY HH24:MI:SS''';
    EXECUTE IMMEDIATE 'set linesize 500';

END;
/

CREATE OR REPLACE TRIGGER trig_logoff BEFORE LOGOFF ON SCHEMA DECLARE
    row_count NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO row_count
    FROM
        buildings;

    INSERT INTO log_connection VALUES (
        ora_login_user,
        ora_sysevent,
        sysdate,
        row_count
    );

END;
/


--!-----------------------------------------------------------------------------------------------------------------------------------------------------
-- * Триггер INSTEAD OF для работы с необновляемым представлением.
--!-----------------------------------------------------------------------------------------------------------------------------------------------------
--* update
CREATE OR REPLACE TRIGGER buildings_view_update_trig INSTEAD OF
    UPDATE ON buildings_view
    FOR EACH ROW
DECLARE
    teamkey_new        teams.teamkey%TYPE;
    clientkey_new      clients.clientkey%TYPE;
    check_excep_lead   teams.lead%TYPE;
    check_excep_client teams.lead%TYPE;
BEGIN
    IF :new.lead != :old.lead THEN
        SELECT
            lead
        INTO check_excep_lead
        FROM
            teams
        WHERE
            lead = :new.lead;

        SELECT
            teamkey
        INTO teamkey_new
        FROM
            teams
        WHERE
            lead = :new.lead;

    ELSE
        SELECT
            teamkey
        INTO teamkey_new
        FROM
            teams
        WHERE
            lead = :old.lead;

    END IF;

    IF :new.client_name != :old.client_name THEN
        SELECT
            fname
            || ' '
            || lname
        INTO check_excep_client
        FROM
            clients
        WHERE
            fname
            || ' '
            || lname = :new.client_name;

        SELECT
            clientkey
        INTO clientkey_new
        FROM
            clients
        WHERE
            fname
            || ' '
            || lname = :new.client_name;

    ELSE
        SELECT
            clientkey
        INTO clientkey_new
        FROM
            clients
        WHERE
            fname
            || ' '
            || lname = :old.lead;

    END IF;

    UPDATE buildings
    SET
        typeobj = :new.typeobj,
        clientkey = clientkey_new,
        teamkey = teamkey_new,
        contraktdate = :new.contraktdate,
        enddate = :new.enddate,
        contractprice = :new.contractprice
    WHERE
        buildkey = :old.buildkey;

EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('-------------------------------------------');
        dbms_output.put_line('| Таких данных нет в родительской таблице |');
        dbms_output.put_line('-------------------------------------------');
END;
/

UPDATE buildings_view
SET
    typeobj = '11'
WHERE
    buildkey = 6;

--* insert

CREATE OR REPLACE TRIGGER buildings_view_insert_trig INSTEAD OF
    INSERT ON buildings_view
DECLARE
    teamkey_new        teams.teamkey%TYPE;
    clientkey_new      clients.clientkey%TYPE;
    check_excep_lead   teams.lead%TYPE;
    check_excep_client teams.lead%TYPE;
BEGIN
        SELECT
            lead
        INTO check_excep_lead
        FROM
            teams
        WHERE
            lead = :new.lead;

        SELECT
            teamkey
        INTO teamkey_new
        FROM
            teams
        WHERE
            lead = :new.lead;

        SELECT
            fname
            || ' '
            || lname
        INTO check_excep_client
        FROM
            clients
        WHERE
            fname
            || ' '
            || lname = :new.client_name;

        SELECT
            clientkey
        INTO clientkey_new
        FROM
            clients
        WHERE
            fname
            || ' '
            || lname = :new.client_name;


    INSERT INTO buildings (
        typeobj,
        clientkey,
        teamkey,
        contraktdate,
        enddate,
        contractprice
    ) VALUES (
        :new.typeobj,
        clientkey_new,
        teamkey_new,
        :new.contraktdate,
        :new.enddate,
        :new.contractprice
    );

EXCEPTION
    WHEN no_data_found THEN
        dbms_output.put_line('-------------------------------------------');
        dbms_output.put_line('| Таких данных нет в родительской таблице |');
        dbms_output.put_line('-------------------------------------------');
END;
/

INSERT INTO buildings_view (
    typeobj,
    lead,
    client_name,
    contraktdate,
    enddate,
    contractprice
) VALUES (
    'Тип1',
    'Станиславский Богдан Валерьевич',
    'Былинский Трофим',
    TO_DATE('14.08.21', 'dd.mm.yy'),
    TO_DATE('15.08.21', 'dd.mm.yy'),
    999999999
);
