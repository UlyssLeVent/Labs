CREATE DATABASE PublishDB

CREATE TABLE Territories (
    code varchar(17),
    name varchar(80),
);

INSERT INTO Communities VALUES ('UA74000000000025378', 'Чернігівська область');
INSERT INTO Communities VALUES ('UA46140000000036328', 'Яворівський район Львівської області');
INSERT INTO Communities VALUES ('UA71020270000021083', 'Стеблівська територіальна громада');
INSERT INTO Communities VALUES ('UA32120070080094229', 'село Нові Безрадичі');
INSERT INTO Communities VALUES ('UA80000000000210193', 'Дарницький район міста Києва');


SELECT
    *
FROM
    PublichDB.Territories
;




