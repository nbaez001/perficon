DELIMITER $$
CREATE PROCEDURE PFC_C_SALDO_MENSUAL (IN dia INT, IN mes INT, IN anio INT, IN fecha DATE, IN id_usuario_crea INT, IN fec_usuario_crea DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE vmonto DECIMAL(8,2) DEFAULT 0.00;
DECLARE vmonto_egreso DECIMAL(8,2) DEFAULT 0.00;
DECLARE vmonto_ingreso DECIMAL(8,2) DEFAULT 0.00;
DECLARE vfecha DATE;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SELECT sm.monto,sm.fecha INTO vmonto,vfecha FROM saldo_mensual sm WHERE sm.fecha = (SELECT MAX(sm2.fecha) FROM saldo_mensual sm2);
	SELECT SUM(e.total) INTO vmonto_egreso FROM egreso e WHERE e.fecha >= vfecha AND e.fecha < fecha;
	SELECT SUM(i.monto) INTO vmonto_ingreso FROM ingreso i WHERE i.fecha >= vfecha AND i.fecha <fecha;
	SET vmonto = vmonto + vmonto_ingreso - vmonto_egreso;
	INSERT INTO saldo_mensual(dia,mes,anio,monto,fecha,id_usuario_crea,fec_usuario_crea) VALUES (dia,mes,anio,vmonto,fecha,id_usuario_crea,fec_usuario_crea);
	COMMIT;
	SET rmensaje = 'Saldo mensual insertado';
	SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_D_MOVIMIENTO_BANCO (IN idt BIGINT, IN id_cuenta_banco BIGINT, IN id_tipo_movimiento INT, IN monto DECIMAL(8,2))  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE vmonto DECIMAL(8,2) DEFAULT 0.00;
DECLARE val_tipo_movimiento VARCHAR(50) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SELECT cb.saldo INTO vmonto FROM cuenta_banco cb where cb.id=id_cuenta_banco;
	SELECT m.valor INTO val_tipo_movimiento FROM maestra m where m.id=id_tipo_movimiento;
	CASE val_tipo_movimiento
        WHEN '1' THEN /*1=DEPOSITO*/
           SET vmonto = vmonto - monto;
        WHEN '2' THEN /*2=RETIRO*/
           SET vmonto = vmonto + monto;
		WHEN '3' THEN /*3=TRANSFERENCIA*/
           SET vmonto = vmonto + monto;
		WHEN '4' THEN /*4=DESCUENTO*/
           SET vmonto = vmonto + monto;
		WHEN '5' THEN /*5=INTERES*/
           SET vmonto = vmonto - monto;
        ELSE
           SET vmonto = vmonto;
    END CASE;
	UPDATE cuenta_banco cnt SET cnt.saldo = vmonto WHERE cnt.id = id_cuenta_banco;
	DELETE FROM ingreso WHERE id_movimiento_banco = idt;
	DELETE FROM movimiento_banco WHERE id = idt;
	COMMIT;
	SET rmensaje = 'Eliminado correctamente';
	SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_I_CUENTA_BANCO (IN nro_cuenta VARCHAR(20), IN cci VARCHAR(20), IN nombre VARCHAR(50), IN saldo DECIMAL(8,2), IN id_usuario_crea INT, IN fec_usuario_crea DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE rid INT unsigned DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
  	SET rcodigo = 1, rmensaje = 'Error al procesar';
  	SELECT rcodigo, rmensaje, rid;
	END;
START TRANSACTION;
	INSERT INTO cuenta_banco(nro_cuenta,cci,nombre,saldo,id_usuario_crea,fec_usuario_crea) VALUES(nro_cuenta,cci,nombre,saldo,id_usuario_crea,fec_usuario_crea);
  COMMIT;
  SET rmensaje = 'Registrado correctamente';
  SELECT MAX(ID) INTO rid FROM cuenta_banco;
  SELECT rcodigo, rmensaje, rid;
END$$

CREATE PROCEDURE PFC_I_EGRESO (IN id_tipo_egreso INT, IN id_unidad_medida INT, IN nombre VARCHAR(100), IN cantidad DECIMAL(8,2), IN precio DECIMAL(8,2), IN total DECIMAL(8,2), IN descripcion VARCHAR(500), IN ubicacion VARCHAR(100), IN dia VARCHAR(10), IN fecha DATE, IN id_usuario_crea INT, IN fec_usuario_crea DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE rid INT unsigned DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	INSERT INTO egreso(id_tipo_egreso,id_unidad_medida,nombre,cantidad,precio,total,descripcion,ubicacion,dia,fecha,id_usuario_crea,fec_usuario_crea,total_egreso) VALUES(id_tipo_egreso,id_unidad_medida,nombre,cantidad,precio,total,descripcion,ubicacion,dia,fecha,id_usuario_crea,fec_usuario_crea,total);
  COMMIT;
  SET rmensaje = 'Registrado correctamente';
  SELECT MAX(ID) INTO rid FROM egreso;
  SELECT rcodigo, rmensaje, rid;
END$$

CREATE PROCEDURE PFC_I_INGRESO (IN id_tipo_ingreso INT, IN nombre VARCHAR(150), IN monto DECIMAL(8,2), IN observacion VARCHAR(500), IN fecha DATE, IN id_estado INT, IN id_usuario_crea INT, IN fec_usuario_crea DATE, IN json JSON)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE rid INT unsigned DEFAULT 0;
DECLARE json_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(json);
DECLARE _index BIGINT UNSIGNED DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	INSERT INTO ingreso(id_tipo_ingreso,nombre,monto,observacion,fecha,id_estado,id_usuario_crea,fec_usuario_crea) VALUES(id_tipo_ingreso,nombre,monto,observacion,fecha,id_estado,id_usuario_crea,fec_usuario_crea);
	SELECT MAX(ID) INTO rid FROM ingreso;
	WHILE _index < json_items DO
		UPDATE egreso e SET e.total_egreso = JSON_EXTRACT(json, CONCAT('$[', _index, '].totalEgreso')) WHERE e.id = JSON_EXTRACT(json, CONCAT('$[', _index, '].id'));
		INSERT INTO retorno_egreso (id_egreso,id_ingreso,id_movimiento_banco,monto,fecha,id_usuario_crea,fec_usuario_crea) VALUES (JSON_EXTRACT(json, CONCAT('$[', _index, '].id')),rid,null,JSON_EXTRACT(json, CONCAT('$[', _index, '].monto')),fecha,id_usuario_crea,fec_usuario_crea);
		SET _index := _index + 1;
	END WHILE;
	COMMIT;
	SET rmensaje = 'Registrado correctamente';
	SELECT rcodigo, rmensaje, rid;
END$$

CREATE PROCEDURE PFC_I_MAESTRA (IN id_maestra_padre INT, IN orden INT, IN nombre VARCHAR(100), IN codigo VARCHAR(10), IN valor VARCHAR(50), IN id_usuario_crea INT, IN fec_usuario_crea DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
  	SET rcodigo = 1, rmensaje = 'Error al procesar';
  	SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	INSERT INTO maestra(id_maestra_padre,orden,nombre,codigo,valor,id_usuario_crea,fec_usuario_crea) VALUES(id_maestra_padre,orden,nombre,codigo,valor,id_usuario_crea,fec_usuario_crea);
  COMMIT;
  SET rmensaje = 'Registrado correctamente';
  SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_I_MOVIMIENTO_BANCO (IN id_cuenta_banco BIGINT, IN id_tipo_movimiento INT, IN val_tipo_movimiento INT, IN detalle VARCHAR(50), IN monto DECIMAL(8,2), IN fecha DATE, IN id_usuario_crea INT, IN fec_usuario_crea DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE rid INT unsigned DEFAULT 0;
DECLARE rmonto DECIMAL(8,2) DEFAULT 0.00;
DECLARE vnombrecb varchar(50) DEFAULT '';
DECLARE vid_tipo_ingreso INT unsigned DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SELECT cb.saldo,cb.nombre INTO rmonto,vnombrecb FROM cuenta_banco cb where cb.id=id_cuenta_banco;
	INSERT INTO movimiento_banco(id_cuenta_banco,id_tipo_movimiento,detalle,monto,fecha,id_usuario_crea,fec_usuario_crea) VALUES(id_cuenta_banco,id_tipo_movimiento,detalle,monto,fecha,id_usuario_crea,fec_usuario_crea);	
	SELECT MAX(ID) INTO rid FROM movimiento_banco;
	CASE val_tipo_movimiento
        WHEN  1 THEN /*1=DEPOSITO*/
           SET rmonto = rmonto + monto;
        WHEN 2 THEN /*2=RETIRO*/
           SET rmonto = rmonto - monto;
		   SELECT m.id INTO vid_tipo_ingreso from maestra m where m.valor = '1' and m.id_maestra_padre = (SELECT m.id from maestra m where m.valor = '4' and m.id_maestra_padre = 0); 
		   INSERT INTO ingreso(id_tipo_ingreso,id_movimiento_banco,nombre,monto,observacion,fecha,id_estado,id_usuario_crea,fec_usuario_crea) 
		   VALUES(vid_tipo_ingreso,rid,CONCAT('RETIRO - ',vnombrecb),monto,detalle,fecha,1,id_usuario_crea,fec_usuario_crea);
		WHEN 3 THEN /*3=TRANSFERENCIA*/
           SET rmonto = rmonto - monto;
		WHEN 4 THEN /*4=DESCUENTO*/
           SET rmonto = rmonto - monto;
		WHEN 5 THEN /*5=INTERES*/
           SET rmonto = rmonto + monto;
        ELSE
           SET rmonto = rmonto;
    END CASE;
	UPDATE cuenta_banco cnt SET cnt.saldo = rmonto where cnt.id = id_cuenta_banco;
  COMMIT;
  SET rmensaje = 'Registrado correctamente';
  SELECT rcodigo, rmensaje, rid;
END$$

CREATE PROCEDURE PFC_L_CUENTA_BANCO ()  BEGIN
  SELECT
  m.id AS 'id',
  m.nro_cuenta AS 'nroCuenta',
  m.cci AS 'cci',
  m.nombre AS 'nombre',
  m.saldo AS 'saldo',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM cuenta_banco m
  ORDER BY m.id DESC;
END$$

CREATE PROCEDURE PFC_L_EGRESO (IN id_tipo_egreso INT, IN dia VARCHAR(10), IN indicio VARCHAR(50), IN fecha_inicio DATE, IN fecha_fin DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT "";
DECLARE vsql varchar(500) DEFAULT "";
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = "Consulta exitosa";
	SET @vsql = "";
	IF (IFNULL(id_tipo_egreso,0)<>0) THEN
	  SET @vsql = CONCAT(@vsql, " AND e.id_tipo_egreso=",id_tipo_egreso);
	END IF;
	IF (IFNULL(dia,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.dia='",dia,"'");
	END IF;
	IF (IFNULL(indicio,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.nombre like '%",indicio,"%'");
	END IF;
	IF (IFNULL(fecha_inicio,"")<>"" AND IFNULL(fecha_fin,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.fecha>='",fecha_inicio,"' AND e.fecha<='",fecha_fin,"'");
	END IF;
	SET @msql = CONCAT("SELECT ",
		"0 AS 'rcodigo', ",
		"'Consulta exitosa' AS 'rmensaje', ",
		"CONCAT('[', ",
		"GROUP_CONCAT( ",
		"JSON_OBJECT( ",
		"'id',e.id, ",
		"'idTipoEgreso',e.id_tipo_egreso, ",
		"'nomTipoEgreso',(SELECT m.nombre FROM maestra m WHERE m.id = e.id_tipo_egreso), ",
		"'idUnidadMedida',e.id_unidad_medida, ",
		"'nomUnidadMedida',(SELECT m.nombre FROM maestra m WHERE m.id = e.id_unidad_medida), ",
		"'nombre', e.nombre, ",
		"'cantidad',e.cantidad, ",
		"'precio',e.precio, ",
		"'total', e.total, ",
		"'totalEgreso', e.total_egreso, ",
		"'descripcion',e.descripcion, ",
		"'ubicacion',e.ubicacion, ",
		"'dia',e.dia, ",
		"'fecha',e.fecha, ",
		"'idUsuarioCrea',e.id_usuario_crea, ",
		"'fecUsuarioCrea',e.fec_usuario_crea, ",
		"'idUsuarioMod',e.id_usuario_mod, ",
		"'fecUsuarioMod',e.fec_usuario_mod) ",
		" ORDER BY e.fecha DESC),']') AS 'result' ",
		"FROM egreso e WHERE 1=1",@vsql);
	PREPARE stmt1 FROM @msql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END$$

CREATE PROCEDURE PFC_L_EGRESO_RET (IN id_ingreso INT)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT "";
DECLARE vsql varchar(500) DEFAULT "";
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = "Consulta exitosa";
	SET @vsql = "";
	IF (IFNULL(id_ingreso,0)<>0) THEN
	  SET @vsql = CONCAT(@vsql, " AND re.id_ingreso=",id_ingreso);
	END IF;
	SET @msql = CONCAT("SELECT ",
		"0 AS 'rcodigo', ",
		"'Consulta exitosa' AS 'rmensaje', ",
		"CONCAT('[', ",
		"GROUP_CONCAT( ",
		"JSON_OBJECT( ",
		"'id',e.id, ",
		"'idTipoEgreso',e.id_tipo_egreso, ",
		"'nomTipoEgreso',(SELECT m.nombre FROM maestra m WHERE m.id = e.id_tipo_egreso), ",
		"'idUnidadMedida',e.id_unidad_medida, ",
		"'nomUnidadMedida',(SELECT m.nombre FROM maestra m WHERE m.id = e.id_unidad_medida), ",
		"'nombre', e.nombre, ",
		"'cantidad',e.cantidad, ",
		"'precio',e.precio, ",
		"'total', e.total, ",
		"'totalEgreso', e.total_egreso, ",
		"'totalRetorno', re.monto, ",
		"'descripcion',e.descripcion, ",
		"'ubicacion',e.ubicacion, ",
		"'dia',e.dia, ",
		"'fecha',e.fecha, ",
		"'idUsuarioCrea',e.id_usuario_crea, ",
		"'fecUsuarioCrea',e.fec_usuario_crea, ",
		"'idUsuarioMod',e.id_usuario_mod, ",
		"'fecUsuarioMod',e.fec_usuario_mod) ",
		" ORDER BY re.id ASC),']') AS 'result' ",
		"FROM egreso e inner join retorno_egreso re on re.id_egreso=e.id WHERE 1=1",@vsql);
	PREPARE stmt1 FROM @msql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END$$

CREATE PROCEDURE PFC_L_INGRESO (IN id_tipo_ingreso INT, IN indicio VARCHAR(50), IN fecha_inicio DATE, IN fecha_fin DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT "";
DECLARE vsql varchar(500) DEFAULT "";
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = "Consulta exitosa";
	SET @vsql = "";
	IF (IFNULL(id_tipo_ingreso,0)<>0) THEN
	  SET @vsql = CONCAT(@vsql, " AND e.id_tipo_ingreso=",id_tipo_ingreso);
	END IF;
	IF (IFNULL(indicio,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.nombre like '%",indicio,"%'");
	END IF;
	IF (IFNULL(fecha_inicio,"")<>"" AND IFNULL(fecha_fin,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.fecha>='",fecha_inicio,"' AND e.fecha<='",fecha_fin,"'");
	END IF;
	SET @msql = CONCAT("SELECT ",
		"0 AS 'rcodigo', ",
		"'Consulta exitosa' AS 'rmensaje', ",
		"CONCAT('[', ",
		"GROUP_CONCAT( ",
		"JSON_OBJECT( ",
		"'id',e.id, ",
		"'idTipoIngreso',e.id_tipo_ingreso, ",
		"'nomTipoIngreso',(SELECT m.nombre FROM maestra m WHERE m.id = e.id_tipo_ingreso), ",
		"'idMovimientoBanco',e.id_movimiento_banco, ",
		"'nombre', e.nombre, ",
		"'monto', e.monto, ",
		"'observacion',e.observacion, ",
		"'fecha',e.fecha, ",
		"'idEstado',e.id_estado, ",
		"'idUsuarioCrea',e.id_usuario_crea, ",
		"'fecUsuarioCrea',e.fec_usuario_crea, ",
		"'idUsuarioMod',e.id_usuario_mod, ",
		"'fecUsuarioMod',e.fec_usuario_mod) ",
		" ORDER BY e.fecha DESC),']') AS 'result' ",
		"FROM ingreso e WHERE 1=1",@vsql);
	PREPARE stmt1 FROM @msql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END$$

CREATE PROCEDURE PFC_L_MAESTRA (IN id_maestra_padre INT)  BEGIN
  SELECT
  m.id AS 'id',
  m.id_maestra_padre AS 'idMaestraPadre',
  m.orden AS 'orden',
  m.nombre AS 'nombre',
  m.codigo AS 'codigo',
  m.valor AS 'valor',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM maestra m WHERE m.id_maestra_padre = id_maestra_padre
  ORDER BY m.orden ASC;
END$$

CREATE PROCEDURE PFC_L_MOVIMIENTO_BANCO (IN id_cuenta_banco INT, IN indicio VARCHAR(50), IN fecha_inicio DATE, IN fecha_fin DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT "";
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET @vsql = "";
	IF (IFNULL(id_cuenta_banco,0)<>0) THEN
	  SET @vsql = CONCAT(@vsql, " AND e.id_cuenta_banco=",id_cuenta_banco);
	END IF;
	IF (IFNULL(indicio,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.detalle like '%",indicio,"%'");
	END IF;
	IF (IFNULL(fecha_inicio,"")<>"" AND IFNULL(fecha_fin,"")<>"") THEN
	  SET @vsql = CONCAT(@vsql, " AND e.fecha>='",fecha_inicio,"' AND e.fecha<='",fecha_fin,"'");
	END IF;
	SET @msql = CONCAT("SELECT ",
		"0 AS 'rcodigo', ",
		"'Consulta exitosa' AS 'rmensaje', ",
		"CONCAT('[', ",
		"GROUP_CONCAT( ",
		"JSON_OBJECT( ",
		"'id',e.id, ",
		"'idCuentaBanco',e.id_cuenta_banco, ",
		"'nomCuentaBanco',(SELECT cb.nombre FROM cuenta_banco cb WHERE cb.id = e.id_cuenta_banco), ",
		"'idTipoMovimiento',e.id_tipo_movimiento, ",
		"'nomTipoMovimiento',(SELECT mae.nombre FROM maestra mae WHERE mae.id = e.id_tipo_movimiento), ",
		"'detalle', e.detalle, ",
		"'monto',e.monto, ",
		"'fecha',e.fecha, ",
		"'idUsuarioCrea',e.id_usuario_crea, ",
		"'fecUsuarioCrea',e.fec_usuario_crea, ",
		"'idUsuarioMod',e.id_usuario_mod, ",
		"'fecUsuarioMod',e.fec_usuario_mod) ",
		" ORDER BY e.fecha DESC),']') AS 'result' ",
		"FROM movimiento_banco e WHERE 1=1",@vsql);
	PREPARE stmt1 FROM @msql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END$$

CREATE PROCEDURE PFC_S_BAR_CHART (IN anio INT, IN mes INT, IN dia INT, IN cant_dias INT, IN cant_dias_prev INT)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE vjson varchar(1200) DEFAULT '[]';
DECLARE vdia INT unsigned DEFAULT dia;
DECLARE vmes INT unsigned DEFAULT (mes + 1);
DECLARE vanio INT unsigned DEFAULT anio;
DECLARE vcontador INT unsigned DEFAULT 1;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = 'Consulta exitosa';
	simple_loop: LOOP
		SELECT JSON_ARRAY_APPEND(vjson,'$', JSON_OBJECT('label',vdia,'data',(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE YEAR(e.fecha) = vanio AND MONTH(e.fecha) = vmes AND DAY(e.fecha) = vdia))) INTO vjson;
		SET vdia = vdia - 1;
		IF vdia=0 THEN
			SET vdia = cant_dias_prev;
			SET vmes = vmes - 1;
		END IF;
		IF vmes=0 THEN
			SET vmes = 12;
			SET vanio = vanio - 1;
		END IF;
		SET vcontador = vcontador + 1;
		IF vcontador=(cant_dias + 1) THEN
			LEAVE simple_loop;
		END IF;
	END LOOP simple_loop;
	SELECT rcodigo AS 'rcodigo', rmensaje AS 'rmensaje', vjson AS 'result';
END$$

CREATE PROCEDURE PFC_S_CUENTA_BANCO (IN id BIGINT)  BEGIN
  SELECT
  m.id AS 'id',
  m.nro_cuenta AS 'nroCuenta',
  m.cci AS 'cci',
  m.nombre AS 'nombre',
  m.saldo AS 'saldo',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM cuenta_banco m WHERE m.id = id;
END$$

CREATE PROCEDURE PFC_S_EGRESO ()  BEGIN
  SELECT * FROM egreso;
END$$

CREATE PROCEDURE PFC_S_LINE_CHART (IN anio INT, IN mes INT, OUT rcodigo INTEGER, OUT rmensaje VARCHAR(100))  BEGIN
DECLARE vcontador INT unsigned DEFAULT 1;
DECLARE vanio INT unsigned DEFAULT anio;
DECLARE vmes INT unsigned DEFAULT (mes + 1);
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
	END;
START TRANSACTION;
	SET rcodigo = 0;
	SET rmensaje = 'Consulta exitosa';
	SET @QUERY = "";
	simple_loop: LOOP
		IF(vcontador=1) THEN
			SET @QUERY = CONCAT(@QUERY," SELECT ",(vmes-1)," as label,","(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE YEAR(e.fecha) = ",vanio," AND MONTH(e.fecha) = ",vmes,") as data,","(SELECT IF(SUM(m.monto) IS NULL, 0, SUM(m.monto)) FROM movimiento_banco m WHERE YEAR(m.fecha) = ",vanio," AND MONTH(m.fecha) = ",vmes," AND (m.id_tipo_movimiento = 25 OR m.id_tipo_movimiento = 29)) as dataIngMov,","(SELECT IF(SUM(i.monto) IS NULL, 0, SUM(i.monto)) FROM ingreso i WHERE YEAR(i.fecha) = ",vanio," AND MONTH(i.fecha) = ",vmes," AND i.id_tipo_ingreso = 32) as dataIng");
		ELSE
			SET @QUERY = CONCAT(@QUERY," UNION ALL SELECT ",(vmes-1)," as label,","(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE YEAR(e.fecha) = ",vanio," AND MONTH(e.fecha) = ",vmes,") as data,","(SELECT IF(SUM(m.monto) IS NULL, 0, SUM(m.monto)) FROM movimiento_banco m WHERE YEAR(m.fecha) = ",vanio," AND MONTH(m.fecha) = ",vmes," AND (m.id_tipo_movimiento = 25 OR m.id_tipo_movimiento = 29)) as dataIngMov,","(SELECT IF(SUM(i.monto) IS NULL, 0, SUM(i.monto)) FROM ingreso i WHERE YEAR(i.fecha) = ",vanio," AND MONTH(i.fecha) = ",vmes," AND i.id_tipo_ingreso = 32) as dataIng");
		END IF;
		SET vmes = vmes - 1;
		IF vmes=0 THEN
			SET vmes = 12;
			SET vanio = vanio - 1;
		END IF;
		SET vcontador = vcontador + 1;
		IF vcontador=13 THEN
			LEAVE simple_loop;
		END IF;
	END LOOP simple_loop;
	PREPARE STMT1 FROM @QUERY;
	EXECUTE STMT1;
	DEALLOCATE PREPARE STMT1;
END$$

CREATE PROCEDURE PFC_S_MAESTRA (IN id BIGINT)  BEGIN
  SELECT
  m.id AS 'id',
  m.id_maestra_padre AS 'idMaestraPadre',
  m.orden AS 'orden',
  m.nombre AS 'nombre',
  m.codigo AS 'codigo',
  m.valor AS 'valor',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM maestra m WHERE m.id = id;
END$$

CREATE PROCEDURE PFC_S_MOVIMIENTO_BANCO (IN id BIGINT)  BEGIN
  SELECT
  m.id AS 'id',
  m.id_cuenta_banco AS 'idCuentaBanco',
  (select cb.nombre from cuenta_banco cb where cb.id = m.id_cuenta_banco) as 'nomCuentaBanco',
  m.id_tipo_movimiento AS 'idTipoMovimiento',
  (select mae.nombre from maestra mae where mae.id = m.id_tipo_movimiento) as 'nomTipoMovimiento',
  m.detalle AS 'detalle',
  m.monto AS 'monto',
  m.fecha AS 'fecha',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM movimiento_banco m WHERE m.id = id;
END$$

CREATE PROCEDURE PFC_S_PIE_CHART (IN anio INT, IN id_tabla INT)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = 'Consulta exitosa';
	SELECT
		rcodigo AS 'rcodigo',
		rmensaje AS 'rmensaje',
		CONCAT('[',
		GROUP_CONCAT(
		JSON_OBJECT('label',m.nombre,'data',(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE e.id_tipo_egreso = m.id AND YEAR(e.fecha) = anio),'cantidad',(SELECT COUNT(e.id) FROM egreso e WHERE e.id_tipo_egreso = m.id AND YEAR(e.fecha) = anio))
		),']') AS 'result'
		FROM maestra m 
		WHERE m.id_maestra_padre = (select m2.id from maestra m2 where m2.id_tabla = id_tabla AND m2.id_maestra_padre = 0);
END$$

CREATE PROCEDURE PFC_S_SALDO_ACTUAL (IN dia INT, IN mes INT, IN anio INT, IN fecha DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE vmonto DECIMAL(8,2) DEFAULT 0.00;
DECLARE vmonto_egreso DECIMAL(8,2) DEFAULT 0.00;
DECLARE vmonto_ingreso DECIMAL(8,2) DEFAULT 0.00;
DECLARE vfecha DATE;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SELECT sm.monto,sm.fecha INTO vmonto,vfecha FROM saldo_mensual sm WHERE sm.mes = mes AND sm.anio = anio;
	SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) INTO vmonto_egreso FROM egreso e WHERE e.fecha >= vfecha AND e.fecha <= fecha;
	SELECT IF(SUM(i.monto) IS NULL, 0, SUM(i.monto)) INTO vmonto_ingreso FROM ingreso i WHERE i.fecha >= vfecha AND i.fecha <=fecha;
	SET vmonto = vmonto + vmonto_ingreso - vmonto_egreso;
	SET rmensaje = 'Consulta exitosa';
	SELECT
		rcodigo as 'rcodigo',
		rmensaje as 'rmensaje',
		JSON_ARRAY(JSON_OBJECT('id',0,'dia',dia,'mes',mes,'anio',anio,'monto',vmonto,'fecha',fecha)) as 'result';
END$$

CREATE PROCEDURE PFC_S_SALDO_MENSUAL (IN mes INT, IN anio INT)  BEGIN
  SELECT
  m.id AS 'id',
  m.dia AS 'dia',
  m.mes AS 'mes',
  m.anio AS 'anio',
  m.monto AS 'monto',
  m.fecha AS 'fecha',
  m.id_usuario_crea AS 'idUsuarioCrea',
  m.fec_usuario_crea AS 'fecUsuarioCrea',
  m.id_usuario_mod AS 'idUsuarioMod',
  m.fec_usuario_mod AS 'fecUsuarioMod'
  FROM saldo_mensual m WHERE m.mes = mes AND m.anio = anio;
END$$

CREATE PROCEDURE PFC_S_SUMA_CATEGORIA (IN anio INT, IN mes INT, IN id_tabla INT)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = 'Consulta exitosa';
	SELECT
		rcodigo AS 'rcodigo',
		rmensaje AS 'rmensaje',
		CONCAT('[',
		GROUP_CONCAT(
		JSON_OBJECT('label',m.nombre,'data',(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE e.id_tipo_egreso = m.id AND YEAR(e.fecha) = anio AND MONTH(e.fecha) = mes))
		),']') AS 'result'
		FROM maestra m 
		WHERE m.id_maestra_padre = (select m2.id from maestra m2 where m2.id_tabla = id_tabla AND m2.id_maestra_padre = 0);
END$$

CREATE PROCEDURE PFC_U_CUENTA_BANCO (IN id INT, IN nro_cuenta VARCHAR(20), IN cci VARCHAR(20), IN nombre VARCHAR(50), IN saldo DECIMAL(8,2), IN id_usuario_mod INT, IN fec_usuario_mod DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		SET rcodigo = 1, rmensaje = 'Error al procesar';
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	UPDATE cuenta_banco e SET e.nro_cuenta=nro_cuenta,e.cci=cci,e.nombre=nombre,e.saldo=saldo,e.id_usuario_mod=id_usuario_mod,e.fec_usuario_mod=fec_usuario_mod WHERE e.id=id;
	COMMIT;
	SET rmensaje = 'Modificado correctamente';
	SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_U_EGRESO (IN id INT, IN id_tipo_egreso INT, IN id_unidad_medida INT, IN nombre VARCHAR(100), IN cantidad DECIMAL(8,2), IN precio DECIMAL(8,2), IN total DECIMAL(8,2), IN descripcion VARCHAR(500), IN ubicacion VARCHAR(100), IN dia VARCHAR(10), IN fecha DATE, IN id_usuario_mod INT, IN fec_usuario_mod DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	UPDATE egreso e SET e.id_tipo_egreso=id_tipo_egreso,e.id_unidad_medida=id_unidad_medida,e.nombre=nombre,e.cantidad=cantidad,e.precio=precio,e.total=total,e.descripcion=descripcion,e.ubicacion=ubicacion,e.dia=dia,e.fecha=fecha,e.id_usuario_mod=id_usuario_mod,e.fec_usuario_mod=fec_usuario_mod,e.total_egreso=total WHERE e.id=id;
	COMMIT;
	SET rmensaje = 'Registrado correctamente';
	SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_U_INGRESO (IN id INT, IN id_tipo_ingreso INT, IN nombre VARCHAR(150), IN monto DECIMAL(8,2), IN observacion VARCHAR(500), IN fecha DATE, IN id_usuario_mod INT, IN fec_usuario_mod DATE, IN json JSON)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE json_items BIGINT UNSIGNED DEFAULT JSON_LENGTH(json);
DECLARE _index BIGINT UNSIGNED DEFAULT 0;
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	UPDATE ingreso e SET e.id_tipo_ingreso=id_tipo_ingreso,e.nombre=nombre,e.monto=monto,e.observacion=observacion,e.fecha=fecha,e.id_usuario_mod=id_usuario_mod,e.fec_usuario_mod=fec_usuario_mod WHERE e.id=id;
	DELETE FROM retorno_egreso where id_ingreso = id;
	WHILE _index < json_items DO
		UPDATE egreso e SET e.total_egreso = JSON_EXTRACT(json, CONCAT('$[', _index, '].totalEgreso')) WHERE e.id = JSON_EXTRACT(json, CONCAT('$[', _index, '].id'));
		INSERT INTO retorno_egreso (id_egreso,id_ingreso,id_movimiento_banco,monto,fecha,id_usuario_crea,fec_usuario_crea) VALUES (JSON_EXTRACT(json, CONCAT('$[', _index, '].id')),id,null,JSON_EXTRACT(json, CONCAT('$[', _index, '].monto')),fecha,id_usuario_crea,fec_usuario_crea);
		SET _index := _index + 1;
	END WHILE;
	COMMIT;
	SET rmensaje = 'Modificado correctamente';
	SELECT rcodigo, rmensaje;
END$$

CREATE PROCEDURE PFC_U_MAESTRA (IN id BIGINT, IN id_maestra_padre INT, IN orden INT, IN nombre VARCHAR(100), IN codigo VARCHAR(10), IN valor VARCHAR(50), IN id_usuario_mod INT, IN fec_usuario_mod DATE)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
  	SET rcodigo = 1, rmensaje = 'Error al procesar';
  	SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	UPDATE maestra m 
  SET m.id_maestra_padre=id_maestra_padre,m.orden=orden,m.nombre=nombre,m.codigo=codigo, m.valor=valor,m.id_usuario_mod=id_usuario_mod, m.fec_usuario_mod=fec_usuario_mod
  WHERE m.id=id;
  COMMIT;
  SET rmensaje = 'Actualizado correctamente';
  SELECT rcodigo, rmensaje;
END$$

DELIMITER ;