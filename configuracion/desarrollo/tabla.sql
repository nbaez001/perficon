CREATE TABLE EMPRESA (
  ID BIGINT(20) UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  RUC VARCHAR(11) NOT NULL,
  LICENCIA DATE NOT NULL,
  FLG_ACTIVO INT(1) UNSIGNED NOT NULL,
  ID_USUARIO_CREA INT(10) UNSIGNED NOT NULL,
  FEC_USUARIO_CREA DATE NOT NULL,
  ID_USUARIO_MOD INT(10) UNSIGNED DEFAULT NULL,
  FEC_USUARIO_MOD DATE DEFAULT NULL
);

INSERT INTO EMPRESA (RUC,LICENCIA, FLG_ACTIVO,ID_USUARIO_CREA, FEC_USUARIO_CREA) VALUES('20602899161','2023-06-30',1,1,now());
COMMIT;