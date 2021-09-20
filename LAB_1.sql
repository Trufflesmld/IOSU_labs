CREATE TABLE teams(
    teamKey INTEGER PRIMARY KEY,
    lead VARCHAR2(50) NOT NULL,
    strength INTEGER NOT NULL
);

CREATE SEQUENCE teams_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE objectsTypes(
    typeObj VARCHAR2(15) PRIMARY KEY,
    floorCount INTEGER NOT NULL CHECK (floorCount > 0),
    livingSpace INTEGER NOT NULL CHECK (livingSpace > 0),
    cellarSpace INTEGER CHECK (cellarSpace > 0)
);

CREATE TABLE clients(
    clientKey INTEGER PRIMARY KEY,
    fName VARCHAR2(20) NOT NULL,
    lName VARCHAR2(20) NOT NULL,
    tel VARCHAR2(17) NOT NULL,
    CONSTRAINT telRegExp CHECK(
        REGEXP_LIKE(tel, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')
    ),
    CONSTRAINT telUni UNIQUE(tel)
);

CREATE SEQUENCE clients_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE stages(
    stageKey NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stageName VARCHAR2(25)
);

CREATE TABLE stuf(
    stufKey NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stufName VARCHAR2(25),
    balance INTEGER CHECK (balance < 1000)
);

CREATE TABLE buildings(
    buildKey NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    typeObj VARCHAR2(15) NOT NULL,
    clientKey INTEGER NOT NULL,
    teamKey INTEGER NOT NULL,
    contraktDate DATE NOT NULL,
    endDate DATE NOT NULL,
    CONSTRAINT objTypeInBuildings FOREIGN KEY(typeObj) REFERENCES objectsTypes,
    CONSTRAINT clientKeyInBuildings FOREIGN KEY(clientKey) REFERENCES clients,
    CONSTRAINT teamKeyInBuildings FOREIGN KEY(teamKey) REFERENCES teams
);

CREATE TABLE build_stage(
    buildKey INTEGER,
    stageKey INTEGER,
    PRIMARY KEY (buildKey, stageKey),
    CONSTRAINT buildInBuild_stage FOREIGN KEY(buildKey) REFERENCES buildings,
    CONSTRAINT stageInBuild_stage FOREIGN KEY(stageKey) REFERENCES stages
);

CREATE TABLE stage_stuff(
    buildKey INTEGER,
    stufKey INTEGER,
    stageKey INTEGER,
    CONSTRAINT buildInStage_stuff FOREIGN KEY(buildKey) REFERENCES buildings,
    CONSTRAINT stufInStage_stuff FOREIGN KEY(stufKey) REFERENCES stuf,
    CONSTRAINT stageInStage_stuff FOREIGN KEY(stageKey) REFERENCES stages
);

ALTER TABLE
    stage_stuff
ADD
    CONSTRAINT PK_buildKey_stageKey_stufKey PRIMARY KEY (buildKey, stageKey, stufKey);

CREATE SYNONYM B_S FOR build_stage;

CREATE SYNONYM S_S FOR stage_stuff;

------------------------------------------------------------------------------------- 
ALTER TABLE
    objectsTypes
ADD
    CONSTRAINT countLimit CHECK （ （ livingSpace + cellarSpace ） = floorCount ）;

ALTER TABLE
    buildings
ADD
    contractPrice NUMBER （ 38,
    2 ）;

ALTER TABLE
    buildings
ADD
    CONSTRAINT dateValid CHECK （ contraktDate < endDate ）;

ALTER TABLE
    teams
MODIFY
    lead VARCHAR2 （ 100 ）;

ALTER TABLE
    objectsTypes DROP CONSTRAINT SYS_C008578;

ALTER TABLE
    objectsTypes
ADD
    CONSTRAINT cellarSpaceLimit CHECK (cellarSpace >= 0);

ALTER TABLE
    stages
MODIFY
    stageName varchar2(100);

ALTER TABLE
    stuf
MODIFY
    stufname varchar2(50);

-------------------------------------------------------------------------------------- 
/*Индексы*/
CREATE INDEX key_of_team_in_buildings ON buildings(teamkey);
CREATE INDEX key_of_typeObj_in_buildings ON buildings(typeObj);


-------------------------------------------------------------------------------------------
/*insert TEAMS*/
BEGIN
INSERT INTO
    teams
VALUES
    (teams_seq.nextval, 'Фоменко Иван Сергеевич', 7);

INSERT INTO
    teams
VALUES
    (
        teams_seq.nextval,
        'Елов Александр Евгеньевич',
        8
    );

INSERT INTO
    teams
VALUES
    (
        teams_seq.nextval,
        'Соломонов Игнат Константинович',
        7
    );

INSERT INTO
    teams
VALUES
    (
        teams_seq.nextval,
        'Станиславский Богдан Валерьевич',
        9
    );

INSERT INTO
    teams
VALUES
    (
        teams_seq.nextval,
        'Остапенко Игорь Николаевич',
        11
    );

END;

/
/*insert objectsTypes*/
INSERT
    ALL INTO objectsTypes
VALUES
    ('Тип1', 56, 50, 6) INTO objectsTypes
VALUES
    ('Тип2', 132, 120, 12) INTO objectsTypes
VALUES
    ('Тип3', 190, 190, 0) INTO objectsTypes
VALUES
    ('Тип4', 100, 75, 25) INTO objectsTypes
VALUES
    ('Тип5', 150, 125, 25)
SELECT
    *
FROM
    dual;

/*insert clients*/
BEGIN
INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Молодой',
        'Игнат',
        '+375(29)225-11-71'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Асафьев',
        'Станислав',
        '+375(29)225-11-72'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Плёсов',
        'Валентин',
        '+375(29)225-11-73'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Ящеров',
        'Константин',
        '+375(29)225-11-74'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Нечаев',
        'Артём',
        '+375(29)225-11-75'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Былинский',
        'Трофим',
        '+375(29)225-22-71'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Ефимчик',
        'Ян',
        '+375(29)225-51-71'
    );

