CREATE TABLE bran(bno INTEGER NOT NULL,
                    street VARCHAR2(30) NOT NULL,
                    city VARCHAR2(15) NOT NULL,
                    tel_no VARCHAR2(17),
                    PRIMARY KEY(bno),
                    CONSTRAINT ch_telno_branch
                                CHECK(REGEXP_LIKE(tel_no, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
                    CONSTRAINT uni_telno_branch UNIQUE(tel_no));

CREATE TABLE staff(sno INTEGER NOT NULL,
                    fname VARCHAR2(20) NOT NULL,
                    lname VARCHAR2(20) NOT NULL,
                    address VARCHAR2(60) NOT NULL,
                    tel_no VARCHAR2(17) NOT NULL,
                    position VARCHAR2(40) NOT NULL,
                    sex VARCHAR2(6),
                    dob DATE,
                    salary NUMBER(5,2),
                    bno INTEGER,
                    PRIMARY KEY(sno),
                    CONSTRAINT ch_telno_staff
                               CHECK(REGEXP_LIKE(tel_no, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
                    CONSTRAINT uni_telno_staff 
                               UNIQUE(tel_no),
                    CONSTRAINT ch_sex
                               CHECK(sex IN('male','female')),
                    CONSTRAINT bno_fk_staff
                               FOREIGN KEY(bno)
                               REFERENCES branch
                     );

CREATE TABLE property_for_rent(pno INTEGER NOT NULL,
                    street VARCHAR2(30) NOT NULL,
                    city VARCHAR2(15) NOT NULL,
                    type_obj CHAR(1) NOT NULL,
                    rooms INTEGER,
                    rent NUMBER(5,2),
                    ono INTEGER,
                    sno INTEGER,
                    bno INTEGER,
                    PRIMARY KEY(pno),
                    CONSTRAINT ch_obj_type
                               CHECK(type_obj IN('h','f')),
                    CONSTRAINT sno_fk_pfrent
                               FOREIGN KEY(sno)
                               REFERENCES staff,           
                    CONSTRAINT bno_fk_pfrent
                               FOREIGN KEY(bno)
                               REFERENCES branch
                     );

CREATE SYNONYM objects for property_for_rent;

CREATE TABLE renter(rno INTEGER NOT NULL,
                    fname VARCHAR2(20) NOT NULL,
                    lname VARCHAR2(20),
                    address VARCHAR2(60),
                    tel_no VARCHAR2(17),
                    pref_type CHAR(1),
                    max_rent NUMBER(5,2),
                    bno INTEGER,
                    PRIMARY KEY(rno),
                    CONSTRAINT ch_pref_type
                               CHECK(pref_type IN('h','f')),
                    CONSTRAINT ch_telno_renter
                                CHECK(REGEXP_LIKE(tel_no, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
                    CONSTRAINT uni_telno_renter
                               UNIQUE(tel_no),                                    
                    CONSTRAINT bno_fk_renter
                               FOREIGN KEY(bno)
                               REFERENCES branch
                     );

CREATE TABLE owner(ono INTEGER NOT NULL,
                    fname VARCHAR2(20),
                    lname VARCHAR2(20),
                    address VARCHAR2(60),
                    tel_no VARCHAR2(17),
                    PRIMARY KEY(ono),
                    CONSTRAINT ch_telno_owner
                                CHECK(REGEXP_LIKE(tel_no, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
                    CONSTRAINT uni_telno_owner
                               UNIQUE(tel_no)                                   
                     ); 

ALTER TABLE property_for_rent
ADD CONSTRAINT ono_fk1
               FOREIGN KEY(ono)
               REFERENCES owner;

CREATE TABLE viewing(rno INTEGER NOT NULL,
                     pno INTEGER NOT NULL,
                    date1 DATE NOT NULL,
                    comment1 VARCHAR2(300),
                    PRIMARY KEY(rno,pno)
);      

������������������:
CREATE SEQUENCE bran_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE staff_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE property_for_rent_seq
START WITH 1
INCREMENT BY 1;

CREATE SEQUENCE renter_seq
START WITH 1
INCREMENT BY 1;

CREATE OR REPLACE TRIGGER seq_branch
	BEFORE INSERT ON branch
	FOR EACH ROW
	BEGIN	
	SELECT branch_seq.nextval 
		INTO :NEW.bno 
	FROM DUAL;
END seq_branch ;

begin
insert into branch(street, city, tel_no) values('42','1','+375(29)221-11-71');
insert into branch(street, city, tel_no) values('13','2','+375(33)222-11-71');
insert into branch(street, city, tel_no) values('17','3','+375(25)223-11-71');
insert into branch (street, city, tel_no)values('11','4','+375(29)224-11-71');
insert into branch (street, city, tel_no)values('764','5','+375(29)225-11-71');
insert into branch (street, city, tel_no)values('123','6','+375(29)226-11-71');
insert into branch(street, city, tel_no) values('64','7','+375(29)227-11-71');
insert into branch (street, city, tel_no)values('88','8','+375(29)228-11-71');
insert into branch (street, city, tel_no)values('44','9','+375(33)229-11-71');
insert into branch (street, city, tel_no)values('58','10','+375(29)230-11-71');
insert into branch (street, city, tel_no)values(' 102','11','+375(29)255-11-71');
end;
/

insert into staff values(staff_seq.nextval,'������','������','�����, �������� 19','+375(25)225-11-71','director',
'male', to_date('17.03.86', 'dd.mm.yy'),300,1);
insert into staff values(staff_seq.nextval,'�������','����','�����, �������� 19','+375(29)225-11-71','manager',
'female', to_date('22.09.87', 'dd.mm.yy'),250,2);
insert into staff values(staff_seq.nextval,'������','�������','������, ��������������� 14','+375(33)225-11-71','seller',
'male', to_date('25.04.90', 'dd.mm.yy'),800,2);
insert into staff values(staff_seq.nextval,'������','���������','������, ���������� 33','+375(29)221-11-71','manager',
'female', to_date('30.12.91', 'dd.mm.yy'),200,3);
insert into staff values(staff_seq.nextval,'���������','�����','�������, ��������� 12','+375(29)225-12-71','manager',
'female', to_date('30.08.78', 'dd.mm.yy'),280,5);
insert into staff values(staff_seq.nextval,'������','������','�����, ������ 13','+375(29)225-31-71','manager',
'male', to_date('04.05.96', 'dd.mm.yy'),190,6);
insert into staff values(staff_seq.nextval,'�����','������','������, ������������� 33','+375(29)225-41-71','seller',
'male', to_date('12.08.88', 'dd.mm.yy'),700,6);
insert into staff values(staff_seq.nextval,'���������','������','�����, ���������� 19','+375(29)225-51-71','seller',
'male', to_date('25.06.80', 'dd.mm.yy'),900,7);
insert into staff values(staff_seq.nextval,'�����','���','�������, ������������ 73','+375(29)225-22-71','seeller',
'male', to_date('17.03.86', 'dd.mm.yy'),300,8);


insert into owner(ono,fname,lname,address,tel_no) select staff_seq.nextval,fname,lname,address,tel_no from staff;

begin
insert into objects values (property_for_rent_seq.nextval,'����� ������ 43','�����','h',2,600,12,3,1);
insert into objects values (property_for_rent_seq.nextval,'������������ 13','�����','f',3,500,13,5,1);
insert into objects values (property_for_rent_seq.nextval,'�������� 77','�����','f',4,100,14,3,3);
insert into objects values (property_for_rent_seq.nextval,'���� ������ 105','������','h',4,400, 14,6,6);

insert into renter values(renter_seq.nextval,'������','����','�����, ������ 5','+375(29)225-11-71','h',500,1);
insert into renter values(renter_seq.nextval,'������','����','�����, ����������� 76','+375(29)225-11-72','f',400,1);
insert into renter values(renter_seq.nextval,'�����','���������','������, ������������ 666','+375(29)225-11-73','h',900,3);
insert into renter values(renter_seq.nextval,'��������','������','�������, �������� 9','+375(29)225-11-74','f',700,3);
insert into renter values(renter_seq.nextval,'�������','�����','������, ��������� 73','+375(29)225-11-75','h',500,6);
end;
/
begin
insert into viewing values(1, 6,to_date('03.12.19', 'dd.mm.yy'),'ok');
insert into viewing values(1, 5,to_date('03.10.20', 'dd.mm.yy'),'good');
insert into viewing values(2, 3,to_date('15.08.20', 'dd.mm.yy'),'');
insert into viewing values(4, 3,to_date('16.08.19', 'dd.mm.yy'),'bad');
insert into viewing values(5, 4,to_date('04.12.20', 'dd.mm.yy'),'');
end;
/


INSERT ALL
 insert into objectsTypes values('Type1', 20, 15, 5)
 into objectsTypes values('Type2', 25, 16, 5)
 into objectsTypes values('Type3', 20, 15, 5)
 into objectsTypes values('Type4', 20, 15, 5)
 into objectsTypes values('Type5', 20, 15, 5)
 into objectsTypes values('Type6', 20, 15, 5)
 into objectsTypes values('Type7', 20, 15, 5)
 into objectsTypes values('Type8', 20, 15, 5)
 into objectsTypes values('Type9', 20, 15, 5)
 into objectsTypes values('Type10',20, 15, 5) 
 into objectsTypes values('Type11',20, 15, 5) 
SELECT * FROM dual;

alter table objectsTypes add constraint countLimit check ((livingSpace + cellarSpace) = floorCount);

alter table buildings add constraint dateValid check (contraktDate < endDate);