INSERT INTO
    clients
VALUES
    (
        clients_seq.nextval,
        'Зайцев',
        'Дмитрий',
        '+375(29)225-41-71'
    );

END;

/
/*insert stages*/
BEGIN
INSERT INTO
    stages(stageName)
VALUES
    ('Устройство фундамента');

INSERT INTO
    stages(stageName)
VALUES
    ('Возведение стен, перегородок, перекрытий');

INSERT INTO
    stages(stageName)
VALUES
    ('Кровельные работы');

INSERT INTO
    stages(stageName)
VALUES
    ('Установка окон и дверей');

INSERT INTO
    stages(stageName)
VALUES
    ('Утепление и отделка фасада');

INSERT INTO
    stages(stageName)
VALUES
    (
        'Устройство электрики, сантехники, вентиляции, отопления'
    );

INSERT INTO
    stages(stageName)
VALUES
    ('Внутренние отделочные работы');

END;

/
/*insert stuf*/
BEGIN
INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Винты (упаковка 1000шт)', 200);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Гвозди (упаковка 1000шт)', 488);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Арматура (упаковка 100шт)', 400);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Бетон куб.м', 323);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Пеноблок', 500);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Клей для пеноблоков', 415);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Перемычки', 423);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Пиломатериал', 388);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Кровельный материал', 411);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Утеплитель', 263);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Гидроизоляция', 354);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Монтажная пена', 111);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Анкера (упаковка 1000шт)', 123);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Окна', 500);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Двери', 500);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Отливы', 489);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Утеплитель', 455);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Штукатурный состав', 288);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Сетка армирующая м2', 277);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Клей л', 150);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Декоративная штукатурка', 222);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Провода', 333);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Выключатели', 500);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Светильники', 500);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Распределительные щитки', 263);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Шпаклевка 25кг', 279);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Штукатурка 25кг', 165);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Обои (упаковка 100м2)', 410);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Краска 5л', 399);

INSERT INTO
    stuf(stufName, balance)
VALUES
    ('Доски для каркаса', 299);

END;

/
/*insert buildings*/
BEGIN
INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип1',
        1,
        1,
        to_date('23.01.21', 'dd.mm.yy'),
        to_date('15.05.21', 'dd.mm.yy'),
        100.75
    );

INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип2',
        2,
        2,
        to_date('24.03.21', 'dd.mm.yy'),
        to_date('17.07.2021', 'dd.mm.yy'),
        1000.75
    );

INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип3',
        3,
        3,
        to_date('22.02.21', 'dd.mm.yy'),
        to_date('26.06.2021', 'dd.mm.yy'),
        500.75
    );

INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип5',
        4,
        4,
        to_date('02.04.21', 'dd.mm.yy'),
        to_date('11.07.21', 'dd.mm.yy'),
        600
    );

INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип2',
        5,
        5,
        to_date('11.03.2021', 'dd.mm.yy'),
        to_date('22.08.21', 'dd.mm.yy'),
        777
    );

INSERT INTO
    buildings(
        typeObj,
        clientKey,
        teamKey,
        contraktDate,
        endDate,
        contractPrice
    )
VALUES
    (
        'Тип3',
        6,
        5,
        to_date('05.05.21', 'dd.mm.yy'),
        to_date('30.08.21', 'dd.mm.yy'),
        888
    );

END;

/
/*insert build_stage*/
BEGIN
INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (5, 41);

INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (6, 42);

INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (7, 43);

INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (8, 44);

INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (9, 45);

INSERT INTO
    B_S(buildKey, stageKey)
VALUES
    (10, 46);

END;

/
/*insert S_S*/
BEGIN
INSERT INTO
    S_S
VALUES
    (5, 1, 41, 100);

INSERT INTO
    S_S
VALUES
    (5, 2, 41, 120);

INSERT INTO
    S_S
VALUES
    (5, 3, 41, 30);

INSERT INTO
    S_S
VALUES
    (5, 4, 41, 80);

INSERT INTO
    S_S
VALUES
    (5, 5, 41, 15);

INSERT INTO
    S_S
VALUES
    (6, 6, 42, 7);

INSERT INTO
    S_S
VALUES
    (6, 7, 42, 115);

INSERT INTO
    S_S
VALUES
    (6, 8, 42, 13);

INSERT INTO
    S_S
VALUES
    (6, 9, 42, 93);

INSERT INTO
    S_S
VALUES
    (6, 10, 42, 11);

INSERT INTO
    S_S
VALUES
    (7, 11, 43, 19);

INSERT INTO
    S_S
VALUES
    (7, 12, 43, 23);

INSERT INTO
    S_S
VALUES
    (7, 13, 43, 48);

INSERT INTO
    S_S
VALUES
    (7, 14, 43, 99);

INSERT INTO
    S_S
VALUES
    (7, 15, 43, 86);

INSERT INTO
    S_S
VALUES
    (8, 16, 44, 43);

INSERT INTO
    S_S
VALUES
    (8, 17, 44, 11);

INSERT INTO
    S_S
VALUES
    (8, 18, 44, 85);

INSERT INTO
    S_S
VALUES
    (8, 19, 44, 201);

INSERT INTO
    S_S
VALUES
    (8, 20, 44, 123);

INSERT INTO
    S_S
VALUES
    (9, 21, 45, 128);

INSERT INTO
    S_S
VALUES
    (9, 22, 45, 145);

INSERT INTO
    S_S
VALUES
    (9, 23, 45, 189);

INSERT INTO
    S_S
VALUES
    (9, 24, 45, 119);

INSERT INTO
    S_S
VALUES
    (9, 25, 45, 155);

INSERT INTO
    S_S
VALUES
    (10, 26, 46, 211);

INSERT INTO
    S_S
VALUES
    (10, 27, 46, 488);

INSERT INTO
    S_S
VALUES
    (10, 28, 46, 135);

INSERT INTO
    S_S
VALUES
    (10, 29, 46, 249);

INSERT INTO
    S_S
VALUES
    (10, 30, 46, 26);

END;

/