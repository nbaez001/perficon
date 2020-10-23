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

CREATE TABLE cuenta_banco (
  id bigint(20) UNSIGNED NOT NULL,
  nro_cuenta varchar(20) NOT NULL,
  cci varchar(20) NOT NULL,
  nombre varchar(50) NOT NULL,
  saldo decimal(8,2) UNSIGNED NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL
);

INSERT INTO cuenta_banco (id, nro_cuenta, cci, nombre, saldo, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod) VALUES
(1, '2003****17214', '0032****3****1721436', 'INTERBANK', 34338.91, 1, '2019-12-02', 1, '2020-08-11'),
(2, '0405****007', '0180****405****00700', 'BANCO DE LA NACION', 216.91, 1, '2019-12-02', 1, '2020-08-11'),
(3, '0409****757', '0180****409****75702', 'BANCO DE LA NACION 2', 3211.61, 1, '2020-08-19', 1, '2020-08-19'),
(4, '0277***376', '0092****027****37674', 'SCOTIABANK', 45.93, 1, '2020-10-02', 1, '2020-10-02');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla egreso
--

CREATE TABLE egreso (
  id bigint(20) UNSIGNED NOT NULL,
  id_tipo_egreso int(10) UNSIGNED NOT NULL,
  id_unidad_medida int(10) UNSIGNED NOT NULL,
  nombre varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  cantidad decimal(8,2) UNSIGNED NOT NULL,
  precio decimal(8,2) UNSIGNED NOT NULL,
  total decimal(8,2) UNSIGNED NOT NULL,
  descripcion varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  ubicacion varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  dia varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  fecha date NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL,
  total_egreso decimal(8,2) UNSIGNED DEFAULT NULL
);

--
-- Volcado de datos para la tabla egreso
--

INSERT INTO egreso (id, id_tipo_egreso, id_unidad_medida, nombre, cantidad, precio, total, descripcion, ubicacion, dia, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod, total_egreso) VALUES
(1, 3, 18, 'CUARTO', 1.00, 450.00, 450.00, '', '', 'SABADO', '2019-09-21', 1, '2019-11-14', 1, '2019-11-17', 450.00),
(2, 5, 19, 'PESCADO', 1.00, 12.00, 12.00, '1 PESCADO MEDIANO ENTERO', '', 'SABADO', '2019-09-21', 1, '2019-11-14', NULL, NULL, 12.00),
(3, 5, 19, 'MAIZ MORADO', 0.34, 3.50, 1.20, '3 CCORONTAS', 'MERCADO PALERMO', 'SABADO', '2019-09-21', 1, '2019-11-17', 1, '2019-11-17', 1.20),
(4, 5, 19, 'ARVEJAS', 0.25, 6.00, 1.50, '', 'PALERMO', 'SABADO', '2019-09-21', 1, '2019-11-17', 1, '2019-11-17', 1.50),
(5, 5, 18, 'ZANAHORIA', 1.00, 0.50, 0.50, '1 ZANAHORIA', 'PALERMO', 'SABADO', '2019-09-21', 1, '2019-11-17', NULL, NULL, 0.50),
(6, 5, 19, 'ARROZ', 2.00, 3.80, 7.60, '', '', 'SABADO', '2019-09-21', 1, '2019-11-17', NULL, NULL, 7.60),
(7, 17, 18, 'CORTE PANTALON', 1.00, 7.00, 7.00, '', 'PALERMO', 'SABADO', '2019-09-21', 1, '2019-11-17', NULL, NULL, 7.00),
(8, 4, 18, 'BITEL', 1.00, 29.90, 29.90, '', '', 'SABADO', '2019-09-21', 1, '2019-11-17', NULL, NULL, 29.90),
(9, 5, 19, 'HUEVOS', 1.00, 6.20, 6.20, '', '', 'DOMINGO', '2019-09-22', 1, '2019-11-17', NULL, NULL, 6.20),
(10, 5, 18, 'DORITOS', 1.00, 1.30, 1.30, '', '', 'DOMINGO', '2019-09-22', 1, '2019-11-17', NULL, NULL, 1.30),
(11, 8, 18, 'PASAJE', 2.00, 1.00, 2.00, '', '', 'LUNES', '2019-09-23', 1, '2019-11-17', NULL, NULL, 2.00),
(12, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'LUNES', '2019-09-23', 1, '2019-11-17', NULL, NULL, 9.00),
(13, 8, 18, 'PASAJE', 2.00, 1.00, 2.00, '', '', 'MARTES', '2019-09-24', 1, '2019-11-17', NULL, NULL, 2.00),
(14, 5, 18, 'ALMUERZO', 2.00, 1.00, 2.00, '', '', 'MARTES', '2019-09-24', 1, '2019-11-17', NULL, NULL, 2.00),
(15, 17, 18, 'COLABORACION', 1.00, 1.00, 1.00, '', '', 'MARTES', '2019-09-24', 1, '2019-11-17', NULL, NULL, 1.00),
(16, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 7.00),
(17, 5, 18, 'FIDEO', 1.00, 2.95, 2.95, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 2.95),
(18, 5, 18, 'MAYONESA', 1.00, 3.90, 3.90, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 3.90),
(19, 5, 20, 'LECHE', 6.00, 1.75, 10.50, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 10.50),
(20, 5, 21, 'ACEITE', 1.00, 3.90, 3.90, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 3.90),
(21, 5, 22, 'ARVEJA Y ZANAHORIA', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 1.00),
(22, 5, 19, 'POLLO', 0.83, 5.80, 4.80, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 4.80),
(23, 5, 22, 'PLATANO', 1.00, 2.00, 2.00, '5 PLATANOS', 'PALERMO', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 2.00),
(24, 5, 19, 'PAPA', 1.00, 2.80, 2.80, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 2.80),
(25, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-09-25', 1, '2019-11-17', NULL, NULL, 1.00),
(26, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2019-09-26', 1, '2019-11-17', NULL, NULL, 9.00),
(27, 5, 18, 'DESAYUNO', 1.10, 2.00, 2.20, '', '', 'VIERNES', '2019-09-27', 1, '2019-11-17', NULL, NULL, 2.20),
(28, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'VIERNES', '2019-09-27', 1, '2019-11-17', NULL, NULL, 8.00),
(29, 7, 18, 'MOUSE', 1.00, 20.00, 20.00, '', '', 'VIERNES', '2019-09-27', 1, '2019-11-17', NULL, NULL, 20.00),
(30, 5, 18, 'PICARONES', 1.00, 3.00, 3.00, '', '', 'VIERNES', '2019-09-27', 1, '2019-11-17', NULL, NULL, 3.00),
(31, 5, 19, 'MARACUYA', 0.34, 3.50, 1.20, '2 MARACUYAS MEDIANAS', '', 'SABADO', '2019-09-28', 1, '2019-11-17', NULL, NULL, 1.20),
(32, 5, 19, 'ARROZ DE MAZAMORRA', 1.09, 2.20, 2.40, '', '', 'SABADO', '2019-09-28', 1, '2019-11-17', NULL, NULL, 2.40),
(33, 5, 19, 'PAPA HUAYRO', 1.37, 3.50, 4.80, '', '', 'SABADO', '2019-09-28', 1, '2019-11-17', NULL, NULL, 4.80),
(34, 5, 19, 'HUEVO', 0.50, 6.00, 3.00, '7 HUEVOS', '', 'SABADO', '2019-09-28', 1, '2019-11-17', NULL, NULL, 3.00),
(35, 5, 19, 'ARROZ', 1.00, 4.60, 4.60, '', '', 'DOMINGO', '2019-09-29', 1, '2019-11-17', NULL, NULL, 4.60),
(36, 5, 19, 'FREJOL CASTILLA', 1.00, 6.50, 6.50, '', '', 'DOMINGO', '2019-09-29', 1, '2019-11-17', NULL, NULL, 6.50),
(37, 5, 19, 'POLLO', 0.43, 5.80, 2.50, '', '', 'DOMINGO', '2019-09-29', 1, '2019-11-17', NULL, NULL, 2.50),
(38, 5, 18, 'SALCHICHA POLLO', 1.00, 2.90, 2.90, 'CONTIENE 6 SALCHICHAS', '', 'DOMINGO', '2019-09-29', 1, '2019-11-17', NULL, NULL, 2.90),
(39, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'LUNES', '2019-09-30', 1, '2019-11-17', NULL, NULL, 8.00),
(40, 5, 18, 'SOYA', 1.00, 0.70, 0.70, '', '', 'MARTES', '2019-10-01', 1, '2019-11-17', NULL, NULL, 0.70),
(41, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', '', 'MARTES', '2019-10-01', 1, '2019-11-17', NULL, NULL, 2.00),
(42, 5, 18, 'ALMUERZO', 2.00, 8.00, 16.00, '', '', 'MARTES', '2019-10-01', 1, '2019-11-17', NULL, NULL, 16.00),
(43, 5, 18, 'SALCHICHA DE POLLO', 1.00, 11.00, 11.00, 'CONTIENE 12 SALCHICHAS', '', 'MARTES', '2019-10-01', 1, '2019-11-17', NULL, NULL, 11.00),
(44, 5, 18, 'SOYA', 1.00, 0.70, 0.70, '', '', 'MIERCOLES', '2019-10-02', 1, '2019-11-24', NULL, NULL, 0.70),
(45, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', '', 'MIERCOLES', '2019-10-02', 1, '2019-11-24', NULL, NULL, 2.00),
(46, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MIERCOLES', '2019-10-02', 1, '2019-11-24', NULL, NULL, 9.00),
(47, 5, 18, 'GASEOSA', 1.00, 2.50, 2.50, '', '', 'MIERCOLES', '2019-10-02', 1, '2019-11-24', NULL, NULL, 2.50),
(48, 5, 18, 'PAN', 1.00, 2.00, 2.00, '', '', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 2.00),
(49, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 9.00),
(50, 5, 19, 'HUEVO', 0.66, 5.00, 3.30, '', 'TIENDA', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 3.30),
(51, 5, 18, 'FILETE DE ATUN MERKAT', 1.00, 3.50, 3.50, '', '', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 3.50),
(52, 5, 19, 'MAIZ MORADO', 0.36, 4.50, 1.60, '2 CCORONTAS', '', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 1.60),
(53, 5, 18, 'PAN', 1.00, 2.00, 2.00, '', '', 'JUEVES', '2019-10-03', 1, '2019-11-24', NULL, NULL, 2.00),
(54, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'VIERNES', '2019-10-04', 1, '2019-11-24', NULL, NULL, 8.00),
(55, 5, 19, 'TOMATE', 0.23, 3.00, 0.70, '', '', 'SABADO', '2019-10-05', 1, '2019-11-24', 1, '2019-11-24', 0.70),
(56, 5, 18, 'LIMON', 2.00, 1.50, 3.00, '', '', 'SABADO', '2019-10-05', 1, '2019-11-24', NULL, NULL, 3.00),
(57, 9, 18, 'LAMISIL', 1.00, 23.00, 23.00, '', '', 'SABADO', '2019-10-05', 1, '2019-11-24', 1, '2019-11-24', 23.00),
(58, 6, 20, 'JABON', 1.00, 12.60, 12.60, '', '', 'SABADO', '2019-10-05', 1, '2019-11-24', NULL, NULL, 12.60),
(59, 5, 19, 'HUEVO', 1.00, 6.20, 6.20, '', '', 'DOMINGO', '2019-10-06', 1, '2019-11-24', NULL, NULL, 6.20),
(60, 5, 19, 'TOMATE', 0.23, 3.00, 0.70, '', '', 'DOMINGO', '2019-10-06', 1, '2019-11-24', NULL, NULL, 0.70),
(61, 5, 18, 'DORITOS', 1.00, 1.20, 1.20, '', '', 'DOMINGO', '2019-10-06', 1, '2019-11-24', NULL, NULL, 1.20),
(62, 5, 18, 'PAN', 1.00, 2.00, 2.00, '', '', 'LUNES', '2019-10-07', 1, '2019-11-24', NULL, NULL, 2.00),
(63, 5, 18, 'SOYA', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-10-07', 1, '2019-11-24', NULL, NULL, 1.00),
(64, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'LUNES', '2019-10-07', 1, '2019-11-24', NULL, NULL, 9.00),
(65, 5, 18, 'CENA', 1.00, 10.00, 10.00, '', '', 'LUNES', '2019-10-07', 1, '2019-11-24', NULL, NULL, 10.00),
(66, 5, 18, 'JUGO DE NARANJA', 2.00, 1.50, 3.00, '', '', 'MARTES', '2019-10-08', 1, '2019-11-24', NULL, NULL, 3.00),
(67, 5, 18, 'PEPSI', 1.00, 2.50, 2.50, '750 ML', '', 'MARTES', '2019-10-08', 1, '2019-11-24', NULL, NULL, 2.50),
(68, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 2.00),
(69, 5, 18, 'ALMUERZO', 2.00, 1.00, 2.00, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 2.00),
(70, 5, 18, 'ESCANEO', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 1.00),
(71, 5, 19, 'HUEVO', 0.67, 5.00, 3.35, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 3.35),
(72, 5, 18, 'ATUN', 2.00, 2.20, 4.40, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 4.40),
(73, 5, 19, 'TOMATE', 0.52, 4.49, 2.35, '4 TOMATES (ES MEJOR COMPRAR EN TIENDA)', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 2.35),
(74, 6, 18, 'GEL CURL ROCK AMPLIFIER', 1.00, 50.00, 50.00, '', '', 'MIERCOLES', '2019-10-09', 1, '2019-11-24', NULL, NULL, 50.00),
(75, 8, 18, 'PASAJE', 2.00, 1.00, 2.00, '', '', 'JUEVES', '2019-10-10', 1, '2019-11-24', NULL, NULL, 2.00),
(76, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2019-10-10', 1, '2019-11-24', NULL, NULL, 9.00),
(77, 17, 18, 'MEDID DE PESO', 2.00, 0.50, 1.00, '', '', 'JUEVES', '2019-10-10', 1, '2019-11-24', NULL, NULL, 1.00),
(78, 5, 19, 'AZUCAR', 0.50, 2.60, 1.30, '', '', 'JUEVES', '2019-10-10', 1, '2019-11-24', NULL, NULL, 1.30),
(79, 8, 18, 'PASAJE', 2.00, 1.00, 2.00, '', '', 'VIERNES', '2019-10-11', 1, '2019-11-24', NULL, NULL, 2.00),
(80, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'VIERNES', '2019-10-11', 1, '2019-11-24', NULL, NULL, 9.00),
(81, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 1.00),
(82, 5, 18, 'CEREAL', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 1.00),
(83, 5, 19, 'MAIZ MORADA', 0.47, 3.00, 1.40, '2 CCORONTAS', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 1.40),
(84, 5, 19, 'LIMON', 0.25, 2.00, 0.50, '9 LIMONES', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 0.50),
(85, 5, 19, 'PESCADO', 0.75, 8.00, 6.00, '2 PESCADOS JUREL', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 6.00),
(86, 5, 19, 'HARINA DE PESCADO', 0.25, 3.60, 0.90, '', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 0.90),
(87, 5, 18, 'AJI COLORADO', 1.00, 0.50, 0.50, '', '', 'SABADO', '2019-10-12', 1, '2019-11-24', NULL, NULL, 0.50),
(88, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'LUNES', '2019-10-14', 1, '2019-11-24', NULL, NULL, 9.00),
(89, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MARTES', '2019-10-15', 1, '2019-11-24', NULL, NULL, 9.00),
(90, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'MARTES', '2019-10-15', 1, '2019-11-24', NULL, NULL, 1.00),
(91, 17, 18, 'COLABORACION HERVIDORA', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-10-15', 1, '2019-11-24', NULL, NULL, 7.00),
(92, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MIERCOLES', '2019-10-16', 1, '2019-11-24', NULL, NULL, 9.00),
(93, 6, 18, 'PAPEL HIGIENICO', 1.00, 3.20, 3.20, '4 ROLLOS', '', 'MIERCOLES', '2019-10-16', 1, '2019-11-24', NULL, NULL, 3.20),
(94, 5, 22, 'BOLSA ARROZ', 1.00, 19.90, 19.90, 'BOLSA DE 5KG', '', 'MIERCOLES', '2019-10-16', 1, '2019-11-24', NULL, NULL, 19.90),
(95, 5, 18, 'BOLSA DE PLASTICO', 1.00, 0.10, 0.10, '', '', 'MIERCOLES', '2019-10-16', 1, '2019-11-24', NULL, NULL, 0.10),
(96, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2019-10-17', 1, '2019-11-24', NULL, NULL, 9.00),
(97, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2019-10-17', 1, '2019-11-24', NULL, NULL, 1.00),
(98, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'VIERNES', '2019-10-18', 1, '2019-11-24', NULL, NULL, 9.00),
(99, 5, 19, 'PESCADO', 1.00, 8.00, 8.00, '2 PESCADOS 1 PEQUEÑA Y 1 MEDIANA', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 8.00),
(100, 5, 19, 'PAPA', 1.00, 3.50, 3.50, '6 PAPAS GRANDES', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 3.50),
(101, 5, 19, 'MAIZ MORADA', 0.40, 3.50, 1.40, '2 CCORONTAS', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 1.40),
(102, 5, 19, 'TOMATE', 0.80, 3.50, 2.80, '3 TOMATES', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 2.80),
(103, 5, 19, 'LIMON', 0.27, 3.00, 0.80, '5 LIMONES', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 0.80),
(104, 5, 22, 'AGUAIMANTO', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 1.00),
(105, 5, 18, 'CEBOLLA', 1.00, 0.30, 0.30, '1 CEBOLLA MEDIANA', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 0.30),
(106, 5, 18, 'DORITOS', 1.00, 1.20, 1.20, '', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 1.20),
(107, 9, 18, 'IBUPROFENO 800MG', 1.00, 1.80, 1.80, '1 BLISTER', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 1.80),
(108, 9, 18, 'DEXAMETASONA 4MG', 1.00, 1.90, 1.90, '', '', 'SABADO', '2019-10-19', 1, '2019-11-24', NULL, NULL, 1.90),
(109, 6, 18, 'DESODORANTE NIVEA', 1.00, 10.50, 10.50, '', 'METRO CANADA', 'DOMINGO', '2019-10-20', 1, '2019-11-24', NULL, NULL, 10.50),
(110, 5, 19, 'AZUCAR MAXIMA', 1.00, 2.69, 2.69, 'PRODUCIDA POR METRO FORRO MORADO', '', 'DOMINGO', '2019-10-20', 1, '2019-11-24', NULL, NULL, 2.69),
(111, 6, 18, 'PASTA DENTAL WHITE ATRACCION', 1.00, 8.70, 8.70, '', 'METRO CANADA', 'DOMINGO', '2019-10-20', 1, '2019-11-24', NULL, NULL, 8.70),
(112, 5, 18, 'BOLSA PLASTICO', 1.00, 0.15, 0.15, '', '', 'DOMINGO', '2019-10-20', 1, '2019-11-24', NULL, NULL, 0.15),
(113, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'LUNES', '2019-10-21', 1, '2019-11-24', NULL, NULL, 9.00),
(114, 4, 18, 'BITEL', 1.00, 29.90, 29.90, '', '', 'LUNES', '2019-10-21', 1, '2019-11-24', NULL, NULL, 29.90),
(115, 12, 18, 'BOXER', 1.00, 8.00, 8.00, '', '', 'LUNES', '2019-10-21', 1, '2019-11-24', NULL, NULL, 8.00),
(116, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MARTES', '2019-10-22', 1, '2019-11-24', NULL, NULL, 9.00),
(117, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 9.00),
(118, 5, 18, 'LENTEJAS', 1.00, 3.00, 3.00, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 3.00),
(119, 5, 19, 'HUEVOS', 0.45, 5.10, 2.30, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 2.30),
(120, 5, 18, 'FOSFORO', 1.00, 0.30, 0.30, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 0.30),
(121, 5, 18, 'MAYONESA', 1.00, 2.80, 2.80, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 2.80),
(122, 6, 18, 'PAPEL HIGIENICO', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-10-23', 1, '2019-11-24', NULL, NULL, 1.00),
(123, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2019-10-24', 1, '2019-11-24', NULL, NULL, 9.00),
(124, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'VIERNES', '2019-10-25', 1, '2019-11-24', NULL, NULL, 9.00),
(125, 17, 18, 'PESO', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2019-10-25', 1, '2019-11-24', NULL, NULL, 1.00),
(126, 5, 18, 'FIDEOS NICOLINI', 1.00, 2.00, 2.00, 'NICOLINI 500G', '', 'SABADO', '2019-10-26', 1, '2019-11-24', 1, '2020-01-04', 2.00),
(127, 5, 18, 'AYUDIN', 1.00, 4.00, 4.00, '320G', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 4.00),
(128, 5, 18, 'DORITOS', 1.00, 1.20, 1.20, '', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 1.20),
(129, 5, 19, 'TOMATE', 0.34, 3.50, 1.20, '2 TOMATES EN TIENDA', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 1.20),
(130, 3, 18, 'ALQUILER', 1.00, 450.00, 450.00, '', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 450.00),
(131, 5, 18, 'GASEOSA', 1.00, 10.70, 10.70, '', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 10.70),
(132, 5, 19, 'AZUCAR', 1.00, 3.30, 3.30, '', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 3.30),
(133, 6, 18, 'DETERGENTE', 1.00, 4.00, 4.00, '', '', 'SABADO', '2019-10-26', 1, '2019-11-24', NULL, NULL, 4.00),
(134, 8, 18, 'PASAJE', 1.00, 2.00, 2.00, '', '', 'LUNES', '2019-10-28', 1, '2019-11-24', NULL, NULL, 2.00),
(135, 5, 18, 'HUEVO', 1.00, 1.20, 1.20, '', '', 'LUNES', '2019-10-28', 1, '2019-11-24', NULL, NULL, 1.20),
(136, 11, 18, 'ESCANEO', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-10-28', 1, '2019-11-24', NULL, NULL, 1.00),
(137, 8, 18, 'PASAJE', 1.00, 2.00, 2.00, '', '', 'MARTES', '2019-10-29', 1, '2019-11-24', NULL, NULL, 2.00),
(138, 5, 18, 'ALMUERZO', 2.00, 9.00, 18.00, '', '', 'MARTES', '2019-10-29', 1, '2019-11-24', NULL, NULL, 18.00),
(139, 13, 18, 'PASAJE AYACUCHO', 1.00, 60.00, 60.00, '', '', 'MARTES', '2019-10-29', 1, '2019-11-24', 1, '2019-11-24', 60.00),
(140, 8, 18, 'PASAJE', 3.00, 1.00, 3.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 3.00),
(141, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', 1, '2019-12-01', 9.00),
(142, 14, 18, 'TURRONES', 3.00, 12.50, 37.50, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 37.50),
(143, 16, 18, 'LIMAS TRONCOCONICA', 1.00, 5.00, 5.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 5.00),
(144, 16, 18, 'LIMAS CONICA', 1.00, 5.00, 5.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 5.00),
(145, 16, 18, 'LIMAS ESPECIALES', 1.00, 13.00, 13.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 13.00),
(146, 5, 18, 'CENA', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 7.00),
(147, 16, 18, 'PLACAS RADIOGRAFICAS', 0.50, 120.00, 60.00, '', '', 'MIERCOLES', '2019-10-30', 1, '2019-11-24', NULL, NULL, 60.00),
(148, 15, 18, 'MEDICINA', 1.00, 200.00, 200.00, '', '', 'JUEVES', '2019-10-31', 1, '2019-11-24', NULL, NULL, 200.00),
(149, 15, 18, 'COMPRAS MERCADO', 1.00, 215.20, 215.20, '', '', 'JUEVES', '2019-10-31', 1, '2019-11-24', NULL, NULL, 215.20),
(150, 15, 18, 'ALMUERZO FAMILIAR', 1.00, 126.00, 126.00, '', '', 'VIERNES', '2019-11-01', 1, '2019-11-24', NULL, NULL, 126.00),
(151, 15, 18, 'PEON PAPA', 1.00, 1500.00, 1500.00, '', '', 'MARTES', '2019-11-05', 1, '2019-11-24', NULL, NULL, 1500.00),
(152, 15, 18, 'PLANTAS PAPA', 1.00, 1000.00, 1000.00, '', '', 'MIERCOLES', '2019-11-06', 1, '2019-11-24', NULL, NULL, 1000.00),
(153, 13, 18, 'PASAJE LIMA', 1.00, 25.00, 25.00, '', '', 'MIERCOLES', '2019-11-06', 1, '2019-11-24', NULL, NULL, 25.00),
(154, 5, 18, 'ALMUERZO', 2.00, 9.00, 18.00, '', '', 'JUEVES', '2019-11-07', 1, '2019-11-24', NULL, NULL, 18.00),
(155, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'VIERNES', '2019-11-08', 1, '2019-11-24', NULL, NULL, 9.00),
(156, 5, 18, 'CHOCAPIC', 1.00, 12.50, 12.50, '', '', 'VIERNES', '2019-11-08', 1, '2019-11-24', NULL, NULL, 12.50),
(157, 5, 18, 'BOLSA', 1.00, 0.10, 0.10, '', '', 'VIERNES', '2019-11-08', 1, '2019-11-24', NULL, NULL, 0.10),
(158, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'SABADO', '2019-11-09', 1, '2019-11-24', NULL, NULL, 7.00),
(159, 5, 18, 'CENA', 1.00, 5.00, 5.00, '', '', 'SABADO', '2019-11-09', 1, '2019-11-24', NULL, NULL, 5.00),
(160, 5, 18, 'GASEOSA COCA COLA', 1.00, 2.50, 2.50, '', '', 'SABADO', '2019-11-09', 1, '2019-11-24', NULL, NULL, 2.50),
(161, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'DOMINGO', '2019-11-10', 1, '2019-11-24', NULL, NULL, 7.00),
(162, 5, 18, 'GASEOSA FANTA', 1.00, 2.50, 2.50, '', '', 'DOMINGO', '2019-11-10', 1, '2019-11-24', NULL, NULL, 2.50),
(163, 5, 18, 'CUATES', 2.00, 1.00, 2.00, '', '', 'DOMINGO', '2019-11-10', 1, '2019-11-24', NULL, NULL, 2.00),
(164, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'LUNES', '2019-11-11', 1, '2019-11-24', NULL, NULL, 9.00),
(165, 5, 18, 'CENA', 1.00, 5.00, 5.00, '', '', 'LUNES', '2019-11-11', 1, '2019-11-24', NULL, NULL, 5.00),
(166, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MARTES', '2019-11-12', 1, '2019-11-24', NULL, NULL, 9.00),
(167, 5, 19, 'UVAS', 0.50, 3.00, 1.50, '', '', 'MARTES', '2019-11-12', 1, '2019-11-24', NULL, NULL, 1.50),
(168, 3, 18, 'CUARTO', 1.00, 400.00, 400.00, '', '', 'MARTES', '2019-11-12', 1, '2019-11-24', NULL, NULL, 400.00),
(169, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'MIERCOLES', '2019-11-13', 1, '2019-11-24', NULL, NULL, 9.00),
(170, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-11-14', 1, '2019-11-24', NULL, NULL, 7.00),
(171, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2019-11-15', 1, '2019-11-24', NULL, NULL, 7.00),
(172, 5, 18, 'CENA', 1.00, 5.00, 5.00, '', '', 'VIERNES', '2019-11-15', 1, '2019-11-24', NULL, NULL, 5.00),
(173, 5, 18, 'PASAJE', 1.00, 8.00, 8.00, '', '', 'SABADO', '2019-11-16', 1, '2019-11-24', NULL, NULL, 8.00),
(174, 5, 18, 'DORITOS', 1.00, 1.20, 1.20, '', '', 'SABADO', '2019-11-16', 1, '2019-11-24', NULL, NULL, 1.20),
(175, 5, 18, 'CHICHA MORADA', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-11-16', 1, '2019-11-24', NULL, NULL, 1.00),
(176, 5, 19, 'SANDIA', 0.45, 4.00, 1.80, '', '', 'SABADO', '2019-11-16', 1, '2019-11-24', NULL, NULL, 1.80),
(177, 5, 18, 'AEROPUERTO', 1.00, 9.50, 9.50, '', '', 'SABADO', '2019-11-16', 1, '2019-11-24', NULL, NULL, 9.50),
(178, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'DOMINGO', '2019-11-17', 1, '2019-11-24', NULL, NULL, 8.00),
(179, 5, 18, 'GASEOSA KOLA REAL', 1.00, 2.20, 2.20, '1LITRO', '', 'DOMINGO', '2019-11-17', 1, '2019-11-24', NULL, NULL, 2.20),
(180, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2019-11-18', 1, '2019-11-24', NULL, NULL, 7.00),
(181, 17, 18, 'APORTE CUMPLEAÑOS', 1.00, 5.00, 5.00, '', '', 'LUNES', '2019-11-18', 1, '2019-11-24', 1, '2019-12-01', 5.00),
(182, 5, 19, 'MANGO PAPAYA', 1.00, 3.50, 3.50, '', '', 'LUNES', '2019-11-18', 1, '2019-11-24', NULL, NULL, 3.50),
(183, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-11-18', 1, '2019-11-24', NULL, NULL, 1.00),
(184, 23, 18, 'PRESTAMO VLADI CUMPLEAÑOS', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-11-18', 1, '2019-11-24', NULL, NULL, 1.00),
(185, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-11-19', 1, '2019-11-24', NULL, NULL, 7.00),
(186, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-11-20', 1, '2019-11-24', NULL, NULL, 7.00),
(187, 5, 19, 'FRESAS', 1.00, 3.00, 3.00, '', '', 'MIERCOLES', '2019-11-20', 1, '2019-11-24', NULL, NULL, 3.00),
(188, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-11-21', 1, '2019-11-24', NULL, NULL, 7.00),
(189, 4, 18, 'BITEL', 1.00, 29.90, 29.90, '', '', 'JUEVES', '2019-11-21', 1, '2019-11-24', NULL, NULL, 29.90),
(190, 5, 18, 'ALMUERZO', 1.00, 9.00, 9.00, '', '', 'VIERNES', '2019-11-22', 1, '2019-11-24', NULL, NULL, 9.00),
(191, 17, 18, 'BAÑO', 1.00, 0.50, 0.50, '', '', 'VIERNES', '2019-11-22', 1, '2019-11-24', NULL, NULL, 0.50),
(192, 17, 18, 'PESO', 1.00, 0.50, 0.50, '', '', 'VIERNES', '2019-11-22', 1, '2019-11-24', NULL, NULL, 0.50),
(193, 5, 18, 'MANDARINA', 1.00, 2.00, 2.00, '', '', 'VIERNES', '2019-11-22', 1, '2019-11-24', NULL, NULL, 2.00),
(194, 6, 18, 'PAPEL HIGIENICO', 1.00, 3.50, 3.50, '', '', 'VIERNES', '2019-11-22', 1, '2019-11-24', NULL, NULL, 3.50),
(195, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'SABADO', '2019-11-23', 1, '2019-11-24', NULL, NULL, 8.00),
(196, 7, 18, 'CATRE DE MADERA', 1.00, 130.00, 130.00, '', '', 'SABADO', '2019-11-23', 1, '2019-11-24', NULL, NULL, 130.00),
(197, 8, 18, 'PASAJE', 1.00, 10.00, 10.00, '', '', 'SABADO', '2019-11-23', 1, '2019-11-24', NULL, NULL, 10.00),
(198, 7, 18, 'PEGAMENTO', 2.00, 1.00, 2.00, '', '', 'SABADO', '2019-11-23', 1, '2019-11-24', NULL, NULL, 2.00),
(199, 17, 18, 'PERDIDO', 1.00, 3.50, 3.50, '', '', 'SABADO', '2019-11-23', 1, '2019-11-24', NULL, NULL, 3.50),
(200, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'DOMINGO', '2019-11-24', 1, '2019-11-24', NULL, NULL, 8.00),
(201, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2019-11-25', 1, '2019-11-26', 1, '2019-11-30', 7.00),
(202, 5, 19, 'MANGO', 1.00, 3.00, 3.00, '', '', 'LUNES', '2019-11-25', 1, '2019-11-26', 1, '2019-11-26', 3.00),
(203, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-11-27', 1, '2019-11-27', NULL, NULL, 7.00),
(204, 5, 18, 'PAPEL HIGIENICO', 1.00, 1.00, 1.00, 'PARA USO EN LA OFICINA', '', 'MIERCOLES', '2019-11-27', 1, '2019-11-27', NULL, NULL, 1.00),
(205, 5, 19, 'UVA PALESTINA', 0.50, 4.00, 2.00, '', '', 'MIERCOLES', '2019-11-27', 1, '2019-11-28', 1, '2019-11-28', 2.00),
(206, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-11-28', 1, '2019-11-28', NULL, NULL, 7.00),
(207, 7, 18, 'AUDIFONO', 1.00, 20.00, 20.00, '', '', 'JUEVES', '2019-11-28', 1, '2019-11-29', 1, '2019-11-29', 20.00),
(208, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2019-11-29', 1, '2019-11-30', 1, '2019-12-01', 7.00),
(209, 7, 18, 'HERVIDOR IMACO', 1.00, 69.00, 69.00, 'SERIE KE1518N\nGARANTIA DE 2 MESES', 'METRO CANADA', 'SABADO', '2019-11-30', 1, '2019-11-30', 1, '2019-12-02', 69.00),
(210, 5, 19, 'AZUCAR RUBIA', 1.00, 2.20, 2.20, '', 'MERCADO PALERMO', 'SABADO', '2019-11-30', 1, '2019-11-30', NULL, NULL, 2.20),
(211, 5, 18, 'ZUKO NARANJA', 1.00, 0.80, 0.80, 'RINDE 2L PESO 15G', 'MERCADO PALERMO', 'SABADO', '2019-11-30', 1, '2019-11-30', NULL, NULL, 0.80),
(212, 5, 18, 'MANZANA ISRAEL', 1.00, 2.50, 2.50, '1 MALLITA DE MANZANAS 15 MANZANAS APROX.', 'ESQUINA MERCADO PALERMO', 'SABADO', '2019-11-30', 1, '2019-11-30', NULL, NULL, 2.50),
(213, 7, 18, 'SOPORTE PARA CELULAR', 1.00, 5.00, 5.00, '', '', 'MARTES', '2019-11-26', 1, '2019-12-02', NULL, NULL, 5.00),
(214, 6, 22, 'DETERGENTE BOLIVAR', 1.00, 4.50, 4.50, 'BOLSA DE 500G', '', 'DOMINGO', '2019-12-01', 1, '2019-12-02', 1, '2019-12-02', 4.50),
(215, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', 'PARQUE PALERMO', 'DOMINGO', '2019-12-01', 1, '2019-12-02', 1, '2019-12-02', 8.00),
(216, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, 'MENU PAIS', '', 'LUNES', '2019-12-02', 1, '2019-12-02', NULL, NULL, 7.00),
(217, 17, 18, 'APORTE AMBIENTACION NAVIDAD', 1.00, 5.00, 5.00, '', '', 'LUNES', '2019-12-02', 1, '2019-12-02', NULL, NULL, 5.00),
(218, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-12-03', 1, '2019-12-03', NULL, NULL, 7.00),
(219, 5, 19, 'MANGO', 1.33, 3.00, 4.00, '', '', 'MARTES', '2019-12-03', 1, '2019-12-04', NULL, NULL, 4.00),
(220, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-12-04', 1, '2019-12-04', NULL, NULL, 7.00),
(221, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-12-05', 1, '2019-12-06', 1, '2019-12-06', 7.00),
(222, 5, 18, 'ALMUERZ BUFFET', 1.00, 31.80, 31.80, '29 SOLES DE BUFFET Y 2.8 DE CHICHA MORADA ENTRE 4 PERSONAS\nDEUDA ROCA1.8', '', 'VIERNES', '2019-12-06', 1, '2019-12-06', 1, '2019-12-07', 31.80),
(223, 17, 18, 'COLABORACION MENDIGO', 1.00, 0.50, 0.50, '', '', 'SABADO', '2019-12-07', 1, '2019-12-07', NULL, NULL, 0.50),
(224, 5, 18, 'TUMBO', 2.00, 0.50, 1.00, '', '', 'SABADO', '2019-12-07', 1, '2019-12-07', NULL, NULL, 1.00),
(225, 6, 18, 'PAPEL HIGIENICO OFICINA', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2019-12-05', 1, '2019-12-07', NULL, NULL, 1.00),
(226, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'DOMINGO', '2019-12-08', 1, '2019-12-08', NULL, NULL, 8.00),
(227, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2019-12-09', 1, '2019-12-09', NULL, NULL, 7.00),
(228, 11, 18, 'LAPICERO', 1.00, 0.80, 0.80, '', 'KIOSCO PROGRAMA PAIS', 'LUNES', '2019-12-09', 1, '2019-12-09', NULL, NULL, 0.80),
(229, 5, 19, 'DURAZNO', 0.50, 4.00, 2.00, '', '', 'LUNES', '2019-12-09', 1, '2019-12-10', NULL, NULL, 2.00),
(230, 5, 18, 'CAFE METRO', 1.00, 11.00, 11.00, 'CAFE GRANULADO METRO DE 100G', '', 'MARTES', '2019-12-10', 1, '2019-12-10', NULL, NULL, 11.00),
(231, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-12-10', 1, '2019-12-10', NULL, NULL, 7.00),
(232, 7, 18, 'CARGADOR LAPTOP SAMSUNG', 1.00, 35.00, 35.00, 'CARGADOR 19V 3.16A', 'WILSON', 'MARTES', '2019-12-10', 1, '2019-12-11', 1, '2019-12-11', 35.00),
(233, 5, 18, 'FRUNA', 1.00, 1.00, 1.00, '', '', 'MARTES', '2019-12-10', 1, '2019-12-11', 1, '2019-12-12', 1.00),
(234, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-12-11', 1, '2019-12-12', 1, '2019-12-12', 7.00),
(235, 6, 18, 'PASTA DENTAL CLOSE UP WHITE ATTRACTION', 1.00, 8.70, 8.70, '90G', '', 'MIERCOLES', '2019-12-11', 1, '2019-12-12', 1, '2019-12-12', 8.70),
(236, 5, 18, 'CAÑONAZO', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-12-11', 1, '2019-12-12', 1, '2019-12-12', 1.00),
(237, 12, 18, 'PLANTILLA ZAPATO', 1.00, 4.00, 4.00, '', '', 'MIERCOLES', '2019-12-11', 1, '2019-12-12', 1, '2019-12-12', 4.00),
(238, 5, 19, 'FRESAS', 2.00, 1.50, 3.00, '', 'TRICICLO AV. ABAYCAY', 'MIERCOLES', '2019-12-11', 1, '2019-12-12', 1, '2019-12-12', 3.00),
(239, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-12-12', 1, '2019-12-12', NULL, NULL, 7.00),
(240, 5, 18, 'PAN CON HUEVO HOTDOG', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2019-12-13', 1, '2019-12-13', NULL, NULL, 1.00),
(241, 9, 18, 'PANADOL ANTIGRIPAL', 1.00, 1.80, 1.80, 'PRECIO 2 SOLES, MONEDERO MIFARMA 1.8', 'MI FARMA JR CUSCO', 'VIERNES', '2019-12-13', 1, '2019-12-13', NULL, NULL, 1.80),
(242, 5, 18, 'AGUA SAN CARLOS', 1.00, 1.00, 1.00, '500ML', '', 'VIERNES', '2019-12-13', 1, '2019-12-13', NULL, NULL, 1.00),
(243, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2019-12-13', 1, '2019-12-13', NULL, NULL, 7.00),
(244, 17, 18, 'LIMOSNA', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2019-12-13', 1, '2019-12-14', 1, '2019-12-14', 1.00),
(245, 5, 19, 'DURASNO', 2.00, 1.50, 3.00, 'DURASNO HUAYCO 2KG 3SOLES', '', 'VIERNES', '2019-12-13', 1, '2019-12-14', 1, '2019-12-14', 3.00),
(246, 5, 18, 'GASEOSA INKA COLA', 1.00, 7.00, 7.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', NULL, NULL, 7.00),
(247, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', NULL, NULL, 8.00),
(248, 8, 18, 'PASAJE MANCO CAPAC - PALERMO', 3.00, 1.00, 3.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', 1, '2019-12-14', 3.00),
(249, 8, 18, 'PASAJE AVIACION - VILLA SALVADOR', 1.00, 2.00, 2.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', 1, '2019-12-14', 2.00),
(250, 8, 18, 'PASAJE MANCO CAPAC - PALERMO (PA)', 2.00, 1.00, 2.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', 1, '2019-12-15', 2.00),
(251, 8, 18, 'PASAJE VILLA SALVADOR - LURIN REPARTICION', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', NULL, NULL, 1.00),
(252, 8, 18, 'PASAJE LURN - CANAL 4', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-14', NULL, NULL, 1.00),
(253, 8, 18, 'PASAJE RETORNO PACHACAMAC - CRUCE LURIN', 2.00, 1.00, 2.00, 'MIO Y DE CESAR. EL MEJOR BUS PARA IR A LURIN ES EL BUS OLAS MARRON, NARANJA - FONDO BLANCO 8510', '', 'SABADO', '2019-12-14', 1, '2019-12-14', 1, '2019-12-15', 2.00),
(254, 6, 18, 'PAPEL HIGIENICO', 1.00, 13.50, 13.50, 'CONTIENE 24 ROLLOS DE PAPEL', 'TIENDA MASS PALERMO', 'SABADO', '2019-12-14', 1, '2019-12-15', 1, '2019-12-15', 13.50),
(255, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'DOMINGO', '2019-12-15', 1, '2019-12-15', NULL, NULL, 8.00),
(256, 5, 18, 'PAN CON QUESO', 2.00, 1.00, 2.00, '', '', 'DOMINGO', '2019-12-15', 1, '2019-12-15', NULL, NULL, 2.00),
(257, 10, 18, 'LAPIZ', 1.00, 1.00, 1.00, '', 'A 1 CUADRA DE PALERMO', 'SABADO', '2019-12-14', 1, '2019-12-15', 1, '2019-12-15', 1.00),
(258, 10, 18, 'TAJADOR', 1.00, 0.50, 0.50, '', '', 'SABADO', '2019-12-14', 1, '2019-12-15', NULL, NULL, 0.50),
(259, 5, 18, 'CENA POLLO A LA BRAZA', 1.00, 10.00, 10.00, 'PRECIO 9.99 = 10', 'PLAZA MANCO CAPAC', 'SABADO', '2019-12-14', 1, '2019-12-15', NULL, NULL, 10.00),
(260, 12, 18, 'MEDIAS LION', 1.00, 5.00, 5.00, '', 'AV. REP PANAMA - POLVOS AZULES', 'SABADO', '2019-12-14', 1, '2019-12-15', NULL, NULL, 5.00),
(261, 5, 18, 'PAN CON REBOSADO HUEVO Y SOYA', 3.00, 1.00, 3.00, '', 'AV. 28 DE JULIO - MANCO CAPAC', 'SABADO', '2019-12-14', 1, '2019-12-15', 1, '2019-12-15', 3.00),
(262, 8, 18, 'PASAJE PALERMO - MANCO CAPAC (PA)', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-12-14', 1, '2019-12-15', NULL, NULL, 1.00),
(263, 5, 18, 'CENA - SECO DE POLLO', 1.00, 7.00, 7.00, '', 'LUNA PIZARRO', 'DOMINGO', '2019-12-15', 1, '2019-12-16', 1, '2019-12-16', 7.00),
(264, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2019-12-16', 1, '2019-12-16', NULL, NULL, 7.00),
(265, 17, 18, 'COLABORACION CUMPLEAÑOS', 1.00, 5.00, 5.00, '', '', 'LUNES', '2019-12-16', 1, '2019-12-17', 1, '2019-12-17', 5.00),
(266, 6, 18, 'PAPEL HIGIENICO OFICINA', 1.00, 1.00, 1.00, 'PAPEL PARA OFICINA', '', 'LUNES', '2019-12-16', 1, '2019-12-17', 1, '2019-12-17', 1.00),
(267, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-12-17', 1, '2019-12-17', NULL, NULL, 7.00),
(268, 3, 18, 'PAGO CUARTO', 1.00, 400.00, 400.00, 'PAGO CUARTO DICIEMBRE', '', 'MARTES', '2019-12-17', 1, '2019-12-18', NULL, NULL, 400.00),
(269, 17, 18, 'COLABORACION COMPARTIR NAVIDAD', 1.00, 5.00, 5.00, 'COMPARTIR SERA EL LUNES', '', 'MARTES', '2019-12-17', 1, '2019-12-18', 1, '2019-12-18', 5.00),
(270, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2019-12-18', 1, '2019-12-18', NULL, NULL, 7.00),
(271, 8, 18, 'PASAJE PALERMO - MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'DOMINGO', '2019-12-15', 1, '2019-12-18', NULL, NULL, 1.00),
(272, 5, 18, 'PERAS', 5.00, 0.40, 2.00, '5 PERAS A 2 SOLES, UNIDAD 0.4', '', 'MIERCOLES', '2019-12-18', 1, '2019-12-19', NULL, NULL, 2.00),
(273, 5, 18, 'PLATANOS', 8.00, 0.13, 1.00, '8 PLATANOS POR 1 SOL', '', 'MIERCOLES', '2019-12-18', 1, '2019-12-19', NULL, NULL, 1.00),
(274, 5, 18, 'ZANAHORIA Y ARVEJA PICADA', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2019-12-19', 1, '2019-12-19', NULL, NULL, 1.00),
(275, 5, 18, 'AJO', 1.00, 1.20, 1.20, 'UNA BOLITA DE VARIOS AJOS + BOLSA 0.20', 'MERCADO PALERMO', 'JUEVES', '2019-12-19', 1, '2019-12-19', 1, '2019-12-19', 1.20),
(276, 5, 19, 'HUEVO', 0.47, 4.50, 2.10, '8 HUEVOS MEDIANOS', 'MASS PALERMO', 'JUEVES', '2019-12-19', 1, '2019-12-19', NULL, NULL, 2.10),
(277, 5, 18, 'NEGRITA PIÑA', 1.00, 0.80, 0.80, 'PESO 13G RIDEN 3 LITROS', 'TIENDA PALERMO', 'JUEVES', '2019-12-19', 1, '2019-12-19', NULL, NULL, 0.80),
(278, 5, 18, 'FRUNA', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2019-12-19', 1, '2019-12-20', NULL, NULL, 1.00),
(279, 5, 18, 'ALMUERZO', 2.00, 9.00, 18.00, 'UN ALMUERZO ADICIONAL PARA ROCA', '', 'VIERNES', '2019-12-20', 1, '2019-12-20', NULL, NULL, 18.00),
(280, 7, 18, 'COMBO LICUADORA Y OLLA', 1.00, 340.00, 340.00, 'COMBO OLLA ROCERA Y LICUADORA 329.90 MAS 10 SOLES COMISON POR TARJETA A ROCA', 'TIENDA SAGA FALABELLA JR. CUSCO', 'VIERNES', '2019-12-20', 1, '2019-12-20', NULL, NULL, 340.00),
(281, 7, 18, 'BOLSA', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2019-12-20', 1, '2019-12-20', NULL, NULL, 1.00),
(282, 5, 19, 'POLLO', 0.78, 5.80, 4.50, '3 PARTES PIERNA, ANTEPIERNA, MUSLO Y PATA', 'MERCADO PALERMO', 'SABADO', '2019-12-21', 1, '2019-12-21', 1, '2019-12-21', 4.50),
(283, 5, 18, 'MAYONESA ALACENA ', 1.00, 2.60, 2.60, '15G', 'MERCADO PALERMO', 'SABADO', '2019-12-21', 1, '2019-12-21', NULL, NULL, 2.60),
(284, 5, 19, 'LENTEJA', 1.00, 5.00, 5.00, 'TIENDA DEL FONDO', 'MERCADO PALERMO', 'SABADO', '2019-12-21', 1, '2019-12-21', NULL, NULL, 5.00),
(285, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2019-12-20', 1, '2019-12-21', NULL, NULL, 1.00),
(286, 8, 18, 'PASAJE', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-12-21', 1, '2019-12-21', 1, '2019-12-21', 1.00),
(287, 8, 18, 'PASAJE TAXI', 1.00, 8.00, 8.00, '', '', 'SABADO', '2019-12-21', 1, '2019-12-21', 1, '2019-12-21', 8.00),
(288, 12, 18, 'POLO MARRON', 1.00, 17.00, 17.00, '', 'GAMARRA', 'SABADO', '2019-12-21', 1, '2019-12-21', NULL, NULL, 17.00),
(289, 5, 18, 'CHICHA MORADA', 1.00, 1.00, 1.00, '', 'GAMARRA', 'SABADO', '2019-12-21', 1, '2019-12-21', NULL, NULL, 1.00),
(290, 5, 18, 'PASAJE PALERMO - MANCMANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'SABADO', '2019-12-21', 1, '2019-12-22', NULL, NULL, 1.00),
(291, 5, 18, 'CENA CALDO DE GALLINA', 1.00, 8.00, 8.00, '', '', 'SABADO', '2019-12-21', 1, '2019-12-22', NULL, NULL, 8.00),
(292, 6, 18, 'CORTE CABELLO', 1.00, 10.00, 10.00, '1RA PELUQUERIA', 'AV. MANCO CAPAC', 'DOMINGO', '2019-12-22', 1, '2019-12-22', NULL, NULL, 10.00),
(293, 8, 18, 'PASAJE METROPOLITANO', 1.00, 3.00, 3.00, '', '', 'LUNES', '2019-12-23', 1, '2019-12-23', NULL, NULL, 3.00),
(294, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2019-12-23', 1, '2019-12-23', NULL, NULL, 7.00),
(295, 4, 18, 'PAGO BITEL', 1.00, 29.90, 29.90, '', '', 'LUNES', '2019-12-23', 1, '2019-12-23', NULL, NULL, 29.90),
(296, 13, 18, 'PASAJE AYACUCHO', 1.00, 40.00, 40.00, 'MOLIBUS', 'LUNA PIZARRO', 'LUNES', '2019-12-23', 1, '2019-12-24', 1, '2019-12-25', 40.00),
(297, 8, 18, 'PASAJE PALERMO - MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-12-23', 1, '2019-12-24', NULL, NULL, 1.00),
(298, 5, 18, 'CHICHA MORADA', 1.00, 1.00, 1.00, '', 'LUNA PIZARRO', 'LUNES', '2019-12-23', 1, '2019-12-24', NULL, NULL, 1.00),
(299, 8, 18, 'PASAJE NERI G. - ELECTROCENTRO', 1.00, 2.00, 2.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-24', NULL, NULL, 2.00),
(300, 8, 18, 'PASAJE TAXY ELECTROCENTRO - NERI G.', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-24', NULL, NULL, 7.00),
(301, 15, 18, 'CONJUNTO MAX', 1.00, 40.00, 40.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 40.00),
(302, 15, 18, 'CONJUNTO BRIGIT', 1.00, 40.00, 40.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 40.00),
(303, 15, 18, 'TABLERO AJEDREZ', 1.00, 32.00, 32.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 32.00),
(304, 5, 18, 'REFRESCO CEBADA', 1.00, 1.00, 1.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 1.00),
(305, 17, 18, 'COHETE FIESTA PATRONAL', 1.00, 15.00, 15.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 15.00),
(306, 17, 18, 'COHETE CHISPITAS', 1.00, 1.00, 1.00, '', '', 'MARTES', '2019-12-24', 1, '2019-12-25', NULL, NULL, 1.00),
(307, 8, 18, 'PASAJE UNSCH - TERMINAL', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-25', NULL, NULL, 1.00),
(308, 13, 18, 'PASAJE AYACUCHO LIMA', 1.00, 40.00, 40.00, 'DIVINO SEÑOR', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-25', NULL, NULL, 40.00),
(309, 8, 18, 'PASAJE TERMINAL UNSCH', 1.00, 1.00, 1.00, 'RUTA 10', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-25', NULL, NULL, 1.00),
(310, 5, 18, 'RASPADILLAS', 5.00, 2.00, 10.00, '', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-25', NULL, NULL, 10.00),
(311, 8, 18, 'PASAJE NAZARENAS - TERMINAL', 1.00, 4.00, 4.00, '', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-26', NULL, NULL, 4.00),
(312, 13, 18, 'DERECHO DE EMBARQUE', 1.00, 1.50, 1.50, '', '', 'MIERCOLES', '2019-12-25', 1, '2019-12-26', NULL, NULL, 1.50),
(313, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2019-12-26', 1, '2019-12-26', NULL, NULL, 7.00),
(314, 5, 19, 'MANGO', 2.00, 2.50, 5.00, 'MANGO MALOGRADO', 'AV. 28 DE JULIO Y METROPOLITANO', 'JUEVES', '2019-12-26', 1, '2019-12-27', 1, '2019-12-27', 5.00),
(315, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2019-12-27', 1, '2019-12-27', NULL, NULL, 7.00),
(316, 8, 18, 'PASAJE MANCO CAPAC - PALERMO', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2019-12-26', 1, '2019-12-27', NULL, NULL, 1.00),
(317, 7, 18, 'AUDIFONOS TRONSMART SPUNKY BEAT', 1.00, 150.00, 150.00, '', '', 'VIERNES', '2019-12-27', 1, '2019-12-28', NULL, NULL, 150.00),
(318, 17, 18, 'LIMOSNA MEND. CENTRO EMPLEO', 1.00, 0.20, 0.20, '', '', 'SABADO', '2019-12-28', 1, '2019-12-28', NULL, NULL, 0.20),
(319, 5, 18, 'MARACUYA', 0.50, 3.00, 1.50, 'CARRETA ESQUINA DE CUARTO CASIMIRON NEGRON 245', '', 'SABADO', '2019-12-28', 1, '2019-12-28', NULL, NULL, 1.50),
(320, 5, 19, 'PESCADO BONITO', 0.50, 8.00, 4.00, '', 'MERCADO PALERMO', 'SABADO', '2019-12-28', 1, '2019-12-28', NULL, NULL, 4.00),
(321, 5, 18, 'AJI COLORADO', 1.00, 0.50, 0.50, '', 'PALERMO', 'SABADO', '2019-12-28', 1, '2019-12-28', NULL, NULL, 0.50),
(322, 5, 18, 'ALMUERZO PESCADO Y TACACHO', 1.00, 60.00, 60.00, 'PESCADO DE 30 Y PARTE TACACHO URBAY', 'AV. 28 DE JULIO', 'DOMINGO', '2019-12-29', 1, '2019-12-29', NULL, NULL, 60.00),
(323, 13, 18, 'PASAJE LIMA - AYACUCHO', 1.00, 50.00, 50.00, '', 'DIVINO SEÑOR', 'DOMINGO', '2019-12-29', 1, '2019-12-29', NULL, NULL, 50.00),
(324, 16, 18, 'ALGINATO', 1.00, 22.00, 22.00, 'ALGINELLE 168 HOURS PESO 450G.', 'JR. CUSCO', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 0.50),
(325, 16, 18, 'HUANTES GREAT GLOBE', 5.00, 9.00, 45.00, 'MARCA GREAT GLOVE - 100 GLOVES TALLA S - 1 MARCA RUBBERCARE', 'GALERIA 3RA A LA DERECHA', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 0.00),
(326, 16, 18, 'RESINA MASTER FLOW A1', 1.00, 30.00, 30.00, 'RESINA COMPUESTA FOTOCURABLE DE BAJA VISCOSIDAD - MASTER FLOW A1 - CONTIENE 1X2G JERINGA + ACCESORIO', 'GALERIA TIENDA IZQUIERDA PENULTIMA', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 0.00),
(327, 16, 18, 'CERA ROSADA MODELADORA - ECONOMIC KORIWAX', 1.00, 3.50, 3.50, 'MEDIDA 7.3X13X0.10, CONTENIDO 20 UNIDADES, PESO 155GRM', 'GALERIA TIENDA PENULTIMA IZQUIERDA', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 0.00),
(328, 8, 18, 'PASAJE TAXI - GAMARRA PLAZA SAN MARTIN', 1.00, 10.00, 10.00, '', '', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 10.00),
(329, 6, 18, 'JABON HENO PRAVIA GRADE', 1.00, 3.50, 3.50, '', 'TIENDA PALERMO', 'DOMINGO', '2019-12-29', 1, '2019-12-30', NULL, NULL, 3.50),
(330, 8, 18, 'PASAJE PALERMO - MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-12-30', 1, '2019-12-30', NULL, NULL, 1.00),
(331, 5, 18, 'TRIO EXPRESS', 1.00, 37.00, 37.00, 'TRIO EXPRESS 27 SOLES - JARA DE CHICHA 10 SOLES', 'UNA CUADRA DEL MES', 'LUNES', '2019-12-30', 1, '2019-12-30', 1, '2019-12-30', 37.00),
(332, 8, 18, 'PASAJE PALERMO - MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-12-30', 1, '2019-12-31', NULL, NULL, 1.00),
(333, 8, 18, 'PASAJE RUTA 9', 1.00, 0.80, 0.80, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 0.80),
(334, 8, 18, 'PASAJE MOTOTAXY', 1.00, 2.00, 2.00, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 2.00),
(335, 5, 18, 'PASAJE NAZARENAS - MERCADO SANTA CLARA', 2.00, 0.75, 1.50, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 1.50),
(336, 5, 19, 'LECHON', 0.30, 20.00, 6.00, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 6.00),
(337, 8, 18, 'MOTOTAXI MER. SANTA CLARA - NAZARENAS', 1.00, 6.00, 6.00, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 6.00),
(338, 5, 18, 'REFRESCO MARACUYA', 1.00, 1.00, 1.00, '', '', 'LUNES', '2019-12-30', 1, '2019-12-31', 1, '2019-12-31', 1.00),
(339, 5, 18, 'GASEOSA KR NEGRA', 1.00, 6.00, 6.00, '', '', 'MARTES', '2019-12-31', 1, '2019-12-31', NULL, NULL, 6.00),
(340, 12, 18, 'BOXER AMARILLO', 1.00, 10.00, 10.00, '', '', 'MARTES', '2019-12-31', 1, '2020-01-01', NULL, NULL, 10.00),
(341, 15, 18, 'TRUZA AMARILLO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2019-12-31', 1, '2020-01-01', NULL, NULL, 7.00),
(342, 17, 18, 'VINO ', 1.00, 30.00, 30.00, '3 VINOS A 12  IGUAL 36 MENOS 6', '', 'MARTES', '2019-12-31', 1, '2020-01-01', NULL, NULL, 30.00),
(343, 15, 18, 'MATRICULA ZOE', 1.00, 90.00, 90.00, 'MATRICULA COMPLETA 340 POR 2 MESES', 'CEPRE UNSCH', 'JUEVES', '2020-01-02', 1, '2020-01-02', NULL, NULL, 90.00),
(344, 5, 18, 'CHICHA MORADA', 2.00, 1.00, 2.00, '', '', 'JUEVES', '2020-01-02', 1, '2020-01-02', NULL, NULL, 2.00),
(345, 13, 18, 'PASAJE ESPINOZA AYACUCHO - LIMA', 1.00, 60.00, 60.00, '', '', 'JUEVES', '2020-01-02', 1, '2020-01-02', NULL, NULL, 60.00),
(346, 15, 18, 'PEON PAPA', 1.00, 1500.00, 1500.00, 'PARA PEON DE PAPA', '', 'JUEVES', '2020-01-02', 1, '2020-01-03', NULL, NULL, 1500.00),
(347, 8, 18, 'PASAJE NAZARENAS - TERMINAL', 1.00, 4.00, 4.00, '', '', 'JUEVES', '2020-01-02', 1, '2020-01-03', NULL, NULL, 4.00),
(348, 13, 18, 'TARIFA EMBARQUE', 1.00, 1.50, 1.50, '', '', 'JUEVES', '2020-01-02', 1, '2020-01-03', NULL, NULL, 1.50),
(349, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2020-01-03', 1, '2020-01-03', NULL, NULL, 7.00),
(350, 7, 18, 'AUDIFONO SAMSUNG', 1.00, 10.00, 10.00, '', '', 'VIERNES', '2020-01-03', 1, '2020-01-04', NULL, NULL, 10.00),
(351, 12, 18, 'SHORT NIKE PLOMO', 1.00, 18.00, 18.00, '', '', 'VIERNES', '2020-01-03', 1, '2020-01-04', NULL, NULL, 18.00),
(352, 5, 19, 'PESCADO BONITO', 0.93, 7.00, 6.50, '4 TROZOS DE PESCADO', 'MERCADO MUNICIPAL MANCO CAPAC', 'SABADO', '2020-01-04', 1, '2020-01-04', NULL, NULL, 6.50),
(353, 5, 18, 'AJI COLORADO', 1.00, 0.50, 0.50, 'NO SABE PREPARAR', 'MERCADO MANCO CAPAC', 'SABADO', '2020-01-04', 1, '2020-01-04', NULL, NULL, 0.50),
(354, 5, 19, 'MARACUYA', 0.71, 2.80, 2.00, '4 MARACUYAS - 2 GRANDES 2 PEQUEÑOS MAS 0.1 DE BOLSA NEGRA', 'MERCADO MANCO CAPAC', 'SABADO', '2020-01-04', 1, '2020-01-04', NULL, NULL, 2.00),
(355, 5, 18, 'FIDEOS BELLS', 2.00, 1.40, 2.80, '500GR', 'TIENDA MASS PALERMO', 'SABADO', '2020-01-04', 1, '2020-01-04', 1, '2020-01-04', 2.80),
(356, 5, 18, 'DORITOS QUESO', 1.00, 2.50, 2.50, '85 GR', 'TIENDA MASS PALERMO', 'SABADO', '2020-01-04', 1, '2020-01-04', 1, '2020-01-04', 2.50),
(357, 5, 18, 'BOLSA MASS', 1.00, 0.10, 0.10, '', 'TIENDA MASS PALERMO', 'SABADO', '2020-01-04', 1, '2020-01-04', NULL, NULL, 0.10),
(358, 6, 18, 'PAPEL HIGIENICO', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-01-03', 1, '2020-01-06', NULL, NULL, 1.00),
(359, 8, 18, 'PASAJE RUTA 23', 1.00, 1.00, 1.00, 'MANCO CAPAC - PALERMO', '', 'VIERNES', '2020-01-03', 1, '2020-01-06', NULL, NULL, 1.00),
(360, 5, 19, 'MANDARINA VERDE', 0.50, 4.00, 2.00, '8 MANDARINAS PEQUEÑAS', 'CARRETA ESQUINA CUARTO', 'VIERNES', '2020-01-03', 1, '2020-01-06', NULL, NULL, 2.00),
(361, 5, 18, 'PAN CON MANJAR', 1.00, 1.00, 1.00, '5 PANECILLOS CON MANJAR', 'AV. MANCO CAPAC', 'LUNES', '2020-01-06', 1, '2020-01-07', NULL, NULL, 1.00),
(362, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2020-01-06', 1, '2020-01-07', NULL, NULL, 7.00),
(363, 5, 19, 'ARANDANO', 1.00, 2.00, 2.00, '', 'AV. MANCO CAPAC', 'LUNES', '2020-01-06', 1, '2020-01-07', NULL, NULL, 2.00),
(364, 5, 18, 'PAN AMARILLO', 1.00, 1.00, 1.00, '6 PANECILLOS', 'AV. MANCO CAPAC', 'MARTES', '2020-01-07', 1, '2020-01-08', NULL, NULL, 1.00),
(365, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'MARTES', '2020-01-07', 1, '2020-01-08', NULL, NULL, 7.00),
(366, 5, 18, 'PLATANOS', 1.00, 1.00, 1.00, '7 PLATANOS POR 1 SOL', '', 'MARTES', '2020-01-07', 1, '2020-01-08', NULL, NULL, 1.00),
(367, 5, 18, 'PAN CON REBOSADO', 2.00, 1.00, 2.00, '', '', 'MIERCOLES', '2020-01-08', 1, '2020-01-08', NULL, NULL, 2.00),
(368, 5, 18, 'ALMUEZO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2020-01-08', 1, '2020-01-08', NULL, NULL, 7.00),
(369, 5, 18, 'PAN CON REBOSADO Y QUESO', 2.00, 1.00, 2.00, '', '', 'JUEVES', '2020-01-09', 1, '2020-01-09', NULL, NULL, 2.00),
(370, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2020-01-09', 1, '2020-01-09', NULL, NULL, 7.00),
(371, 5, 19, 'UVA ROSADA SIN PEPA', 1.00, 2.00, 2.00, '', '', 'JUEVES', '2020-01-09', 1, '2020-01-10', NULL, NULL, 2.00),
(372, 5, 18, 'PAN', 1.00, 1.00, 1.00, '6 PANES', 'TIENDA AL COSTADO DEL TAMBO PALERMO', 'JUEVES', '2020-01-09', 1, '2020-01-10', NULL, NULL, 1.00),
(373, 5, 19, 'HUEVO', 0.51, 4.30, 2.20, '9 HUEVOS PEQUEÑAS', 'TIENDA AL COSTADO DEL MERCADO PALERMO', 'JUEVES', '2020-01-09', 1, '2020-01-10', NULL, NULL, 2.20),
(374, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 7.00),
(375, 17, 18, 'APORTE DESPEDIDA AMBROSIO', 1.00, 5.00, 5.00, '', '', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 5.00),
(376, 6, 18, 'JABON HENO DE PRAVIA 3X150G', 1.00, 12.60, 12.60, 'ESTAFA PRECIO TIENDA 3.50! 3X150G UNIDAD 4.2', 'METRO CENTRO HISTORICO', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 12.60),
(377, 5, 18, 'PIMIENTA SIBARITA NEGRA 40G', 1.00, 8.90, 8.90, 'PIMIENTA NEGRA 40G 1.41OZ', 'METRO CENTRO HISTORICO', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 8.90),
(378, 5, 18, 'PAÑO METRO 3UNIDADES', 1.00, 10.30, 10.30, '3 UNIDADES 18X20CM', 'METRO CENTRO HISTORICO', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 10.30),
(379, 5, 18, 'MAYONESA ALACENA 190G', 1.00, 4.89, 4.89, 'PESO 190G', 'METRO CENTRO HISTORICO', 'VIERNES', '2020-01-10', 1, '2020-01-11', 1, '2020-01-11', 4.89),
(380, 5, 18, 'ACEITE MAXIMA', 1.00, 3.80, 3.80, '900ML', 'METRO CENTRO HISTORICO', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 3.80),
(381, 8, 18, 'PASAJE RUTA 23A', 1.00, 1.00, 1.00, 'PASAJE PALERMO - MANCO CAPAC', '', 'VIERNES', '2020-01-10', 1, '2020-01-11', NULL, NULL, 1.00),
(382, 11, 18, 'COPIA DNI Y FOLDER MANILA', 1.00, 0.70, 0.70, '0.2 COPIA Y 0.5 FOLDER', 'A 2 CUADRAS DE PALERMO', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 0.70),
(383, 8, 18, 'PASAJE BUS IO47', 1.00, 2.50, 2.50, 'DESDE CAMPO DE MARTE - OVALO NARANJAL, COLOR NARANJA BLANCO CON CINTAS AZULEW', '', 'SABADO', '2020-01-11', 1, '2020-01-11', 1, '2020-01-11', 2.50),
(384, 8, 18, 'PASAJE BUS 47 ', 1.00, 2.50, 2.50, 'PASAJE UNIVERSIDAD PRIVADA DEL NORTE - PARINACOCHAS, BUS COLOR NARANJA Y BLANCO', '', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 2.50),
(385, 5, 19, 'QUESO', 0.57, 16.00, 9.20, '', 'MERCADO PALERMO', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 9.20),
(386, 5, 19, 'AZUCAR RUBIA', 1.00, 2.40, 2.40, '', 'MERCADO PALERMO TIENDA FONDO', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 2.40),
(387, 5, 18, 'AJI COLORADO', 1.00, 0.30, 0.30, 'NO QUISO DAR CON AJO Y COMINO', 'MERCADO PALERMO TIENDA FILA 3', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 0.30),
(388, 5, 19, 'MAIZ MORADA ', 0.50, 3.00, 1.50, '4 MASORCAS MEDIANAS', 'MERCADO PALERMO TIENDA FILA 2', 'SABADO', '2020-01-11', 1, '2020-01-11', NULL, NULL, 1.50),
(389, 9, 18, 'PANADOL ATIGRIPAL NF', 1.00, 2.00, 2.00, '2 TABLETAS', 'MI FARMA PALERMO', 'DOMINGO', '2020-01-12', 1, '2020-01-13', NULL, NULL, 2.00),
(390, 5, 18, 'PAN', 1.00, 1.00, 1.00, 'MAS A LA IZQUIERDA HAY MAYOR VARIEDAD, IR A LA PROXIMA, 5 PANES CADA UNO 0.2', 'TIENDA AL COSTADO DEL TAMBO', 'DOMINGO', '2020-01-12', 1, '2020-01-13', 1, '2020-01-13', 1.00),
(391, 6, 22, 'DETERGENTE BOREAL', 1.00, 5.20, 5.20, '900GR CONVIENE A DIFERENCIA DEL BOLIVAR', 'TIENDA MASS PALERMO', 'DOMINGO', '2020-01-12', 1, '2020-01-13', 1, '2020-01-13', 5.20),
(392, 6, 18, 'BOLSA MASS', 1.00, 0.10, 0.10, '', 'TIENDA MASS', 'DOMINGO', '2020-01-12', 1, '2020-01-13', NULL, NULL, 0.10),
(393, 5, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, 'PALERMO - MANCO CAPAC', '', 'LUNES', '2020-01-13', 1, '2020-01-13', NULL, NULL, 1.00),
(394, 9, 18, 'PANADOL ANTIGRIPAL', 1.00, 1.90, 1.90, 'PRECIO 2.10 DESCUENTO 1.90', 'MI FARMA AV. ABANCAY', 'LUNES', '2020-01-13', 1, '2020-01-13', NULL, NULL, 1.90),
(395, 4, 18, 'BITEL FEBRERO', 1.00, 29.90, 29.90, '', '', 'LUNES', '2020-01-13', 1, '2020-01-13', NULL, NULL, 29.90),
(396, 5, 18, 'ATUN BELTRAN GRATED DE SARDINA', 2.00, 2.20, 4.40, '170GR', 'TIENDA MAXI AHORRO', 'MARTES', '2020-01-14', 1, '2020-01-15', 1, '2020-01-15', 4.40),
(397, 5, 18, 'BOLSA', 1.00, 0.20, 0.20, '', 'TIENDA MAXI AHORRO', 'MARTES', '2020-01-14', 1, '2020-01-15', NULL, NULL, 0.20),
(398, 5, 18, 'ALMUERZO', 1.00, 10.00, 10.00, '', '', 'MIERCOLES', '2020-01-15', 1, '2020-01-15', NULL, NULL, 10.00),
(399, 17, 18, 'VISITA MUSEO NAVAL CASA GRAU', 1.00, 3.00, 3.00, '', '', 'MIERCOLES', '2020-01-15', 1, '2020-01-15', 1, '2020-01-17', 3.00);
INSERT INTO egreso (id, id_tipo_egreso, id_unidad_medida, nombre, cantidad, precio, total, descripcion, ubicacion, dia, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod, total_egreso) VALUES
(400, 5, 18, 'DEUDA ALMUERZO LUNES', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2020-01-15', 1, '2020-01-15', NULL, NULL, 7.00),
(401, 5, 19, 'DURAZNO', 0.50, 4.00, 2.00, '', 'CARRETA AL ESQUINADEL CUARTO', 'MIERCOLES', '2020-01-15', 1, '2020-01-16', NULL, NULL, 2.00),
(402, 17, 18, 'FOTO TAMAÑO CARNET', 1.00, 24.00, 24.00, '6 FOTOS CARNET', 'AV. ABANCAY', 'JUEVES', '2020-01-16', 1, '2020-01-16', NULL, NULL, 24.00),
(403, 5, 18, 'ALMUERZO', 2.00, 7.00, 14.00, '', '', 'JUEVES', '2020-01-16', 1, '2020-01-16', NULL, NULL, 14.00),
(404, 5, 19, 'AZUCAR RUBIA', 1.00, 2.49, 2.49, '1KG', 'METRO CENTRO HISTORICO', 'JUEVES', '2020-01-16', 1, '2020-01-16', NULL, NULL, 2.49),
(405, 17, 18, 'VISITA MUSEO DE LOS COMBATIENTES DEL MORO DE ARICA', 1.00, 3.00, 3.00, '', '', 'VIERNES', '2020-01-17', 1, '2020-01-17', NULL, NULL, 3.00),
(406, 8, 18, 'PASAJE BUS 8516 UNIVERSIDAD CIENTIFICA', 1.00, 2.00, 2.00, 'BUS 8516 COLOR BLANCO Y OLAS AMARILLAS', '', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 2.00),
(407, 8, 18, 'PASAJE BUS 8516', 1.00, 2.00, 2.00, 'BUS 8516 COLOR BLANCO CON OLAS AMARILLAS', '', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 2.00),
(408, 5, 18, 'TARI CREMA DE AJI ALACENA', 1.00, 7.90, 7.90, '', 'PLAZA VEA CHORILLOS', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 7.90),
(409, 5, 19, 'HUEVOS', 0.47, 4.30, 2.00, '8 HUEVOS', 'TIENDA MASS PALERMO', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 2.00),
(410, 5, 18, 'BOLSA MASS', 1.00, 0.10, 0.10, '', 'TIENDA MASS PALERMO', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 0.10),
(411, 5, 18, 'SA DE COCINA MARINA', 1.00, 1.30, 1.30, '1KG DE SAL DE COCINA', 'PRIMERA TIENDA A LA IZQUIERDA BAJANDO DEL CUARTO PALERMO', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 1.30),
(412, 5, 18, 'TOMATE', 2.00, 0.50, 1.00, 'TOMATES GRANDES A 0.5', 'CARRETA VERDURAS BAJANDO CUARTO PALERMO', 'SABADO', '2020-01-18', 1, '2020-01-18', NULL, NULL, 1.00),
(413, 7, 18, 'CINTA ADHESIVA CRISTALINA PEGAFAN', 1.00, 1.20, 1.20, '12MM X 22.86M', 'TIENDA A 2 TIENDAS DEL TAMBO PALERMO', 'SABADO', '2020-01-18', 1, '2020-01-19', 1, '2020-01-19', 1.20),
(414, 16, 19, 'YESO PIEDRA (TIPO III) DENTAMIX', 1.00, 6.00, 6.00, 'PESO 1KG - LLAMADO CEMENTO AZUL(POR ELI)', 'TIENDA GALERIA JR. CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 6.00),
(415, 16, 18, 'CAJA LIDOCAINA 2% - NEWCAINA', 1.00, 55.00, 55.00, 'LIDOCAINA 2% CON EPINEFRINA 1:80.000 SOLUCION INYECTABLE - 50 CAPSULAS DE PLASTICO 1.8ML', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', 1, '2020-01-19', 18.00),
(416, 16, 18, 'RESINA LLIS EA2', 1.00, 25.00, 25.00, 'COMPOSITO NANOHIBRIDO PARA DIENTES ANTERIORES Y POSTERIORES - 1 GERINGA 4GR - TIEMPO FOTOPOLIMERIZADO 20S.', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(417, 16, 18, 'RESINA LLIS DA3', 1.00, 25.00, 25.00, 'COMPOSITO NANOHIBRIDO PARA DIENTES ANTERIORES Y POSTERIORES - 1 GERINGA 4G - TIEMPO FOTOPOLIMERIZADO 40S.', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(418, 16, 18, 'RESINA 3M Z100 RESTORATIVE - B2', 1.00, 40.00, 40.00, 'B2 SHADE - 4GR - 3M ESPE Z100 RESTORATIVE', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(419, 16, 18, 'ACRILICO DENTAL VITALLOY', 1.00, 2.00, 2.00, 'ACRILICO DENTAL CURADO RAPIDO 15GR - COLOR 59 CREMA(ELI)', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(420, 16, 18, 'ACRILICO VITACRON TRANSPARENTE ', 1.00, 2.00, 2.00, 'ACRILICO AUTOPOLIMERIZABLE POLVO 15GR - TONO TRANSPARENTE', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(421, 16, 18, 'KIT DE POSTES FIBRA DE VIDRIO Y 4 FRESAS', 1.00, 70.00, 70.00, 'FIBRAS DE CUARZO POSTES DE RESINA - 20 PIEZAS (S/.3.5) MAS 4 FRESAS', 'TIENDA PENULTIMA IZQUIERDA GALERIA JR CUSCO', 'SABADO', '2020-01-18', 1, '2020-01-19', NULL, NULL, 0.00),
(422, 8, 18, 'PASAJE BUS OLIVOS', 1.00, 2.50, 2.50, 'BUS COLOR BLANCO NARANJA CON CITAS AZULES', '', 'DOMINGO', '2020-01-19', 1, '2020-01-19', NULL, NULL, 2.50),
(423, 5, 18, 'PAN CON HUEVO', 2.00, 1.00, 2.00, '', 'OLIVOS', 'DOMINGO', '2020-01-19', 1, '2020-01-19', NULL, NULL, 2.00),
(424, 5, 18, 'SOYA', 1.00, 1.00, 1.00, '', 'LOS OLIVOS', 'DOMINGO', '2020-01-19', 1, '2020-01-19', NULL, NULL, 1.00),
(425, 8, 18, 'PASAJE BUS SOL DE ORO', 2.00, 2.00, 4.00, 'BUS COLOR NARANJA Y BLANCO PASAJE DESDE MEGA PLAZA - CANADA, PASAJE MIO Y DE CESAR', '', 'DOMINGO', '2020-01-19', 1, '2020-01-19', 1, '2020-01-20', 4.00),
(426, 11, 18, 'COPIA DNI Y CERT ESTUDIOS', 1.00, 0.30, 0.30, '0.2 DEL DNI Y 0.1 DE CERT ESTUDIOS', 'CRUZANDO PARINACOCHAS', 'DOMINGO', '2020-01-19', 1, '2020-01-19', NULL, NULL, 0.30),
(427, 5, 18, 'MARACUYA', 1.00, 1.00, 1.00, '2 MARACUYAS 1 PEQUEÑO Y OTRO GRANDE', 'CARRETA FRUTA Y VERDURA AL COSTADO DE CUARTO PALERMO', 'DOMINGO', '2020-01-19', 1, '2020-01-20', NULL, NULL, 1.00),
(428, 5, 18, 'PAN', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA A 2 CASAS DEL TAMBO PALERMO', 'DOMINGO', '2020-01-19', 1, '2020-01-20', NULL, NULL, 1.00),
(429, 5, 19, 'HUEVOS', 0.50, 5.00, 2.50, '8 HUEVOS GRANDES', 'TIENDA A 2 CASAS DE TAMBO PALERMO', 'DOMINGO', '2020-01-19', 1, '2020-01-20', NULL, NULL, 2.50),
(430, 3, 18, 'ALQUILER CUARTO FEBRERO', 1.00, 400.00, 400.00, 'PAGO ADELANTADO DE FEBRERO', 'PALERMO', 'DOMINGO', '2020-01-19', 1, '2020-01-20', 1, '2020-01-20', 400.00),
(431, 15, 18, 'COMISION CESAR', 1.00, 50.00, 50.00, '', '', 'DOMINGO', '2020-01-19', 1, '2020-01-20', NULL, NULL, 50.00),
(432, 8, 18, 'PASAJE BUS 23B', 1.00, 1.00, 1.00, '', '', 'LUNES', '2020-01-20', 1, '2020-01-20', NULL, NULL, 1.00),
(433, 8, 18, 'PASAJE BUS 23A', 2.00, 1.00, 2.00, '', '', 'LUNES', '2020-01-20', 1, '2020-01-21', NULL, NULL, 2.00),
(434, 5, 18, 'CENA CHIFA', 2.00, 10.00, 20.00, '', '', 'LUNES', '2020-01-20', 1, '2020-01-21', NULL, NULL, 20.00),
(435, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'LUNES', '2020-01-20', 1, '2020-01-21', NULL, NULL, 7.00),
(436, 5, 18, 'PAPEL HIGIENICO OFICINA', 1.00, 1.00, 1.00, '', '', 'LUNES', '2020-01-20', 1, '2020-01-21', NULL, NULL, 1.00),
(437, 8, 18, 'PASAJE TAXY FANING - PAIS', 1.00, 10.50, 10.50, '', '', 'MARTES', '2020-01-21', 1, '2020-01-22', NULL, NULL, 10.50),
(438, 5, 18, 'CENA BROSTER', 1.00, 5.00, 5.00, '', '', 'MARTES', '2020-01-21', 1, '2020-01-22', NULL, NULL, 5.00),
(439, 5, 18, 'PAN', 1.00, 1.00, 1.00, '4 PANES', '', 'MARTES', '2020-01-21', 1, '2020-01-22', NULL, NULL, 1.00),
(440, 8, 18, 'PASAJE BUS 23A PALERMO - LETICIA', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2020-01-22', 1, '2020-01-22', NULL, NULL, 1.00),
(441, 5, 18, 'PASAJE BUS 4515 ABANCAY - CAMPO DE MARTE', 1.00, 1.00, 1.00, 'BUS 4515 ABANCAY - CAMPO DE MARTE', '', 'MIERCOLES', '2020-01-22', 1, '2020-01-23', NULL, NULL, 1.00),
(442, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', '', 'MIERCOLES', '2020-01-22', 1, '2020-01-23', NULL, NULL, 8.00),
(443, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '9 MANDARINAS VERDES PEQUEÑITAS', 'CARRETA ESQUINA CUARTO PALERMO', 'MIERCOLES', '2020-01-22', 1, '2020-01-23', NULL, NULL, 2.00),
(444, 5, 18, 'ALMUERZO', 1.00, 2.00, 2.00, 'HUAYRA ME PRESTO 5 SOLES', '', 'JUEVES', '2020-01-23', 1, '2020-01-24', NULL, NULL, 2.00),
(445, 8, 18, 'PASAJE BUS 3511 52C ABANCAY - CAMPO DE MARTE', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2020-01-23', 1, '2020-01-24', 1, '2020-01-24', 1.00),
(446, 8, 18, 'PASAJE BUS MACHU PICCHU RUTA 7104', 1.00, 2.00, 2.00, 'PASAJE DE COLON - CANADA', '', 'VIERNES', '2020-01-24', 1, '2020-01-25', 1, '2020-01-25', 2.00),
(447, 8, 18, 'PASAJE COLECTIVO', 1.00, 1.00, 1.00, 'AV COLON', '', 'VIERNES', '2020-01-24', 1, '2020-01-25', NULL, NULL, 1.00),
(448, 5, 18, 'MARACUYA', 0.40, 3.50, 1.40, '2 MARACUYAS 1 MEDIANO Y 1 GRANDE', 'CARRETA ESQUINA CUARTO PALERMO', 'VIERNES', '2020-01-24', 1, '2020-01-25', NULL, NULL, 1.40),
(449, 8, 18, 'PASAJE BUS MACHU PICCHU', 1.00, 2.00, 2.00, 'PASAJE PALERMO - COLONIAL', '', 'SABADO', '2020-01-25', 1, '2020-01-25', NULL, NULL, 2.00),
(450, 5, 18, 'INCA COLA 1.5L', 1.00, 6.20, 6.20, '', 'TIENDA PALERMO', 'SABADO', '2020-01-25', 1, '2020-01-25', NULL, NULL, 6.20),
(451, 5, 18, 'MARCIANO LUCUMA', 1.00, 1.50, 1.50, '', '', 'SABADO', '2020-01-25', 1, '2020-01-25', NULL, NULL, 1.50),
(452, 5, 18, 'ALMUERZO', 1.00, 8.00, 8.00, '', 'GALERIA ELIO - CAL CASTRO', 'SABADO', '2020-01-25', 1, '2020-01-25', NULL, NULL, 8.00),
(453, 8, 18, 'PASAJE BUS MACHU PICCHU', 1.00, 2.00, 2.00, 'PASAJE COLONIAL - CANADA', '', 'SABADO', '2020-01-25', 1, '2020-01-25', NULL, NULL, 2.00),
(454, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '8 MANDARINAS', 'CARRETA ESQUINA CUARTO PALERMO', 'SABADO', '2020-01-25', 1, '2020-01-26', 1, '2020-01-26', 2.00),
(455, 8, 18, 'PASAJE BUS IM11', 1.00, 2.00, 2.00, 'PASAJE PALERMO - COLONIAL, BUS COLOR BLANCO CON 2 FRANJAS ROJAS Y UNA AZUL AL MEDIO', '', 'DOMINGO', '2020-01-26', 1, '2020-01-26', NULL, NULL, 2.00),
(456, 5, 18, 'VASO CHICHA MORADA', 1.00, 1.00, 1.00, '', 'COLEGIO EMBLEMATICO HIPOLITO UNANUE', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 1.00),
(457, 5, 18, 'BOTELLA CHICHA MORADA', 1.00, 1.00, 1.00, '', 'COLEGIO EMBLEMATICO HIPOLITO UNANUE', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 1.00),
(458, 5, 18, 'BOTELLA CHICHA MORADA', 1.00, 1.00, 1.00, '', 'COLEGIO EMBLEMATICO HIPOLITO UNANUE', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 1.00),
(459, 5, 18, 'PLATO ARROZ CON POLLO,CEBICHE Y CHAUFAINITA', 1.00, 8.00, 8.00, '', 'COLEGIO EMBLEMATICO HIPOLITO UNANUE', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 8.00),
(460, 5, 18, 'GASEOSA INKA COLA 625ML', 1.00, 2.50, 2.50, '', 'COLEGIO EMBLEMATICO HIPOLITO UNANUE', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 2.50),
(461, 9, 18, 'PASTILLA PANADOL ANTIGRIPAL', 1.00, 2.20, 2.20, '', 'CRUCE JIRON VICTOR SARRIA Y REYNALDO SAAVEDRA PIÑON', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 2.20),
(462, 5, 18, 'ROSQUITAS DE ANIS', 1.00, 1.30, 1.30, '', '', 'DOMINGO', '2020-01-26', 1, '2020-01-27', NULL, NULL, 1.30),
(463, 8, 18, 'PASAJE TAXY QUILCA - CANADA', 1.00, 8.00, 8.00, '', '', 'LUNES', '2020-01-27', 1, '2020-01-27', 1, '2020-01-28', 8.00),
(464, 5, 18, 'COCOA WINTERS', 1.00, 9.90, 9.90, '220GR', 'METRO JR. UNION', 'LUNES', '2020-01-27', 1, '2020-01-27', NULL, NULL, 9.90),
(465, 5, 18, 'BOLSA METRO', 1.00, 0.20, 0.20, '', 'METRO CANADA', 'LUNES', '2020-01-27', 1, '2020-01-27', NULL, NULL, 0.20),
(466, 9, 18, 'PASTILLA PANADOL', 1.00, 1.90, 1.90, 'PRECIO NORMAL 2.1 ', 'MI FARMA JR CUSCO', 'LUNES', '2020-01-27', 1, '2020-01-27', NULL, NULL, 1.90),
(467, 8, 18, 'PASAJE BUS 8105', 1.00, 1.00, 1.00, 'LA 5\nFONDO ROJO CON UN TRAZO AZUL', '', 'LUNES', '2020-01-27', 1, '2020-01-27', 1, '2020-01-28', 1.00),
(468, 8, 18, 'PASAJE BUS OM32 9V', 1.00, 2.00, 2.00, 'PASAJE LOS OLIVOS - HOSPITAL LOAYZA', 'UNIVERSIDAD CONTINENTAL', 'LUNES', '2020-01-27', 1, '2020-01-27', 1, '2020-01-28', 2.00),
(469, 9, 18, 'PASTILLA PANADOL', 1.00, 1.90, 1.90, 'PRECIO INICIAL 2.1', '', 'LUNES', '2020-01-27', 1, '2020-01-27', NULL, NULL, 1.90),
(470, 9, 18, 'PANADOL', 1.00, 2.20, 2.20, '', 'BOTICAS Y SALUD PALERMO', 'LUNES', '2020-01-27', 1, '2020-01-28', NULL, NULL, 2.20),
(471, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES CADA UNO 0.2', 'SEGUNDA TIENDA DE PANES PALERMO', 'LUNES', '2020-01-27', 1, '2020-01-28', NULL, NULL, 1.00),
(472, 5, 18, 'ALMUERZO', 2.00, 7.00, 14.00, 'ALMUERZO MIO Y DE HUAYRA', '', 'LUNES', '2020-01-27', 1, '2020-01-28', 1, '2020-01-28', 14.00),
(473, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'MARTES', '2020-01-28', 1, '2020-01-28', NULL, NULL, 1.00),
(474, 5, 18, 'FIDEO NICOLINI GRUESO', 2.00, 1.99, 3.98, 'TALLARIN GRUESO 500GR', 'TIENDA MAXIAHORRO IQUITOS', 'LUNES', '2020-01-27', 1, '2020-01-28', 1, '2020-01-29', 3.98),
(475, 5, 19, 'HUEVOS', 0.83, 4.50, 3.71, '', 'TIENDA MAXI AHORRO IQUITOS', 'LUNES', '2020-01-27', 1, '2020-01-28', 1, '2020-01-29', 3.71),
(476, 5, 18, 'ATUN GRATED DE SARDINA BELTRAN', 2.00, 2.20, 4.40, '170GR', 'TIENDA MAXI AHORRO IQUITOS', 'LUNES', '2020-01-27', 1, '2020-01-28', 1, '2020-01-29', 4.40),
(477, 9, 18, 'PASTILLA PANADOL', 1.00, 2.10, 2.10, '', 'MI FARMA JR CUSCO', 'MARTES', '2020-01-28', 1, '2020-01-28', NULL, NULL, 2.10),
(478, 5, 19, 'PALLARES MASS', 0.50, 9.80, 4.90, '', 'TIENDA MASS PALERMO', 'MARTES', '2020-01-28', 1, '2020-01-29', 1, '2020-01-29', 4.90),
(479, 5, 19, 'POLLO PIERNA PECHO', 0.62, 5.80, 3.60, '', 'PRIMERA TIENDA POLLO PALERMO', 'MARTES', '2020-01-28', 1, '2020-01-29', NULL, NULL, 3.60),
(480, 5, 18, 'ALMUERZO', 1.00, 5.00, 5.00, '', '', 'MARTES', '2020-01-28', 1, '2020-01-29', NULL, NULL, 5.00),
(481, 5, 18, 'PAN CHABATA', 1.00, 1.00, 1.00, '4 PANES', '', 'MIERCOLES', '2020-01-29', 1, '2020-01-30', 1, '2020-01-30', 1.00),
(482, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '10 MADARINAS', 'CARRETA ESQUINA CUARTO PALERMO', 'MIERCOLES', '2020-01-29', 1, '2020-01-30', NULL, NULL, 2.00),
(483, 5, 19, 'ARVEJA VERDE MERKAT', 0.50, 4.80, 2.40, '500GR', 'TIENDA MASS IQUITOS', 'MIERCOLES', '2020-01-29', 1, '2020-01-30', 1, '2020-01-30', 2.40),
(484, 5, 19, 'GARBANZO MERKAT', 0.50, 8.20, 4.10, '500GR', 'TIENDA MAXI AHORRO IQUITOS', 'MIERCOLES', '2020-01-29', 1, '2020-01-30', 1, '2020-02-19', 4.10),
(485, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'JUEVES', '2020-01-30', 1, '2020-01-31', NULL, NULL, 7.00),
(486, 5, 18, 'POLLO PECHO', 0.43, 7.00, 3.00, '2 PRESAS PECHO', 'CARRETA CUARTO PALERMO', 'JUEVES', '2020-01-30', 1, '2020-01-31', NULL, NULL, 3.00),
(487, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-01-31', 1, '2020-01-31', 1, '2020-01-31', 1.00),
(488, 5, 19, 'UVA VERDE', 1.00, 2.00, 2.00, '', 'CARRET ESQUINA CUARTO PALERMO', 'VIERNES', '2020-01-31', 1, '2020-02-01', NULL, NULL, 2.00),
(489, 5, 18, 'MARACUYA', 2.00, 0.50, 1.00, '', 'CARRETA ESQUINA CUARTO', 'VIERNES', '2020-01-31', 1, '2020-02-01', NULL, NULL, 1.00),
(490, 5, 19, 'PAPA HUAYRO', 0.76, 2.50, 1.90, '4 PAPAS MEDIANAS', 'CARRETA ESQUINA CUARTO PALERMO', 'DOMINGO', '2020-02-02', 1, '2020-02-03', 1, '2020-02-03', 1.90),
(491, 5, 18, 'CREMA HUANCAINA NICOLINI', 1.00, 7.50, 7.50, '390GR', 'TIENDA MAXI AHORRO IQUITOS', 'DOMINGO', '2020-02-02', 1, '2020-02-03', NULL, NULL, 7.50),
(492, 5, 18, 'FREJOL PANAMITO MERKAT', 1.00, 4.00, 4.00, 'PRECIO 3.99 - 500GR', 'TIENDA MAXI AHORRO IQUITOS', 'DOMINGO', '2020-02-02', 1, '2020-02-03', NULL, NULL, 4.00),
(493, 5, 18, 'HUEVOS GRANEL', 0.68, 4.40, 3.00, '0.69 KG', 'MAXI AHORRO IQUITOS', 'DOMINGO', '2020-02-02', 1, '2020-02-03', NULL, NULL, 3.00),
(494, 5, 18, 'BOLSA PLASTICA', 1.00, 0.20, 0.20, '', 'MAXI AHORRO IQUITOS', 'DOMINGO', '2020-02-02', 1, '2020-02-03', NULL, NULL, 0.20),
(495, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '9 MANDARINAS', 'CARRETA ESQUINA CUARTO PALERMO', 'LUNES', '2020-02-03', 1, '2020-02-04', NULL, NULL, 2.00),
(496, 5, 19, 'POLLO PECHO', 0.76, 7.50, 5.70, '2 PRESAS PECHO', 'CARRETA ESQUINA CUARTO PALERMO', 'LUNES', '2020-02-03', 1, '2020-02-04', 1, '2020-02-04', 5.70),
(497, 17, 18, 'APORTE DESPEDIDA', 1.00, 5.00, 5.00, '', '', 'LUNES', '2020-02-03', 1, '2020-02-04', NULL, NULL, 5.00),
(498, 8, 18, 'PASAJE BUS 23B', 1.00, 1.00, 1.00, '', '', 'MARTES', '2020-02-04', 1, '2020-02-04', NULL, NULL, 1.00),
(499, 8, 18, 'PASAJE BUS 52C', 1.00, 1.00, 1.00, 'ABANCAY - CAMPO DE MARTE', '', 'MARTES', '2020-02-04', 1, '2020-02-05', 1, '2020-02-06', 1.00),
(500, 17, 18, 'APORTE ADAPTADOR HERVIDORA OFICINA', 1.00, 1.00, 1.00, '', '', 'MARTES', '2020-02-04', 1, '2020-02-05', 1, '2020-02-05', 1.00),
(501, 5, 18, 'GRANADILLA', 1.00, 2.00, 2.00, '10 GRANADILLAS POR 2 SOLES', 'TRICICLO', 'MARTES', '2020-02-04', 1, '2020-02-05', NULL, NULL, 2.00),
(502, 5, 19, 'MARACUYA', 0.37, 3.50, 1.30, '2 MARACUYAS GRANDES', 'TIENDA DE FRUTA EN MEDIO DE AV PALERMO', 'MARTES', '2020-02-04', 1, '2020-02-05', NULL, NULL, 1.30),
(503, 5, 18, 'PAN CHABATA', 1.00, 1.00, 1.00, '4 PANES', 'PRIMRA TIENDA DE PAN PALERMO', 'MARTES', '2020-02-04', 1, '2020-02-05', NULL, NULL, 1.00),
(504, 8, 18, 'PASAJE BUS 8516', 1.00, 3.00, 3.00, 'IQUITOS - PANTANOS VILLA', '', 'MIERCOLES', '2020-02-05', 1, '2020-02-05', NULL, NULL, 3.00),
(505, 8, 18, 'PASAJE BUS 8516', 1.00, 3.00, 3.00, 'CIENTIFICA - ABANCAY', '', 'MIERCOLES', '2020-02-05', 1, '2020-02-05', NULL, NULL, 3.00),
(506, 5, 19, 'POLLO', 0.46, 7.00, 3.20, '2 PRESAS DE PECHO PEQUEÑAS', 'TIENDA DE POLLO Y FRUTA AL COSTADO MERCADO PALERMO', 'MIERCOLES', '2020-02-05', 1, '2020-02-06', 1, '2020-02-06', 3.20),
(507, 5, 19, 'PALLARES MASS', 0.50, 9.80, 4.90, '500GR', 'TIENDA MASS PALERMO', 'MIERCOLES', '2020-02-05', 1, '2020-02-06', NULL, NULL, 4.90),
(508, 5, 19, 'ARVEJA VERDE PARTIDA BELLS', 0.50, 4.60, 2.30, '500GR', 'TIENDA MASS PALERMO', 'MIERCOLES', '2020-02-05', 1, '2020-02-06', NULL, NULL, 2.30),
(509, 5, 18, 'BOLSA MASS', 1.00, 0.10, 0.10, '', 'TIENDA MASS PALERMO', 'MIERCOLES', '2020-02-05', 1, '2020-02-06', NULL, NULL, 0.10),
(510, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, 'PALERMO - LETICIA', '', 'VIERNES', '2020-02-07', 1, '2020-02-08', NULL, NULL, 1.00),
(511, 5, 19, 'MANGO', 0.75, 4.00, 3.00, '', 'TIENDA FRUTA EN CASA A MITAD DE PALERMO', 'VIERNES', '2020-02-07', 1, '2020-02-08', NULL, NULL, 3.00),
(512, 8, 18, 'PASAJE BUS 8516', 1.00, 2.50, 2.50, 'IQUITOS - VILLA PANTANOS', '', 'SABADO', '2020-02-08', 1, '2020-02-08', NULL, NULL, 2.50),
(513, 8, 18, 'PASAJE BUS 8516', 1.00, 3.00, 3.00, 'CIENTIFICA - JAVIER PRADO', '', 'SABADO', '2020-02-08', 1, '2020-02-08', NULL, NULL, 3.00),
(514, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, 'PALERMO - LETICIA', '', 'SABADO', '2020-02-08', 1, '2020-02-08', NULL, NULL, 1.00),
(515, 12, 18, 'MEDIAS ADIDAS', 1.00, 5.00, 5.00, '', 'GALERIAS AV. GRAU', 'SABADO', '2020-02-08', 1, '2020-02-08', 1, '2020-02-09', 5.00),
(516, 5, 18, 'GRANADILLA', 1.00, 1.00, 1.00, '6 GRANADILLA', 'TRICICLO AV. GRAU', 'SABADO', '2020-02-08', 1, '2020-02-08', NULL, NULL, 1.00),
(517, 5, 18, 'AJO', 1.00, 1.00, 1.00, '1 BOLA DE VARIOS AJOS (A LA SIGUIENTE SELECCIONAR EL MAS GRANDE)', 'MERCADO PALERMO', 'SABADO', '2020-02-08', 1, '2020-02-08', NULL, NULL, 1.00),
(518, 8, 18, 'PASAJE BUS 8516', 1.00, 2.00, 2.00, 'PROLONG. IQUITOS - CHORILLOS', '', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 2.00),
(519, 5, 18, 'BOLSA MAXI AHORRO', 2.00, 0.10, 0.20, 'BIODEGRADABLE', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 0.20),
(520, 5, 18, 'MAIZ MORADO', 0.56, 2.49, 1.39, '4 CCORONTAS MEDIANAS', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 1.39),
(521, 5, 22, 'ARROZ COSTEÑO AZUL', 1.00, 17.49, 17.49, '5KG', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 17.49),
(522, 5, 19, 'HUEVOS A GRANEL', 0.64, 4.60, 2.92, '10 HUEVOS ', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 2.92),
(523, 8, 18, 'PASAJE BUS 8516', 1.00, 2.00, 2.00, 'CHORILLOS - PROLONG. IQUITOS', '', 'DOMINGO', '2020-02-09', 1, '2020-02-09', 1, '2020-02-10', 2.00),
(524, 5, 18, 'ALMUERZO', 1.00, 4.00, 4.00, '', '', 'DOMINGO', '2020-02-09', 1, '2020-02-09', NULL, NULL, 4.00),
(525, 5, 19, 'ARVEJA VERDE MERKAT', 0.50, 4.80, 2.40, '500GR', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 2.40),
(526, 5, 18, 'BOLSA BIODEGRADABL', 1.00, 0.10, 0.10, 'BIODEGRADABLE', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 0.10),
(527, 5, 19, 'POLLO ESPINAZO', 0.67, 4.49, 3.00, 'TRES PRESAS', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 3.00),
(528, 5, 19, 'GARBANZO MERKAT', 0.50, 8.40, 4.20, '500GR', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 4.20),
(529, 5, 18, 'FREJOL CASTILLA MERKAT', 0.50, 10.40, 5.20, '500GR', 'MAXI AHORRO PROLONG. IQUITOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 5.20),
(530, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES MUY PEQUEÑO, NO VOLVERA IR AHI', 'TIENDA PRIMERA DE PAN', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 1.00),
(531, 5, 18, 'BOTELLA CHICHA DE MARACUYA', 1.00, 1.00, 1.00, '', 'CANCHA DE FUTBOL A 6 CUADRAS DE PANTANOS', 'DOMINGO', '2020-02-09', 1, '2020-02-10', NULL, NULL, 1.00),
(532, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'LUNES', '2020-02-10', 1, '2020-02-10', NULL, NULL, 1.00),
(533, 5, 19, 'CIRUELA', 0.58, 6.00, 3.50, '8 CIRUELAS', 'TIENDA DE FRUTA AL COSTADO DE INKAFARMA PALERMO', 'MARTES', '2020-02-11', 1, '2020-02-12', NULL, NULL, 3.50),
(534, 5, 19, 'POLLO', 0.43, 7.00, 3.00, '2 PIERNAS', 'TIENDA DE POLLO AL COSTADO DE INKAFARMA PALERMO', 'MARTES', '2020-02-11', 1, '2020-02-12', NULL, NULL, 3.00),
(535, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA DE PAN DEL MEDIO', 'JUEVES', '2020-02-13', 1, '2020-02-14', NULL, NULL, 1.00),
(536, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '11 MANDARINAS ', 'CARRETA ESQUINA CUARTO PALERMO', 'JUEVES', '2020-02-13', 1, '2020-02-14', NULL, NULL, 2.00),
(537, 5, 18, 'CENA', 2.00, 10.00, 20.00, '', '', 'JUEVES', '2020-02-13', 1, '2020-02-15', 1, '2020-02-15', 20.00),
(538, 5, 18, 'ALMUERZO', 1.00, 7.00, 7.00, '', '', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 7.00),
(539, 23, 18, 'PRESTAMO YONNY', 1.00, 200.00, 200.00, '', '', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 200.00),
(540, 17, 18, 'BOLSA NEGRA', 1.00, 0.30, 0.30, '', 'JR. CUSCO 177', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.30),
(541, 16, 19, 'YESO PIEDRA DENTAMIX', 3.00, 6.00, 18.00, 'CEMENTO AZUL 1KG', 'TIENDA DE EN MEDIO A LA DERECHA DE LA GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.00),
(542, 16, 18, 'HUANTES TALLA S', 3.00, 10.00, 30.00, '', 'TIENDA DE EN MEDIO A LA DERECHA DE LA GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', 1, '2020-02-15', 0.00),
(543, 16, 18, 'ALGINATO', 1.00, 14.00, 14.00, 'BOLSA DE FORRO MORADO', 'TIENDA DE EN MEDIO A LA DERECHA DE GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.00),
(544, 16, 18, 'PROTOPLAST CEMENTO DE POLICARBOXILATO', 1.00, 22.00, 22.00, 'BOTELLITA', 'TIENDA DE EN MEDIO A LA DERECHA DE LA GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', 1, '2020-02-15', 0.00),
(545, 16, 18, 'EUGENOL', 1.00, 7.00, 7.00, 'CAJITA CON 2 BOTELLITAS ADENTRO', 'TIENDA DE EN MEDIO A LA DERECHA DE LA GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.00),
(546, 16, 18, 'CONOS GUTAPERCHA 1RA Y 2DA GENERACION', 2.00, 13.00, 26.00, 'CAJITAS CON PALITOS NARANJA, UNA DE 1RA GEN Y OTRA DE 2DA GEN', 'TIENDA DE EN MEDIO A LA DERECHA DE GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.00),
(547, 16, 18, 'CONOS DE PAPEL', 1.00, 12.00, 12.00, 'PUNTOS DE PAPEL 1RA GENERACION (CAJITA CON PALITOS BLANCOS)', 'TIENDA DE EN MEDIO A LA DERECHA DE GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', 1, '2020-02-15', 0.00),
(548, 16, 18, 'PLACA RADIOGRAFICA COLOR AZUL', 1.00, 120.00, 120.00, 'COLOR AZUL, HAY OTRO COLOR CELESTE Y MAS CARO', 'TIENDA DE EN MEDIO A LA DERECHA DE GALERIA', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 0.00),
(549, 13, 18, 'PASAJE AYACUCHO BUS CARMEN ALTO', 1.00, 40.00, 40.00, 'LIMA - AYACUCHO', '', 'VIERNES', '2020-02-14', 1, '2020-02-15', 1, '2020-02-15', 40.00),
(550, 8, 18, 'PASAJE BUS 23B', 1.00, 1.00, 1.00, 'PALERMO - PLAZA MANCO CAPAC', '', 'VIERNES', '2020-02-14', 1, '2020-02-15', NULL, NULL, 1.00),
(551, 5, 18, 'HELADOS DE CREMA', 3.00, 1.00, 3.00, '', 'PARQUE BELLIDO', 'SABADO', '2020-02-15', 1, '2020-02-15', NULL, NULL, 3.00),
(552, 23, 18, 'PRESTAMO URBAY', 1.00, 500.00, 500.00, 'PRESTAMO URBAY', '', 'MIERCOLES', '2020-02-12', 1, '2020-02-15', 1, '2020-02-15', 500.00),
(553, 15, 18, 'GASTOS PAPA', 1.00, 2500.00, 2500.00, 'GASTOS PAPA Y MAMA', '', 'SABADO', '2020-02-15', 1, '2020-02-15', NULL, NULL, 2500.00),
(554, 15, 18, 'COMPLEMENTO MATRICULA KEVIN', 1.00, 80.00, 80.00, '', '', 'SABADO', '2020-02-15', 1, '2020-02-15', 1, '2020-02-17', 80.00),
(555, 8, 18, 'PASAJE RUTA8', 3.00, 0.70, 2.10, 'MOLLEPATA - JR. 9 DE DICIEMBRE', '', 'SABADO', '2020-02-15', 1, '2020-02-15', 1, '2020-02-15', 2.10),
(556, 8, 18, 'PASAJE RUTA8', 3.00, 0.67, 2.00, 'PUENTE ENACE - MAGDALENA', '', 'SABADO', '2020-02-15', 1, '2020-02-15', NULL, NULL, 2.00),
(557, 5, 18, 'REFRESCO', 3.00, 1.00, 3.00, '', 'RESIDENCIA', 'SABADO', '2020-02-15', 1, '2020-02-15', NULL, NULL, 3.00),
(558, 12, 18, 'TINTA PARA TEÑIR ROPA MARRON', 1.00, 3.50, 3.50, '', 'MERCADO MAGDALENA', 'DOMINGO', '2020-02-16', 1, '2020-02-16', 1, '2020-02-17', 3.50),
(559, 5, 18, 'GASEOSA KOLA REAL', 1.00, 10.00, 10.00, 'PROPINA KEVIN', '', 'SABADO', '2020-02-15', 1, '2020-02-17', 1, '2020-02-17', 10.00),
(560, 15, 18, 'PROPINA CESAR', 1.00, 100.00, 100.00, '', '', 'DOMINGO', '2020-02-16', 1, '2020-02-17', NULL, NULL, 100.00),
(561, 15, 18, 'PROPINA CINTHIA', 1.00, 50.00, 50.00, '', '', 'DOMINGO', '2020-02-16', 1, '2020-02-17', NULL, NULL, 50.00),
(562, 5, 18, 'PROPINA KEVIN', 1.00, 5.00, 5.00, '', '', 'DOMINGO', '2020-02-16', 1, '2020-02-17', NULL, NULL, 5.00),
(563, 8, 18, 'PASAJE SEDEPA - TERMINAL', 1.00, 1.00, 1.00, '', '', 'DOMINGO', '2020-02-16', 1, '2020-02-17', NULL, NULL, 1.00),
(564, 8, 18, 'TASA DE EMBARQUE', 1.00, 1.50, 1.50, '', 'TERMINAL AYACUCHO', 'DOMINGO', '2020-02-16', 1, '2020-02-17', NULL, NULL, 1.50),
(565, 5, 18, 'PASAJE RUTA 21', 1.00, 1.00, 1.00, 'TERMINAL - SEDEPA', '', 'SABADO', '2020-02-15', 1, '2020-02-17', 1, '2020-02-17', 1.00),
(566, 17, 18, 'CARIDAD VIEJITA', 1.00, 0.20, 0.20, '', 'JR. 9 DE DICIEMBRE', 'SABADO', '2020-02-15', 1, '2020-02-17', NULL, NULL, 0.20),
(567, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, 'MANCO CAPAC - PALERMO', '', 'LUNES', '2020-02-17', 1, '2020-02-17', NULL, NULL, 1.00),
(568, 8, 18, 'PASAJE BUS 23B', 1.00, 1.00, 1.00, 'PALERMO - MANCO CAPAC', '', 'LUNES', '2020-02-17', 1, '2020-02-17', NULL, NULL, 1.00),
(569, 5, 19, 'POLLO', 0.43, 7.00, 3.00, '', 'TIENDA DE POLLO AL MEDIO DE AV. PALERMO', 'LUNES', '2020-02-17', 1, '2020-02-18', NULL, NULL, 3.00),
(570, 5, 19, 'ZANAHORIA', 0.15, 4.00, 0.60, '', 'CARRETA DE VERDURAS PALERMO', 'LUNES', '2020-02-17', 1, '2020-02-18', 1, '2020-02-18', 0.60),
(571, 4, 18, 'PAGO BITEL FEBRERO', 1.00, 29.90, 29.90, '', '', 'LUNES', '2020-02-17', 1, '2020-02-18', NULL, NULL, 29.90),
(572, 5, 18, 'PLATANO', 1.00, 1.00, 1.00, '7 PLATANOS', 'AV. REP PANAMA', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 1.00),
(573, 5, 19, 'AZUCAR RUBIA', 0.98, 2.40, 2.35, 'AZUCAR DE COSTAL', 'MASS PALERMO', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 2.35),
(574, 6, 18, 'COLGATE HERBAL', 1.00, 2.50, 2.50, '', 'MASS PALERMO', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 2.50),
(575, 5, 19, 'LENTEJA BEBE BELLS', 0.50, 6.00, 3.00, '', 'MASS PALERMO', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 3.00),
(576, 5, 19, 'HUEVO GRANEL', 0.59, 4.50, 2.65, '8 HUEVOS', 'MASS PALERMO', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 2.65),
(577, 17, 18, 'CAMBIO DE TARJETA INTERBAK', 1.00, 20.00, 20.00, '', 'INTERBANK JR. 9 DE DICIEMBRE', 'LUNES', '2020-02-17', 1, '2020-02-19', 1, '2020-02-19', 20.00),
(578, 5, 18, 'MARACUYA', 2.00, 0.40, 0.80, '', 'CARRETA CUARTO PALERMO', 'MARTES', '2020-02-18', 1, '2020-02-19', NULL, NULL, 0.80),
(579, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA MEDIO AV PALERMO', 'MIERCOLES', '2020-02-19', 1, '2020-02-20', NULL, NULL, 1.00),
(580, 5, 19, 'POLLO PIERNA ANTEPIERNA', 0.64, 7.00, 4.50, 'PIERNA Y ANTEPIERNA', 'TIENDA POLLO EN MEDIO PALERMO', 'MIERCOLES', '2020-02-19', 1, '2020-02-20', NULL, NULL, 4.50),
(581, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '9 MANDARINAS', 'CARRETA FRUTAS PALERMO', 'MIERCOLES', '2020-02-19', 1, '2020-02-20', NULL, NULL, 2.00),
(582, 5, 19, 'ZANAHORIA', 0.52, 2.50, 1.30, '5 ZANAHORIAS', 'CARRETA VERDURAS PALERMO', 'MIERCOLES', '2020-02-19', 1, '2020-02-20', NULL, NULL, 1.30),
(583, 3, 18, 'ALQUILER CUARTO FEBRERO', 1.00, 400.00, 400.00, 'SE PAGO EN EL CUARTO PISO', '', 'MIERCOLES', '2020-02-19', 1, '2020-02-20', NULL, NULL, 400.00),
(584, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2020-02-20', 1, '2020-02-20', NULL, NULL, 1.00),
(585, 5, 19, 'POLLO MITAD DE PECHO', 0.43, 7.00, 3.00, '', 'TIENDA DE POLLO PALERMO', 'JUEVES', '2020-02-20', 1, '2020-02-21', NULL, NULL, 3.00),
(586, 5, 19, 'MANDARINA', 1.00, 4.00, 4.00, '', 'CARRETA PALERMO', 'JUEVES', '2020-02-20', 1, '2020-02-21', NULL, NULL, 4.00),
(587, 5, 19, 'PALLAR MERKAT', 0.50, 11.00, 5.50, '', 'MAXI AHORRO IQUITOS', 'JUEVES', '2020-02-20', 1, '2020-02-21', 1, '2020-02-21', 5.50),
(588, 5, 19, 'GARBANZO MERKAT', 0.50, 8.40, 4.20, '', 'MAXI AHORRO AV. IQUITOS', 'JUEVES', '2020-02-20', 1, '2020-02-21', NULL, NULL, 4.20),
(589, 15, 18, 'GASTOS CESAR', 1.00, 100.00, 100.00, '', '', 'VIERNES', '2020-02-21', 1, '2020-02-21', NULL, NULL, 100.00),
(590, 5, 18, 'CENA', 2.00, 10.00, 20.00, '', 'PLAZA MANCO CAPAC', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 20.00),
(591, 5, 18, 'MARACUYA', 0.68, 2.50, 1.70, '', 'CARRETA PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 1.70),
(592, 5, 19, 'PALLAR', 1.00, 7.00, 7.00, '', 'PENULTIMA TIENDA AL FONDO PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 7.00),
(593, 5, 19, 'GARBANZO', 1.00, 7.00, 7.00, '', 'PENULTIMA TIENDA AL FONDO PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 7.00),
(594, 5, 19, 'FREJOL CASTILLA', 1.00, 6.00, 6.00, '', 'PENULTIMA TIENDA AL FONDO PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 6.00),
(595, 6, 18, 'CORTE DE CABELLO Y ONDULADO', 1.00, 30.00, 30.00, '', 'PELUQUERIA PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-22', NULL, NULL, 30.00),
(596, 5, 18, 'COSTURA DE PANTALON VESTIR', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-02-22', 1, '2020-02-23', NULL, NULL, 8.00),
(597, 5, 18, 'MARCIANO', 2.00, 1.00, 2.00, '', 'GAMARRA', 'DOMINGO', '2020-02-23', 1, '2020-02-27', 1, '2020-02-27', 2.00),
(598, 7, 18, 'SILLA PLEGABLE', 1.00, 25.00, 25.00, 'REBAJA DE PRECIO 27', 'GAMARRA', 'DOMINGO', '2020-02-23', 1, '2020-02-27', 1, '2020-02-27', 25.00),
(599, 5, 19, 'HUEVO', 0.50, 5.60, 2.80, '', 'MERCADO PALERMO', 'DOMINGO', '2020-02-23', 1, '2020-02-27', 1, '2020-02-27', 2.80),
(600, 5, 19, 'POLLO', 0.54, 7.00, 3.80, 'PIERNA Y PECHO', 'MERCANO EN MEDIO AVENIDA PALERMO', 'DOMINGO', '2020-02-23', 1, '2020-02-27', 1, '2020-02-27', 3.80),
(601, 5, 19, 'POLLO', 0.50, 7.00, 3.50, 'PECHO Y PIERNA', 'TIENDA EN MEDIO PALERMO', 'LUNES', '2020-02-24', 1, '2020-02-27', NULL, NULL, 3.50),
(602, 5, 19, 'POLLO', 0.47, 7.00, 3.30, '2 PIERNAS', 'MERCADO EN MEDIO PALERMO', 'MARTES', '2020-02-25', 1, '2020-02-27', NULL, NULL, 3.30),
(603, 5, 18, 'GRANADILLA', 1.00, 2.00, 2.00, '10 GRANADILLAS', 'AV. ABANCAY', 'MARTES', '2020-02-25', 1, '2020-02-27', NULL, NULL, 2.00),
(604, 5, 18, 'PAN', 1.00, 1.00, 1.00, '4 PANES VACHATA', 'TIENDA EN MEDIO PALERMO PAN', 'MARTES', '2020-02-25', 1, '2020-02-27', NULL, NULL, 1.00),
(605, 5, 19, 'AJO', 0.17, 13.00, 2.20, '2 BOLAS GRANDES DE AJOS', 'MERCADO PALERMO', 'MARTES', '2020-02-25', 1, '2020-02-27', 1, '2020-02-27', 2.20),
(606, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'MIERCOLES', '2020-02-26', 1, '2020-02-27', NULL, NULL, 1.00),
(607, 17, 18, 'PARTIDO', 1.00, 7.00, 7.00, '', '', 'MIERCOLES', '2020-02-26', 1, '2020-02-27', NULL, NULL, 7.00),
(608, 5, 19, 'POLLO', 0.64, 7.00, 4.50, 'UNA PIERNA Y PECHO GRANDE', 'TIENDA EN MEDIO PALERMO', 'MIERCOLES', '2020-02-26', 1, '2020-02-27', NULL, NULL, 4.50),
(610, 5, 19, 'HUEVO', 0.72, 4.30, 3.10, '', 'TIENDA MASS PALERMO', 'MIERCOLES', '2020-02-26', 1, '2020-02-27', NULL, NULL, 3.10),
(611, 5, 18, 'PAN', 1.00, 1.00, 1.00, '5 PANES FRANCES', 'TIENDA EN MEDIO PALERMO', 'MIERCOLES', '2020-02-26', 1, '2020-02-27', NULL, NULL, 1.00),
(612, 5, 19, 'POLLO', 0.32, 9.00, 2.90, '2 PIERNAS', 'TIENDA COSTADO MERCADILLO PALERMO', 'JUEVES', '2020-02-27', 1, '2020-02-28', 1, '2020-02-28', 2.90),
(613, 15, 18, 'PASAJE CESAR', 1.00, 5.00, 5.00, '', '', 'JUEVES', '2020-02-27', 1, '2020-02-28', NULL, NULL, 5.00),
(614, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'LUNES', '2020-02-24', 1, '2020-02-28', NULL, NULL, 1.00),
(615, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-02-28', 1, '2020-02-28', NULL, NULL, 1.00),
(616, 8, 18, 'PASAJE BUS 23B', 2.00, 1.00, 2.00, '', '', 'SABADO', '2020-02-29', 1, '2020-02-29', NULL, NULL, 2.00),
(617, 5, 18, 'BUFFET KASAMAMA', 2.00, 31.80, 63.60, '', 'PLAZA SAN MARTIN', 'SABADO', '2020-02-29', 1, '2020-03-01', 1, '2020-03-01', 63.60),
(618, 5, 19, 'PESCADO JUREL', 1.25, 6.00, 7.50, '', 'MERCADO PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 7.50),
(619, 5, 19, 'LENTEJA', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO TIENDA FONDO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 6.00),
(620, 5, 18, 'BOLSA BLANCA', 1.00, 0.20, 0.20, '', 'TIENDA A FONDO MERCADO PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 0.20),
(621, 5, 18, 'MAYONESA', 1.00, 5.20, 5.20, '190GR', 'MERCADO PALERMO TIENDA FONDO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 5.20),
(622, 5, 18, 'AJI COLORADO PREPARADO', 1.00, 0.50, 0.50, '', 'MERCADO PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 0.50),
(623, 7, 18, 'PAPEL ALUMINIO', 1.00, 1.00, 1.00, '1METRO', 'MERCADO PALERMO CANADA', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 1.00),
(624, 5, 21, 'ACEITE IDEAL', 1.00, 3.80, 3.80, '500ML', 'TIENDA FRENTE MERCADO PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-01', NULL, NULL, 3.80),
(625, 6, 18, 'PAPEL HIGIENICO BOREAL', 1.00, 13.50, 13.50, '', 'MASS PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-02', NULL, NULL, 13.50),
(626, 5, 18, 'PAN', 1.00, 1.00, 1.00, '', 'TIENDA PAN PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-02', NULL, NULL, 1.00),
(627, 5, 18, 'BOLSA BLANCA', 1.00, 0.10, 0.10, '', 'TIENDA FRENTE MERCADO PALERMO', 'DOMINGO', '2020-03-01', 1, '2020-03-02', NULL, NULL, 0.10),
(628, 5, 19, 'POLLO PIERNA PECHO', 0.43, 7.00, 3.00, '', 'TIENDA POLLO EN MEDIO PALERMO', 'LUNES', '2020-03-02', 1, '2020-03-04', 1, '2020-03-04', 3.00),
(629, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '', 'CARRETA ESQUINA CUARTO', 'LUNES', '2020-03-02', 1, '2020-03-04', 1, '2020-03-04', 2.00),
(630, 5, 19, 'POLLO 2 PIERNAS', 0.41, 7.00, 2.90, '', 'TIENDA COSTADO MERCADILLO PALERMO', 'MARTES', '2020-03-03', 1, '2020-03-04', NULL, NULL, 2.90),
(631, 5, 22, 'MANZANA CHILENA VERDE', 1.00, 2.00, 2.00, '10 MANZANAS', 'AV. REP PANAMA', 'MARTES', '2020-03-03', 1, '2020-03-04', NULL, NULL, 2.00),
(632, 5, 18, 'FIDEOS BELLS', 2.00, 1.40, 2.80, '', 'MASS PALERMO', 'MARTES', '2020-03-03', 1, '2020-03-04', NULL, NULL, 2.80),
(633, 5, 19, 'POLLO 2 PECHITOS', 0.61, 8.00, 4.90, '2 PECHOS', 'TIENDA COSTADO MERCADILLO PALERMO', 'MIERCOLES', '2020-03-04', 1, '2020-03-05', NULL, NULL, 4.90),
(634, 5, 22, 'GALLETA SODA SAN JORGE', 2.00, 1.50, 3.00, '', 'CARRETA CANADA Y METROPOLITANO', 'MIERCOLES', '2020-03-04', 1, '2020-03-05', NULL, NULL, 3.00),
(635, 5, 19, 'POLLO 2 PIERNAS', 0.40, 9.00, 3.60, '2 PIERNAS', 'TIENDA POLLO COSTADO MERCADILLO PALERMO', 'JUEVES', '2020-03-05', 1, '2020-03-06', NULL, NULL, 3.60),
(636, 5, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-03-06', 1, '2020-03-06', NULL, NULL, 1.00),
(637, 5, 18, 'MANDARINA', 1.00, 1.00, 1.00, '11 MADARINAS', 'TRICICLO AV. GRAU', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 1.00),
(638, 5, 19, 'ARROZ GRANEL', 1.58, 2.60, 4.10, '', 'MAXIAHORRO AV. PROL. IQUITOS', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 4.10),
(639, 5, 18, 'TARI SALSA DE AJI', 1.00, 9.99, 9.99, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 9.99),
(640, 5, 18, 'MAYONESA WALIBI', 1.00, 2.56, 2.56, 'PRECIO NORMAL 3.2\n200GR', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 2.56),
(641, 5, 19, 'AZUCAR RUBIA GRANEL', 1.11, 2.99, 3.33, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 3.33),
(642, 5, 19, 'HUEVOS A GRANEL', 0.60, 5.50, 3.32, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-06', 1, '2020-03-07', NULL, NULL, 3.32),
(643, 4, 18, 'PAGO BITEL ADELANTADO ABRIL', 1.00, 29.90, 29.90, '', '', 'DOMINGO', '2020-03-08', 1, '2020-03-08', 1, '2020-03-09', 29.90),
(644, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA COSTADO TAMBO', 'DOMINGO', '2020-03-08', 1, '2020-03-09', NULL, NULL, 1.00),
(645, 9, 18, 'PANADOL ANTIGRIPAL', 1.00, 2.10, 2.10, '', 'MIFARMA JR CUSCO', 'LUNES', '2020-03-09', 1, '2020-03-09', NULL, NULL, 2.10),
(646, 9, 18, 'PANADOL ANTIGRIPAL', 1.00, 2.20, 2.20, '', 'BOTICAS Y SALUD PALERMO', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 2.20),
(647, 5, 19, 'UVA ROSADA', 0.50, 5.00, 2.50, '', 'CARRETA CUARTO PALERMO', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 2.50),
(648, 5, 18, 'AJONOMOTO SOBRE 100G', 1.00, 1.60, 1.60, '100GR', 'MAXI AHORRO IQUITOS', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 1.60),
(649, 5, 21, 'ACEITE MERKAT', 1.00, 3.79, 3.78, 'VEGETAL', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 3.78),
(650, 5, 18, 'FILETE DE ATUN MERKAT', 2.00, 3.49, 6.98, 'EN ACEITE VEGETAL', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 6.98),
(651, 5, 19, 'POLLO PIERNA ENCUENTRO', 0.48, 5.99, 2.87, '', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 2.87),
(652, 5, 19, 'HUEVOS GRANEL', 0.65, 5.50, 3.57, '', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-09', 1, '2020-03-10', NULL, NULL, 3.57),
(653, 5, 18, 'PASAJE BUS23A', 1.00, 1.00, 1.00, '', '', 'MARTES', '2020-03-10', 1, '2020-03-10', NULL, NULL, 1.00),
(654, 5, 19, 'POLLO PIERNA', 0.37, 5.99, 2.20, '', 'MAXI AHORRO IQUITOS', 'MARTES', '2020-03-10', 1, '2020-03-11', NULL, NULL, 2.20),
(655, 5, 18, 'COCOA DP WINTERS', 1.00, 6.60, 6.60, 'COCOA EN BOLSA', 'METRO JR. CUSCO', 'MIERCOLES', '2020-03-11', 1, '2020-03-11', NULL, NULL, 6.60),
(656, 16, 18, 'MASCARILLA BIODEGRADABLE GOLD GUARD', 1.00, 35.00, 35.00, '50 MASCARILLAS BIODEGRADABLE', 'JR. CUSCO', 'MIERCOLES', '2020-03-11', 1, '2020-03-12', NULL, NULL, 35.00),
(657, 16, 18, 'KIT RESINA LLIS', 1.00, 150.00, 150.00, 'TONALIDADES EA1,EA2,EA3,EA4 Y CONDOC 37', 'TIENDA FONDO GALERIA', 'MIERCOLES', '2020-03-11', 1, '2020-03-12', NULL, NULL, 150.00),
(658, 16, 18, 'AGUJAS DENTALES TOPJECT', 2.00, 20.00, 40.00, '100 PZS, LARGO 30MM CALIBRE 27G (0.4 MM), CORTO 21MM CALIBRE 30G (0.3 MM)', 'TIENDA FONDO GALERIA', 'MIERCOLES', '2020-03-11', 1, '2020-03-12', NULL, NULL, 40.00),
(659, 5, 18, 'PANADOL ANTIGRIPAL', 1.00, 1.90, 1.90, 'PRECIO NORMAL 2.1', 'MIFARMA CUSCO', 'JUEVES', '2020-03-12', 1, '2020-03-13', NULL, NULL, 1.90),
(660, 5, 18, 'PAN CHABATA', 1.00, 1.00, 1.00, '4 PANES', 'PALERMO', 'JUEVES', '2020-03-12', 1, '2020-03-13', NULL, NULL, 1.00),
(661, 5, 19, 'POLLO PIERNITAS GRANEL', 0.37, 5.99, 2.20, '2 PIERNAS', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-03-11', 1, '2020-03-13', 1, '2020-03-13', 2.20),
(662, 5, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-03-13', 1, '2020-03-13', NULL, NULL, 1.00),
(663, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, 'BIODEGRADABLE', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 0.10),
(664, 5, 18, 'MAYONESA DOYPACK WALIBI', 1.00, 12.20, 12.20, '1KG', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 12.20),
(665, 5, 18, 'HUEVOS A GRANEL', 0.57, 5.60, 3.19, '8 HUEVOS', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 3.19),
(666, 5, 22, 'ARROZ SUPERIOR VALLES DORADOS', 1.00, 15.50, 15.50, '5KG', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 15.50),
(667, 16, 18, 'RESINA Z100 A2 Y B2', 2.00, 43.00, 86.00, '3M ESPE', 'GALERIA JR CUSCO', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 86.00),
(668, 16, 18, 'RESINA Z250', 2.00, 67.00, 134.00, '3M ESPE', 'GALERIA JR CUSCO', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 134.00),
(669, 5, 18, 'VITREMER 3M ESPE', 1.00, 180.00, 180.00, 'A3 MATERIAL RESTAURADOR/RECOSTRUCTOR DE MUÑONES', 'GALERIA JR CUSCO', 'VIERNES', '2020-03-13', 1, '2020-03-14', NULL, NULL, 180.00),
(670, 5, 19, 'MANDARINA', 0.50, 4.00, 2.00, '7 MANDARINAS', 'CARRETA ESQUINA CUARTO PALERMO', 'VIERNES', '2020-03-13', 1, '2020-03-14', 1, '2020-03-15', 2.00),
(671, 5, 18, 'CUATES', 1.00, 1.00, 1.00, '', 'LOS OLIVOS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 1.00),
(672, 10, 18, 'IMPRESION', 1.00, 14.00, 14.00, 'COPIAS PARA CONVALIDACION DE CESAR', 'LOS OLIVOS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 14.00),
(673, 5, 18, 'CEBICHE COMBINADO', 2.00, 6.00, 12.00, 'COMBINADO CEBICHE TALLARIN CHAUFAINITA', 'AV. REP DE PANAMA', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 12.00),
(674, 5, 18, 'BOTELLA CHICHA MORADA', 2.00, 1.00, 2.00, '', 'LOS OLIVOS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 2.00),
(675, 5, 18, 'ALMUERZO', 2.00, 6.50, 13.00, '', 'MERCADO LOS OLIVOS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 13.00),
(676, 5, 18, 'PASAJE BUS OLIVOS - RAMON CASTILLA', 1.00, 2.00, 2.00, '', 'LOS OLIVOS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 2.00),
(677, 5, 18, 'CUCHILLO MADERA', 1.00, 7.00, 7.00, '', 'AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 7.00),
(678, 16, 18, 'ALGINATO HYGEDENT CHROMATIC', 1.00, 15.00, 15.00, '454GR', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 15.00),
(679, 16, 18, 'GUANTES GREAT GLOVE XS', 1.00, 15.00, 15.00, '100 GUANTES', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 15.00),
(680, 5, 18, 'MICROBRUSH DISPOCARE', 1.00, 9.00, 9.00, 'COLOR ROSADO', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 9.00),
(681, 6, 18, 'MASCARILLA', 1.00, 60.00, 60.00, '50 MASCARILLAS', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 60.00),
(682, 16, 18, 'GASA PREPARADA - NON WOVEN SPONGES', 1.00, 7.00, 7.00, '2\'\'X2\'\' 4PLY/PLIEGUES 200PCS/PACK', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 7.00),
(683, 5, 18, 'EUGENOL 926', 1.00, 8.00, 8.00, '12ML', 'GALERIA AV EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 8.00),
(684, 5, 18, 'LIMAS THOMAS  PRIMERA GENERACION ', 1.00, 18.00, 18.00, 'L28MM', 'GALERIA AV. EMANCIPACION', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 18.00),
(685, 5, 18, 'ROLLO ALUMINIO COOK MASTER', 1.00, 4.50, 4.50, '5 METROS', 'PALERMO COSTADO TIENDA MASS', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 4.50),
(686, 5, 18, 'MANDARINA', 1.00, 3.50, 3.50, '20 MANDARINA', 'CARRETA PALERMO', 'SABADO', '2020-03-14', 1, '2020-03-15', NULL, NULL, 3.50),
(687, 5, 18, 'GARBANZO', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO TIENDA FONDO', 'DOMINGO', '2020-03-15', 1, '2020-03-15', NULL, NULL, 7.00),
(688, 5, 18, 'PALLAR', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO TIENDA FONDO', 'DOMINGO', '2020-03-15', 1, '2020-03-15', NULL, NULL, 7.00),
(689, 5, 19, 'FREJOL CASTILLA', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO TIENDA FONDO', 'DOMINGO', '2020-03-15', 1, '2020-03-15', NULL, NULL, 8.00),
(690, 6, 22, 'DETERGENTE ACE AROMA LIMON', 1.00, 19.90, 19.90, '2KG', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 19.90),
(691, 5, 18, 'FIDEO TORNILLO NICOLINI', 4.00, 0.98, 3.90, '250GR', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 3.90),
(692, 5, 19, 'PIERNA POLLO', 0.31, 5.10, 1.60, '2 PIERNAS', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 1.60),
(693, 5, 18, 'LAVAVAJILLA AYUDIN LIMON', 1.00, 3.90, 3.90, '550GR', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 3.90),
(694, 5, 18, 'FIDEO NICOLINI GRUESA', 4.00, 1.99, 7.95, '500GR', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 7.95),
(695, 5, 18, 'SAL DE COCINA MARINA EMSAL', 1.00, 1.40, 1.40, '1KG', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 1.40),
(696, 5, 18, 'GRATED SARDINA BELTRAN', 2.20, 4.00, 8.80, '170GR', 'MAXIAHORRO IQUITOS', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 8.80),
(697, 5, 18, 'PAN', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA PALERMO', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 1.00),
(698, 5, 18, 'JABON HENO PRAVIA BLANCO', 1.00, 3.50, 3.50, '', 'TIENDA PALERMO', 'DOMINGO', '2020-03-15', 1, '2020-03-16', NULL, NULL, 3.50),
(699, 9, 18, 'PANADOL', 2.00, 1.95, 3.90, '', 'MIFARMA PALERMO', 'DOMINGO', '2020-03-15', 1, '2020-03-16', 1, '2020-03-23', 3.90),
(700, 5, 19, 'PAPA BLANCA', 4.00, 1.50, 6.00, '', 'CARRETA ESQUINA CUARTO PALERMO', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 6.00),
(701, 5, 19, 'PAPA AMARILLA', 2.75, 2.00, 5.50, '', 'CARRETA ESQUINA CUARTO PALERMO', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 5.50),
(702, 5, 19, 'CEBOLLA', 0.32, 2.50, 0.80, '', 'CARRETA ESQUINA CUARTO PALERMO', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 0.80),
(703, 17, 18, 'PAGO IMPUESTO 4TA 2019', 1.00, 666.00, 666.00, '', 'BANCO DE LA NACION LINCE', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 666.00),
(704, 5, 18, 'HUEVOS A GRANEL', 1.14, 5.60, 6.40, '', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 6.40),
(705, 5, 18, 'FOSFORO 40 LUCES INTI', 1.00, 2.60, 2.60, '', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-03-16', 1, '2020-03-17', 1, '2020-03-17', 2.60),
(706, 5, 18, 'PERDIDO', 1.00, 1.30, 1.30, '', 'CUARTO PALERMO', 'MARTES', '2020-03-17', 1, '2020-03-17', NULL, NULL, 1.30),
(707, 5, 19, 'PALLAR', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'MARTES', '2020-03-17', 1, '2020-03-17', NULL, NULL, 8.00),
(708, 5, 19, 'LENTEJA', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'MARTES', '2020-03-17', 1, '2020-03-17', NULL, NULL, 6.00),
(709, 9, 18, 'AZITROMAC COM', 5.00, 7.00, 35.00, 'AZITROMICINA', 'FARMACIAS HOLLYWOOD', 'MIERCOLES', '2020-03-18', 1, '2020-03-18', NULL, NULL, 35.00),
(710, 9, 18, 'LEFLEN TAB (NAPROXENO)', 10.00, 1.30, 13.00, '1 BLIZTER = 10 PASTILLAS', 'FARMACIAS HOLLYWOOD  PALERMO', 'MIERCOLES', '2020-03-18', 1, '2020-03-18', NULL, NULL, 13.00),
(711, 8, 18, 'LAT VICK VAPORUB', 1.00, 2.10, 2.10, 'LATA PEQUEÑA 12GR', 'FARMACIAS HOLLYWOOD  PALERMO', 'MIERCOLES', '2020-03-18', 1, '2020-03-18', NULL, NULL, 2.10),
(712, 5, 19, 'MARACUYA', 0.80, 2.50, 2.00, '4 MARACUYAS MEDIANAS', 'TIENDA SUBIDA CUARTO', 'MIERCOLES', '2020-03-18', 1, '2020-03-18', NULL, NULL, 2.00),
(713, 5, 18, 'PAN FRANCES', 1.00, 1.00, 1.00, '5 PANES', 'TIENDA PAN PALERMO', 'MIERCOLES', '2020-03-18', 1, '2020-03-18', NULL, NULL, 1.00),
(714, 3, 18, 'PAGO CUARTO ABRIL', 1.00, 400.00, 400.00, '', '', 'MIERCOLES', '2020-03-18', 1, '2020-03-19', NULL, NULL, 400.00),
(715, 5, 19, 'TOMATE', 0.74, 3.50, 2.60, '4 TOMATES', 'MERCADO PALERMO', 'MARTES', '2020-03-17', 1, '2020-03-19', 1, '2020-03-19', 2.60),
(716, 23, 18, 'PRESTAMO JHONY', 1.00, 3000.00, 3000.00, '018-195-004195182774-84', '', 'MIERCOLES', '2020-03-18', 1, '2020-03-21', NULL, NULL, 3000.00),
(717, 23, 18, 'PRESTAMO JHONY', 1.00, 3000.00, 3000.00, '018-195-004195182774-84', '', 'VIERNES', '2020-03-20', 1, '2020-03-21', NULL, NULL, 3000.00),
(718, 23, 18, 'PRESTAMO JHONY', 1.00, 3000.00, 3000.00, '', '', 'SABADO', '2020-03-21', 1, '2020-03-21', NULL, NULL, 3000.00),
(719, 5, 19, 'POLLO PIERNA PECHO', 0.42, 9.00, 3.80, 'PIERNA PECHO', 'MERCADO PALERMO', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 3.80),
(720, 5, 19, 'HUEVO', 1.01, 7.00, 7.10, '', 'MERCADO PALERMO', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 7.10),
(721, 5, 19, 'DURAZNO', 1.03, 3.50, 3.60, '', 'TIENDA FRUTA', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 3.60),
(722, 9, 18, 'AMOXICILINA 500MG', 1.00, 2.50, 2.50, '1 BLISTER 10 TABLETA', 'FARMA MIAVIDA PALERMO', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 2.50),
(723, 9, 18, 'DEXAMETASONA 4MG', 1.00, 2.20, 2.20, '1 BLISTER 10 TABLETA', 'MI FARMA PALERMO', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 2.20),
(724, 9, 18, 'DOLODICLONED', 3.00, 1.73, 5.20, '3', 'MI FARMA PALERMO', 'LUNES', '2020-03-23', 1, '2020-03-23', NULL, NULL, 5.20),
(725, 5, 19, 'CARNE CHANCHO', 0.64, 22.00, 14.00, '4 TROZOS DE CARNE', 'MERCADO PALERMO', 'VIERNES', '2020-03-27', 1, '2020-03-28', 1, '2020-03-28', 14.00),
(726, 5, 18, 'AJI COLORADO', 1.00, 0.50, 0.50, 'AJI COLORADO, AJO Y COMINO', 'MERCADO PALERMO', 'VIERNES', '2020-03-27', 1, '2020-03-28', NULL, NULL, 0.50),
(727, 5, 18, 'UCHUCUTA', 1.00, 2.50, 2.50, '', 'MERCADO PALERMO', 'VIERNES', '2020-03-27', 1, '2020-03-28', NULL, NULL, 2.50),
(728, 5, 19, 'CARNE MOLIDA', 0.59, 17.00, 10.00, '', 'MERCADO PALERMO', 'SABADO', '2020-03-28', 1, '2020-03-28', NULL, NULL, 10.00),
(729, 5, 19, 'TOMATE', 0.30, 4.00, 1.20, '2 TOMATES MEDIANOS', 'MERCADO PALERMO', 'SABADO', '2020-03-28', 1, '2020-03-28', NULL, NULL, 1.20),
(730, 5, 19, 'HUEVO', 1.00, 6.80, 6.80, '1KG', 'MERCADO PALERMO', 'SABADO', '2020-03-28', 1, '2020-03-28', NULL, NULL, 6.80),
(731, 5, 19, 'ARVEJA', 0.47, 4.50, 2.10, '', 'MERCADO PALERMO', 'DOMINGO', '2020-03-29', 1, '2020-03-29', NULL, NULL, 2.10),
(732, 5, 18, 'VETARRAGA', 0.38, 4.00, 1.50, '2 VETARRAGAS PEQUEÑAS', 'MERCADO PALERMO', 'DOMINGO', '2020-03-29', 1, '2020-03-29', 1, '2020-03-29', 1.50),
(733, 5, 18, 'LIMON', 6.00, 0.13, 0.80, '6 LIMONES', 'MERCADO PALERMO', 'DOMINGO', '2020-03-29', 1, '2020-03-29', 1, '2020-03-29', 0.80),
(734, 5, 19, 'ZANAHORIA', 0.26, 3.50, 0.90, '2 ZANAHORIAS 1 PEQUEÑA 1 MEDIANA', 'MERCADO PALERMO', 'DOMINGO', '2020-03-29', 1, '2020-03-29', NULL, NULL, 0.90),
(735, 5, 19, 'POLLO PIERNA PECHO', 0.53, 8.50, 4.50, 'PIERNA PECHO', 'MERCADO PALERMO', 'DOMINGO', '2020-03-29', 1, '2020-03-29', 1, '2020-03-29', 4.50),
(736, 5, 18, 'PERDIDA', 1.00, 18.10, 18.10, '', '', 'LUNES', '2020-03-30', 1, '2020-03-31', 1, '2020-03-31', 18.10),
(737, 5, 18, 'FILETE DE CABALLA BELTRAN', 2.00, 4.20, 8.40, '', 'MAXIAHORRO IQUITOS', 'MARTES', '2020-03-31', 1, '2020-03-31', NULL, NULL, 8.40),
(738, 5, 18, 'BOLSA BIODEGRADABLE BLANCA', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'MARTES', '2020-03-31', 1, '2020-03-31', NULL, NULL, 0.10);
INSERT INTO egreso (id, id_tipo_egreso, id_unidad_medida, nombre, cantidad, precio, total, descripcion, ubicacion, dia, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod, total_egreso) VALUES
(739, 5, 18, 'ARROZ EXTRA AZUL COSTEÑO', 1.00, 17.80, 17.80, '5KG\nPRECIO NORMAL 18.5', 'MAXIAHORRO IQUITOS', 'MARTES', '2020-03-31', 1, '2020-03-31', 1, '2020-03-31', 17.80),
(740, 5, 18, 'CREMA ROCOTO UCHUCUTA ALACENA 400GR', 1.00, 7.20, 7.20, 'PRECIO NORMAL 9.99\n400GR', 'MAXIAHORRO IQUITOS', 'MARTES', '2020-03-31', 1, '2020-03-31', NULL, NULL, 7.20),
(741, 5, 18, 'HUEVOS A GRANEL', 0.88, 6.90, 6.10, '', 'MAXIAHORRO IQUITOS', 'MARTES', '2020-03-31', 1, '2020-03-31', NULL, NULL, 6.10),
(742, 5, 18, 'BALON GAS MAS GAS', 1.00, 36.00, 36.00, '', 'ESQUINA CUARTO PALERMO', 'MIERCOLES', '2020-04-01', 1, '2020-04-01', NULL, NULL, 36.00),
(743, 5, 19, 'PAPA BLANCA', 1.35, 2.00, 2.70, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-01', 1, '2020-04-01', NULL, NULL, 2.70),
(744, 5, 19, 'TOMATE', 0.67, 3.00, 2.00, '4 TOMATES', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-01', 1, '2020-04-01', NULL, NULL, 2.00),
(745, 5, 18, 'ACEITE IDEAL 1L', 1.00, 6.50, 6.50, '1LITRO', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-01', 1, '2020-04-01', NULL, NULL, 6.50),
(746, 5, 18, 'SILLAO KIKKO 85CC', 1.00, 1.00, 1.00, '85ML', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 1.00),
(747, 5, 19, 'POLLO MUSLO ECONOMICO', 0.48, 5.99, 2.90, '2 MUSLOS', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 2.90),
(748, 5, 19, 'HUEVOS A GRANEL', 1.00, 6.90, 6.90, '16 HUEVOS', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-03-04', 1, '2020-04-03', NULL, NULL, 6.90),
(749, 5, 18, 'SALCHICHA DE POLLO 200GR', 1.00, 3.50, 3.50, '10 SALCHICHAS', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-03-04', 1, '2020-04-03', NULL, NULL, 3.50),
(750, 6, 18, 'JABON HENO 150GR', 1.00, 4.20, 4.20, 'GRANDE', 'FARMACIAS HOLLYWOOD PALERMO', 'MIERCOLES', '2020-03-04', 1, '2020-04-03', 1, '2020-04-03', 4.20),
(751, 5, 18, 'CEBOLLA CHINA', 1.00, 0.50, 0.50, 'UN ATADO PEQUEÑO', 'MERCADO PALERMO', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 0.50),
(752, 5, 18, 'LIMON', 1.00, 0.50, 0.50, '3 LIMONES', 'MERCADO PALERMO', 'MIERCOLES', '2020-03-04', 1, '2020-04-03', NULL, NULL, 0.50),
(753, 5, 18, 'MARACUYA', 0.29, 3.50, 1.00, '2 MARACUYAS GRANDES', 'MERCADO PALERMO', 'MIERCOLES', '2020-03-04', 1, '2020-04-03', NULL, NULL, 1.00),
(754, 5, 19, 'HUEVOS A GRANEL', 1.00, 6.90, 6.90, '16 HUEVOS', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 6.90),
(755, 5, 18, 'SALCHICHA DE POLLO', 1.00, 3.50, 3.50, '5 SALCHICHAS', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 3.50),
(756, 5, 18, 'JABON HENO PRAVIA AMARILLO', 1.00, 4.20, 4.20, '', 'FARMACIAS HOLLYWOOD', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 4.20),
(757, 5, 18, 'LIMON', 1.00, 0.50, 0.50, '3 LIMONES', 'MERCADO PALERMO', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 0.50),
(758, 5, 19, 'MARACUYA', 0.29, 3.50, 1.00, '2 MARACUYAS GRANDES', 'MERCADO PALERMO', 'VIERNES', '2020-04-03', 1, '2020-04-03', NULL, NULL, 1.00),
(759, 5, 19, 'PALLAR', 1.00, 9.00, 9.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 9.00),
(760, 5, 19, 'LENTEJA', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 7.00),
(761, 5, 18, 'VETARRAGA', 2.00, 1.00, 2.00, 'CADA BOLA 1.0', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 2.00),
(762, 5, 19, 'ARVEJA', 0.86, 3.50, 3.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 3.00),
(763, 5, 19, 'ZANAHORIA', 0.77, 3.00, 2.30, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 2.30),
(764, 5, 19, 'LIMON', 0.46, 7.00, 3.20, '10 LIMONES', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 3.20),
(765, 5, 19, 'MANDARINA', 1.00, 4.00, 4.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 4.00),
(766, 5, 19, 'PAPA BLANCA', 3.00, 2.00, 6.00, '', 'CARRETA ESQUINA CUARTO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 6.00),
(767, 5, 19, 'POLLO', 0.89, 9.00, 8.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 8.00),
(768, 5, 19, 'ARROZ GRANEL', 4.72, 2.69, 12.70, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 12.70),
(769, 5, 19, 'AZUCAR RUBIA GRANEL', 1.20, 2.59, 3.10, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 3.10),
(770, 5, 19, 'HUEVOS A GRANEL', 0.99, 6.59, 6.50, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 6.50),
(771, 5, 18, 'BOLSA MAXIAHORRO', 1.00, 0.20, 0.20, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', 1, '2020-04-09', 0.20),
(772, 15, 18, 'RECARGA TELEFONO PAPA', 1.00, 5.00, 5.00, '', '', 'MIERCOLES', '2020-04-08', 1, '2020-04-08', NULL, NULL, 5.00),
(773, 4, 18, 'PAGO BITEL ABRIL', 1.00, 29.90, 29.90, '', '', 'VIERNES', '2020-04-10', 1, '2020-04-11', NULL, NULL, 29.90),
(774, 5, 19, 'PAPA BLANCA', 2.82, 2.20, 6.20, '', 'MERCADO PALERMO', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 6.20),
(775, 5, 19, 'ZANAHORIA', 0.82, 4.00, 3.30, '', 'MERCADO PALERMO', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 3.30),
(776, 5, 19, 'ARVEJAS', 0.40, 5.00, 2.00, '', 'MERCADO PALERMO', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 2.00),
(777, 5, 19, 'POLLO', 0.69, 7.00, 4.80, '', 'MERCADO PALERMO', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 4.80),
(778, 5, 19, 'PALLAR', 1.00, 9.00, 9.00, '', 'MERCADO PALERMO', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 9.00),
(779, 5, 18, 'CREMA DE ROCOTO UCHUCUTA ALACENA 85GR', 1.00, 3.00, 3.00, '85GR', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 3.00),
(780, 5, 18, 'FIDEOS SPAGUETTI NICOLINNI 500GR', 2.00, 2.00, 4.00, '500GR', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 4.00),
(781, 5, 18, 'FIDEO CANUTO RAYADO GRANO ORO 250GR', 2.00, 1.00, 2.00, '250GR', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 2.00),
(782, 5, 19, 'HUEVOS A GRANEL', 1.11, 6.59, 7.30, '18 HUEVOS', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 7.30),
(783, 5, 18, 'FIDEO RIGATON GRANO DE ORO 250GR', 2.00, 0.95, 1.90, '', 'MAXIAHORRO IQUITOS', 'LUNES', '2020-04-13', 1, '2020-04-13', NULL, NULL, 1.90),
(784, 15, 18, 'PAGO TELEFONO CESAR', 1.00, 101.52, 101.52, '', '', 'LUNES', '2020-04-13', 1, '2020-04-14', NULL, NULL, 101.52),
(785, 5, 19, 'TOMATE', 0.60, 7.00, 4.20, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-15', 1, '2020-04-15', NULL, NULL, 4.20),
(786, 5, 19, 'PAPA', 1.50, 2.00, 3.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-15', 1, '2020-04-15', NULL, NULL, 3.00),
(787, 5, 18, 'LIMON', 1.00, 0.30, 0.30, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-04-15', 1, '2020-04-15', NULL, NULL, 0.30),
(788, 5, 18, 'PAN', 2.00, 1.00, 2.00, '5 FRANCES Y 4 CHABATA', 'TIENDA PAN PALERML', 'MIERCOLES', '2020-04-15', 1, '2020-04-15', NULL, NULL, 2.00),
(789, 5, 18, 'BOLSA BLANCA', 1.00, 0.10, 0.10, '', 'TIENDA PAN PALERMO', 'MIERCOLES', '2020-04-15', 1, '2020-04-15', NULL, NULL, 0.10),
(790, 5, 19, 'MANDARINA', 1.00, 2.00, 2.00, '', 'TRICICLO PALERMO ', 'VIERNES', '2020-04-17', 1, '2020-04-17', NULL, NULL, 2.00),
(791, 5, 19, 'GARBANZO', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'VIERNES', '2020-04-17', 1, '2020-04-17', NULL, NULL, 8.00),
(792, 5, 19, 'FREJOL PASTILLA', 1.00, 6.50, 6.50, '', 'MERCADO PALERMO', 'VIERNES', '2020-04-17', 1, '2020-04-17', NULL, NULL, 6.50),
(793, 5, 19, 'POLLO', 0.50, 7.00, 3.50, 'PIERNA Y PECHO', 'MERCADO PALERMO', 'VIERNES', '2020-04-17', 1, '2020-04-17', 1, '2020-04-17', 3.50),
(794, 5, 19, 'MARACUYA', 1.00, 4.00, 4.00, '6 MARACUYAS MEDIANAS', 'MERCADO PALERMO', 'VIERNES', '2020-04-17', 1, '2020-04-17', NULL, NULL, 4.00),
(795, 5, 19, 'ARROZ GRANEL', 2.64, 2.69, 7.10, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-17', 1, '2020-04-18', NULL, NULL, 7.10),
(796, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 3.90, 3.90, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-17', 1, '2020-04-18', NULL, NULL, 3.90),
(797, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-17', 1, '2020-04-18', NULL, NULL, 0.10),
(798, 5, 19, 'HUEVOS GRANEL', 1.29, 6.59, 8.50, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-17', 1, '2020-04-18', NULL, NULL, 8.50),
(799, 5, 18, 'FIDEO CARACOL ALIANZA 250GR', 3.00, 0.73, 2.20, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-17', 1, '2020-04-18', NULL, NULL, 2.20),
(800, 7, 18, 'PILA PANASONIC', 1.00, 1.40, 1.40, '2A', 'TIENDA ABAJO MERCADO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 1.40),
(801, 6, 18, 'JABON HENO', 1.00, 3.00, 3.00, '', 'TIENDA ABAJO MERCADO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 3.00),
(802, 5, 19, 'MONDONGO', 0.43, 14.00, 6.00, '', 'MERCADO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 6.00),
(803, 5, 19, 'ARVEJA', 0.25, 4.80, 1.20, '', 'MERCADO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 1.20),
(804, 5, 18, 'ZANAHORIA', 2.00, 0.75, 1.50, '', 'CARRETA CUARTO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 1.50),
(805, 5, 18, 'AJI AMARILLO', 1.00, 0.50, 0.50, '', 'MERCADO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 0.50),
(806, 5, 19, 'PAPA BLANCA', 2.50, 2.00, 5.00, '', 'CARRETA CUARTO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 5.00),
(807, 5, 19, 'CEBOLLA', 0.25, 4.00, 1.00, '', 'CARRETA CUARTO PALERMO', 'LUNES', '2020-04-20', 1, '2020-04-21', NULL, NULL, 1.00),
(808, 5, 18, 'EGRESO PERDIDO', 1.00, 4.60, 4.60, '', '', 'LUNES', '2020-04-20', 1, '2020-04-24', NULL, NULL, 4.60),
(809, 5, 18, 'VINO GRAN BLANCO TABERNERO 750ML', 1.00, 17.90, 17.90, '750ML', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 17.90),
(810, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 0.10),
(811, 5, 18, 'AJI CRIOLLO DOYPACK WALIBI', 1.00, 3.20, 3.20, 'PRECIO NORMAL 3.60', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 3.20),
(812, 5, 18, 'SILLAO KIKKO 160CC', 1.00, 1.60, 1.60, '160CC', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 1.60),
(813, 5, 19, 'HUEVO A GRANEL', 1.63, 7.19, 11.70, '', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', 1, '2020-04-24', 11.70),
(814, 5, 18, 'HARINA SIN PREPARAR MOLITALIA 1KG', 1.00, 4.20, 4.20, 'PRECIO 4.60', 'MAXIAHORRO IQUITOS', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 4.20),
(815, 5, 19, 'ARROZ NORTEÑO', 2.00, 3.00, 6.00, '', 'MERCADO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 6.00),
(816, 5, 19, 'AJO', 0.30, 18.00, 5.40, '', 'MERCADO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 5.40),
(817, 5, 19, 'FREJOL CASTILLA', 1.00, 6.50, 6.50, '', 'MERCADO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 6.50),
(818, 5, 19, 'PAPA BLANCA', 2.87, 1.50, 4.30, '', 'TRICICLO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-24', NULL, NULL, 4.30),
(819, 5, 19, 'TOMATE', 0.42, 4.00, 1.70, '6 TOMATES', 'TRICICLO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-24', 1, '2020-04-24', 1.70),
(820, 3, 18, 'PAGO CUARTO MAYO', 1.00, 400.00, 400.00, '', '', 'SABADO', '2020-04-25', 1, '2020-04-26', 1, '2020-04-28', 400.00),
(821, 23, 18, 'PAGO CELULAR JHONY', 1.00, 49.90, 49.90, '', '', 'DOMINGO', '2020-04-26', 1, '2020-04-27', NULL, NULL, 49.90),
(822, 5, 19, 'POLLO', 0.83, 9.00, 7.50, '2 MEDIAS PIERNAS, IR A LA ZON DONDE DESPACHAN VARIOS', 'MERCADO PALERMO', 'VIERNES', '2020-04-24', 1, '2020-04-28', 1, '2020-04-28', 7.50),
(823, 5, 18, 'FIDEO SPAGHETTI ALIANZA 500GR', 2.00, 1.50, 3.00, 'NORMAL 1.90', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 3.00),
(824, 5, 19, 'PIERNITAS DE POLLO IMPORTADA', 1.19, 6.49, 7.70, '', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 7.70),
(825, 6, 18, 'PAPEL HIGIENICO SUAVE NARANJA 24U', 1.00, 15.50, 15.50, 'PRECIO NORMAL 16.99', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 15.50),
(826, 5, 18, 'HOT DOG SUIZA 220GR', 1.00, 4.90, 4.90, '', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 4.90),
(827, 5, 19, 'HUEVOS A GRANEL', 0.90, 7.19, 6.50, '12 HUEVOS', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 6.50),
(828, 5, 18, 'FIDEO TALLARIN GRUESO ALIANZA 500GR', 1.00, 1.50, 1.50, 'NORMAL 1.9', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 1.50),
(829, 5, 18, 'GALLETA SODA SAN JORGE 500GR', 1.00, 4.20, 4.20, '', 'MAXIAHORRO  IQUITOS', 'MARTES', '2020-04-28', 1, '2020-04-28', NULL, NULL, 4.20),
(830, 5, 19, 'CEBOLLA', 1.03, 3.50, 3.60, '', 'MERCADO PALERMO', 'MARTES', '2020-04-28', 1, '2020-04-29', NULL, NULL, 3.60),
(831, 5, 19, 'LIMON', 0.48, 4.20, 2.00, '', 'MERCADO PALERMO', 'MARTES', '2020-04-28', 1, '2020-04-29', NULL, NULL, 2.00),
(832, 5, 19, 'ARROZ', 2.00, 3.20, 6.40, '', 'MERCADO PALERMO', 'MARTES', '2020-04-28', 1, '2020-04-29', NULL, NULL, 6.40),
(833, 5, 19, 'PIÑA', 1.00, 2.00, 2.00, '', 'MERCADO PALERMO', 'MARTES', '2020-04-28', 1, '2020-04-29', NULL, NULL, 2.00),
(834, 5, 19, 'PAPA ROSADA', 2.00, 1.00, 2.00, '', 'AMBULANTE', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 2.00),
(835, 5, 22, 'AJI AMARILLA', 1.00, 1.00, 1.00, '5 AJIES AMARILLAS', 'AMBULANTE', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 1.00),
(836, 5, 19, 'POLLO PIERNA PECHO', 0.35, 8.50, 3.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 3.00),
(837, 5, 19, 'ACEITUNA PEQUEÑA', 0.25, 10.00, 2.50, '', 'MERCADO PALERMO', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 2.50),
(838, 5, 19, 'MARACUYA', 1.00, 3.00, 3.00, '5 MARACUYAS MEDIANA GRANDES', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 3.00),
(839, 23, 18, 'PENSION UNIV CONTINENTAL ABRIL CESAR', 1.00, 488.00, 488.00, '', '', 'SABADO', '2020-05-02', 1, '2020-05-02', NULL, NULL, 488.00),
(840, 5, 19, 'ARROZ GRANEL', 4.13, 2.69, 11.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 11.10),
(841, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.00, 4.00, '900ML', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 4.00),
(842, 5, 18, 'SALSA DE AJI TARI 400GR', 1.00, 7.90, 7.90, '400GR', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 7.90),
(843, 5, 18, 'JABON NAT ALOE Y OLIVA PALMOLIVE 3X120G', 1.00, 7.20, 7.20, '3 JABONES EN PACK', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 7.20),
(844, 5, 19, 'AZUCAR RUBIA GRANEL', 1.16, 2.59, 3.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 3.00),
(845, 5, 18, 'PACK H&S 375 Y SH180 LIMP RENOV', 1.00, 23.90, 23.90, 'DOS SHAMPOO UNO MEDIANO Y UNO PEQUEÑO', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 23.90),
(846, 5, 18, 'SAL DE COCINA EMSAL 1KG', 1.00, 1.80, 1.80, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 1.80),
(847, 5, 19, 'HUEVOS A GRANEL', 1.52, 7.19, 10.90, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 10.90),
(848, 5, 18, 'SALCHICHA DE POLLO 200GR', 1.00, 3.50, 3.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 3.50),
(849, 5, 18, 'GALLETA SODA SAN JORGE 500GR', 1.00, 4.20, 4.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 4.20),
(850, 5, 18, 'PALLAR', 1.00, 9.00, 9.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 9.00),
(851, 5, 19, 'LENTEJA', 2.00, 6.00, 12.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 12.00),
(852, 5, 19, 'GARBANZO', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 8.00),
(853, 5, 19, 'FREJOL CASTILLA', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 7.00),
(854, 5, 19, 'PAPA BLANCA', 2.06, 1.70, 3.50, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 3.50),
(855, 5, 19, 'CEBOLLA', 1.00, 3.00, 3.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 3.00),
(856, 5, 19, 'LIMON', 1.00, 2.00, 2.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 2.00),
(857, 5, 19, 'POLLO', 1.69, 8.00, 13.50, '', 'MERCADO PALERMO', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 13.50),
(858, 5, 18, 'BOLSA', 1.00, 0.10, 0.10, '', '', 'SABADO', '2020-05-09', 1, '2020-05-10', NULL, NULL, 0.10),
(859, 7, 18, 'MODEM ENTEL HOGAR', 1.00, 199.00, 199.00, '', '', 'LUNES', '2020-05-11', 1, '2020-05-13', 1, '2020-05-13', 199.00),
(860, 5, 18, 'PAPA BLANCA', 2.00, 1.00, 2.00, '', 'TRICICLO CUARTO PALERMO', 'MIERCOLES', '2020-05-13', 1, '2020-05-13', NULL, NULL, 2.00),
(861, 5, 19, 'FREJOL CASTILLA', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 7.00),
(862, 5, 19, 'GABANZO', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 8.00),
(863, 5, 19, 'CEBOLLA', 1.00, 2.70, 2.70, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 2.70),
(864, 5, 19, 'PAPA BLANCA', 2.00, 1.70, 3.40, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 3.40),
(865, 5, 19, 'HIGADO', 0.50, 14.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 7.00),
(866, 5, 19, 'TOMATE', 0.53, 6.80, 3.60, '', 'MERCADO PALERMO', 'SABADO', '2020-05-16', 1, '2020-05-16', 1, '2020-05-16', 3.60),
(867, 5, 19, 'ARROZ GRANEL', 4.76, 2.69, 12.80, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 12.80),
(868, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.00, 4.00, '3.99', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 4.00),
(869, 5, 19, 'MOLLEJA POLLO IMP', 0.44, 6.99, 3.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 3.10),
(870, 5, 18, 'SALCHICHA DE POLLO 200GR', 1.00, 3.50, 3.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 3.50),
(871, 5, 18, 'FIDEO TALLARIN GRUESO ALIANZA 500GR', 3.00, 1.50, 4.50, '1.90', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 4.50),
(872, 5, 19, 'HUEVOS A GRANEL', 1.24, 6.99, 8.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-16', 1, '2020-05-16', NULL, NULL, 8.70),
(873, 5, 18, 'PAN FRANCES Y CHABATA', 2.00, 1.00, 2.00, '9 PANES', 'TIENDA PAN PALERMO', 'MIERCOLES', '2020-05-20', 1, '2020-05-21', 1, '2020-05-21', 2.00),
(874, 6, 18, 'PASTA DENTAL DENTO BLA 75X3', 1.00, 11.30, 11.30, '', 'METRO  MANCO CAPAC', 'MARTES', '2020-05-19', 1, '2020-05-22', NULL, NULL, 11.30),
(875, 6, 18, 'LEJIA CLOROX TRD 345GR', 1.00, 1.20, 1.20, '', 'METRO MANCO CAPAC', 'MARTES', '2020-05-19', 1, '2020-05-22', NULL, NULL, 1.20),
(876, 17, 18, 'MONTO ROBO', 1.00, 180.50, 180.50, '', 'AV. MACO CAPAC Y MEXICO', 'MARTES', '2020-05-19', 1, '2020-05-22', NULL, NULL, 180.50),
(877, 5, 18, 'PAGO TELEFONO CESAR MAYO', 1.00, 101.52, 101.52, '', '', 'MIERCOLES', '2020-05-20', 1, '2020-05-22', NULL, NULL, 101.52),
(878, 17, 18, 'RENOVACION TARJETA MULTIRED', 1.00, 12.00, 12.00, '', 'BANCO DE LA NACION - NICOLAS ARRIOLA', 'MIERCOLES', '2020-05-20', 1, '2020-05-22', NULL, NULL, 12.00),
(879, 5, 18, 'CREMA DE ROCOTO WALIBI DOY PACK 200', 1.00, 4.30, 4.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 4.30),
(880, 5, 18, 'SALSA DE AJI TARI 400GR', 1.00, 7.90, 7.90, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 7.90),
(881, 5, 18, 'BOLSA BIODEGRAFABLE ASA BLANCA 17X20', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 0.10),
(882, 5, 18, 'COMINO MOLIDO X 18 GR', 1.00, 3.20, 3.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 3.20),
(883, 5, 18, 'AJI PANCA GIGAN SIBARITA 32.4GR X 42U', 1.00, 0.70, 0.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 0.70),
(884, 5, 18, 'AZUCAR RUBIA GRANEL', 1.65, 2.59, 4.27, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 4.27),
(885, 5, 18, 'OREGANO ENTERO 18GR', 1.00, 3.30, 3.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 3.30),
(886, 5, 18, 'HUEVOS A GRANEL', 1.09, 6.39, 6.93, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 6.93),
(887, 5, 19, 'ZANAHORIA', 0.70, 2.00, 1.40, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 1.40),
(888, 5, 18, 'APIO', 1.00, 1.00, 1.00, 'UN APIO MEDIANO', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 1.00),
(889, 5, 19, 'ZAPALLO', 0.40, 2.00, 0.80, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 0.80),
(890, 5, 19, 'POLLO', 0.50, 7.60, 3.80, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 3.80),
(891, 5, 19, 'PAPA AMARILLA', 1.27, 3.00, 3.80, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 3.80),
(892, 5, 19, 'TOMATE', 0.50, 4.00, 2.00, '6 TOMATES', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 2.00),
(893, 5, 19, 'PAPA BLANCA', 4.00, 1.50, 6.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-23', 1, '2020-05-23', NULL, NULL, 6.00),
(894, 3, 18, 'PAGO CUARTO JUNIO', 1.00, 400.00, 400.00, '', '', 'SABADO', '2020-05-23', 1, '2020-05-24', NULL, NULL, 400.00),
(895, 4, 18, 'PAGO INTERNET ENTEL HOGAR', 1.00, 79.67, 79.67, 'PRIMER PAGO', '', 'VIERNES', '2020-05-29', 1, '2020-05-30', NULL, NULL, 79.67),
(896, 5, 19, 'POLLO PARTE PIERNA', 0.60, 6.50, 3.90, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 3.90),
(897, 5, 19, 'PAPA', 4.00, 1.00, 4.00, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 4.00),
(898, 5, 19, 'ZANAHORIA', 1.00, 2.50, 2.50, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 2.50),
(899, 5, 19, 'TOMATE', 0.56, 4.50, 2.50, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 2.50),
(900, 5, 18, 'AJI AMARILLO', 2.00, 0.25, 0.50, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', 1, '2020-05-30', 0.50),
(901, 7, 18, 'PILA', 1.00, 1.50, 1.50, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 1.50),
(902, 5, 19, 'ARROZ GRANEL', 3.90, 2.69, 10.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 10.50),
(903, 5, 18, 'FIDEO SPAGHETTI ALIANZA', 4.00, 1.50, 6.00, 'PRECIO NORMAL 1.9', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 6.00),
(904, 5, 18, 'BOLSA BIODEGRADABLE', 2.00, 0.10, 0.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 0.20),
(905, 5, 18, 'SAL DE COCINA MARINA EMSAL', 1.00, 1.80, 1.80, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 1.80),
(906, 5, 19, 'HUEVOS A GRANEL', 0.80, 6.39, 5.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 5.10),
(907, 5, 18, 'GALLETA SODA SAN JORGE 500GR', 1.00, 4.20, 4.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 4.20),
(908, 6, 18, 'CUBREBOCA', 2.00, 5.00, 10.00, '', 'AV PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 10.00),
(909, 5, 19, 'MANDARINA', 2.00, 2.00, 4.00, '', 'AV PALERMO', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 4.00),
(910, 23, 18, 'PENSION UNIV CESAR MAYO', 1.00, 488.00, 488.00, '', '', 'SABADO', '2020-05-30', 1, '2020-05-30', NULL, NULL, 488.00),
(911, 7, 18, 'CINTA DE EMBALAJE', 1.00, 3.00, 3.00, '', 'COSTADO DE MERCADO PALERMO', 'LUNES', '2020-06-01', 1, '2020-06-01', 1, '2020-06-01', 3.00),
(912, 9, 18, 'CUBREBOCA', 4.00, 3.50, 14.00, '', '', 'LUNES', '2020-06-01', 1, '2020-06-01', NULL, NULL, 14.00),
(913, 9, 18, 'PANADOL ANTIGRIPAL', 2.00, 1.95, 3.90, 'PRECIO NORMAL 2.1', 'MIFARMA PALERMO', 'LUNES', '2020-06-01', 1, '2020-06-01', NULL, NULL, 3.90),
(914, 5, 19, 'PAPA BLANCA', 4.00, 1.50, 6.00, 'MAS ABAJO DONDE VENDEN POLLO 1.2', 'TRICICLO CUARTO PALERMO', 'LUNES', '2020-06-01', 1, '2020-06-01', NULL, NULL, 6.00),
(915, 17, 18, 'ENVIO ENCOMIENDA AYACUCHO', 1.00, 10.00, 10.00, '', 'SAN LUIS', 'MARTES', '2020-06-02', 1, '2020-06-05', NULL, NULL, 10.00),
(916, 5, 19, 'POLLO PARTE PIERNA', 0.50, 7.20, 3.60, '', 'TIENDA CUARTO PALERMO', 'MARTES', '2020-06-02', 1, '2020-06-05', NULL, NULL, 3.60),
(917, 5, 19, 'POLLO PARTE PIERNA', 0.56, 5.50, 3.10, '', 'SAN LUIS', 'MIERCOLES', '2020-06-03', 1, '2020-06-05', NULL, NULL, 3.10),
(918, 5, 18, 'TARI', 1.00, 2.80, 2.80, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-06-03', 1, '2020-06-05', NULL, NULL, 2.80),
(919, 5, 18, 'LAVAVAJILLAS LESLY LIMON 400GR', 1.00, 2.00, 2.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 2.00),
(920, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 4.00, 1.50, 6.00, '1.90', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 6.00),
(921, 5, 18, 'BOLSA BODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 0.10),
(922, 5, 19, 'HUEVOS A GRANEL', 1.11, 6.19, 6.90, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 6.90),
(923, 6, 18, 'JABON LIQ ANTIB EUCALIPTO PUMP AVAL 400ML', 1.00, 7.00, 7.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 7.00),
(924, 5, 19, 'PALLAR', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 8.00),
(925, 5, 19, 'LENTEJA', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 6.00),
(926, 5, 19, 'LIMON', 0.50, 2.00, 1.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 1.00),
(927, 5, 19, 'TOMATE', 1.00, 4.50, 4.50, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 4.50),
(928, 5, 18, 'AJI AMARILLO', 1.00, 1.00, 1.00, '6 AJIES', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 1.00),
(929, 5, 19, 'POLLO PARTE PIERNA', 0.48, 6.50, 3.10, '', 'TIENDA CUARTO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 3.10),
(930, 5, 19, 'PAPA BLANCA', 3.00, 1.50, 4.50, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-06', 1, '2020-06-06', NULL, NULL, 4.50),
(931, 4, 18, 'CHIP CLARO 986355829', 1.00, 10.00, 10.00, 'CLARO 4GLITE (AMERICA MOVIL PERU SAC  - AV. NICOLAS ARRIOLA 480 STA. CATALINA, LA VICTORIA LIMA PERU - RUC 20467534026)\nNUMERO: 986355829\nPUK1: 96479421\n895110163941979290', 'AV. GRAU Y AV.MANCO CAPAC', 'LUNES', '2020-06-08', 1, '2020-06-09', NULL, NULL, 10.00),
(932, 7, 18, 'MICA DE VIDRIO CELULAR', 1.00, 8.00, 8.00, 'TIENDA DE BITEL', 'AV. PETITTUARS', 'LUNES', '2020-06-08', 1, '2020-06-09', NULL, NULL, 8.00),
(933, 5, 18, 'PAN CHABATA Y FRANCES', 2.00, 1.00, 2.00, '9 PANES', 'TIENDA PAN PALERMO', 'LUNES', '2020-06-08', 1, '2020-06-09', NULL, NULL, 2.00),
(934, 11, 18, 'ESCANEO ORDEN COMPRA', 1.00, 0.50, 0.50, '', 'AV. ', 'MIERCOLES', '2020-06-10', 1, '2020-06-11', NULL, NULL, 0.50),
(935, 5, 19, 'PAPA YUNGAY', 2.00, 1.30, 2.60, '', 'TIENDA FRENTE CUARTO PALERMO', 'JUEVES', '2020-06-11', 1, '2020-06-11', NULL, NULL, 2.60),
(936, 5, 19, 'POLLO PARTE PIERNA', 0.72, 5.00, 3.60, '', 'TIENDA FRENTE CUARTO PALERMO', 'JUEVES', '2020-06-11', 1, '2020-06-11', NULL, NULL, 3.60),
(937, 6, 18, 'CORTE DE CABELLO', 2.00, 15.00, 30.00, '', '', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 30.00),
(938, 5, 19, 'POLLO PIERNA', 0.50, 7.00, 3.50, '', 'TIENDA FRENTE CUARTO', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 3.50),
(939, 5, 19, 'TOMATE', 0.50, 4.00, 2.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 2.00),
(940, 5, 19, 'PAPA', 3.00, 1.00, 3.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 3.00),
(941, 5, 18, 'AJI AMARILLO', 6.00, 0.17, 1.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 1.00),
(942, 5, 19, 'ARROZ GRANEL', 3.72, 2.69, 10.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 10.00),
(943, 5, 18, 'FIDEO SPAGUETTI ALIANZA', 4.00, 1.50, 6.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 6.00),
(944, 5, 18, 'ACEITE VEGETAL MERKAT', 1.00, 4.30, 4.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 4.30),
(945, 5, 18, 'HUEVOS A GRANEL', 1.55, 6.19, 9.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 9.60),
(946, 5, 18, 'SALCHICHA DE POLLO 200GR', 1.00, 3.50, 3.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 3.50),
(947, 5, 18, 'GALLETA SODA SAN JORGE 500GE', 1.00, 4.20, 4.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-13', 1, '2020-06-13', NULL, NULL, 4.20),
(948, 5, 18, 'PAGO TELEF. CESAR JUNIO', 1.00, 88.17, 88.17, '', '', 'VIERNES', '2020-06-12', 1, '2020-06-14', NULL, NULL, 88.17),
(949, 15, 18, 'RECARGA PAPA', 1.00, 10.00, 10.00, '', '', 'VIERNES', '2020-06-19', 1, '2020-06-19', NULL, NULL, 10.00),
(950, 5, 19, 'ARROZ GRANEL', 1.38, 2.69, 3.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 3.70),
(951, 5, 18, 'BOLSA BIODEGRADALE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 0.10),
(952, 6, 18, 'JABON NAT ALOE Y OLIVA PALMOLIVE 3X120GR', 1.00, 7.20, 7.20, '3 JABONES', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 7.20),
(953, 5, 19, 'AZUCAR RUBIA GRANEL', 1.24, 2.59, 3.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 3.20),
(954, 5, 19, 'HUEVOS A GRANEL', 0.67, 5.95, 4.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 4.00),
(955, 5, 18, 'CREMA ROCOTO UCHUCUTA ALACENA', 1.00, 10.00, 10.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 10.00),
(956, 5, 18, 'GALLETA SODA SAN JORGE 500GR', 1.00, 4.20, 4.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 4.20),
(957, 5, 19, 'POLLO PARTE PIERNA', 0.60, 7.00, 4.20, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 4.20),
(958, 5, 19, 'TOMATE', 1.00, 4.00, 4.00, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 4.00),
(959, 5, 19, 'PAPA BLANCA', 3.00, 1.50, 4.50, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 4.50),
(960, 5, 19, 'LENTEJA', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 6.00),
(961, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', 'TIENDA PAN PLERMO', 'SABADO', '2020-06-20', 1, '2020-06-20', NULL, NULL, 2.00),
(962, 5, 19, 'POLLO PARTE PIERNA', 0.54, 7.00, 3.80, '', 'TIENDA FRENTE CUARTO PALERMO', 'MARTES', '2020-06-16', 1, '2020-06-20', 1, '2020-06-20', 3.80),
(963, 3, 18, 'PAGO CUARTO JULIO', 1.00, 400.00, 400.00, '', '', 'SABADO', '2020-06-20', 1, '2020-06-21', NULL, NULL, 400.00),
(964, 5, 18, 'FOTOCOPIAS', 1.00, 2.00, 2.00, '', '', 'JUEVES', '2020-06-25', 1, '2020-06-26', NULL, NULL, 2.00),
(965, 5, 18, 'PASAJE BUS23A MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2020-06-25', 1, '2020-06-26', NULL, NULL, 1.00),
(966, 23, 18, 'PENSION CESAR JUNIO ATRAZ', 2.00, 122.00, 244.00, '', '', 'MARTES', '2020-06-23', 1, '2020-06-26', 1, '2020-06-26', 244.00),
(967, 23, 18, 'PENSION CESAR JUNIO', 1.00, 610.00, 610.00, '', '', 'MARTES', '2020-06-23', 1, '2020-06-26', NULL, NULL, 610.00),
(968, 5, 18, 'EGRESO X', 1.00, 1.00, 1.00, '', '', 'JUEVES', '2020-06-25', 1, '2020-06-27', 1, '2020-06-27', 1.00),
(969, 5, 19, 'PALLAR', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 8.00),
(970, 5, 19, 'GARBANZO', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 8.00),
(971, 5, 19, 'ARVEJA VERDE', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 6.00),
(972, 5, 18, 'PAN FRANCES', 1.00, 2.00, 2.00, '', 'TIENDA PAN PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 2.00),
(973, 5, 18, 'AJI AMARILLA', 6.00, 0.17, 1.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 1.00),
(974, 5, 19, 'PAPA BLANCA', 2.00, 1.50, 3.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 3.00),
(975, 5, 19, 'PAPA BLANCA', 2.50, 1.00, 2.50, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 2.50),
(976, 5, 19, 'POLLO PECHO', 0.61, 7.50, 4.60, '', 'TIENDA FRENTE CUARTO PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 4.60),
(977, 5, 18, 'PILA DURACELL', 1.00, 4.80, 4.80, '', 'TIENDA PALERMO', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 4.80),
(978, 5, 22, 'ARROZ EXTRA MERKAT 5KG', 1.00, 16.99, 16.99, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 16.99),
(979, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 3.00, 1.50, 4.50, '1.90', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 4.50),
(980, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.39, 4.39, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 4.39),
(981, 5, 19, 'HUEVOS A GRANEL', 1.48, 5.95, 8.82, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-27', 1, '2020-06-27', 1, '2020-06-27', 8.82),
(982, 5, 18, 'GRATED DE SARDINA BELTRAN 170G', 2.00, 2.30, 4.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-06-27', 1, '2020-06-27', NULL, NULL, 4.60),
(983, 4, 18, 'PAGO ENTEL JUNIO', 1.00, 74.00, 74.00, '', '', 'SABADO', '2020-06-27', 1, '2020-06-28', NULL, NULL, 74.00),
(984, 5, 19, 'POLLO PARTE PIERNA', 0.49, 7.50, 3.70, '', '', 'JUEVES', '2020-07-02', 1, '2020-07-03', NULL, NULL, 3.70),
(985, 5, 19, 'PAPA BLANCA', 1.33, 1.20, 1.60, '', 'TIENDA AL COSTADO CUARTO PALERMO', 'JUEVES', '2020-07-02', 1, '2020-07-03', NULL, NULL, 1.60),
(986, 8, 18, 'PASAJE BUS 23A', 2.00, 1.00, 2.00, '', '', 'SABADO', '2020-07-04', 1, '2020-07-04', NULL, NULL, 2.00),
(987, 5, 19, 'MANDARINA', 1.00, 2.00, 2.00, '', 'TRICICLO AV PASEO DE LA REPUBLICA', 'SABADO', '2020-07-04', 1, '2020-07-04', NULL, NULL, 2.00),
(988, 8, 18, 'PASAJE BUS 23B', 2.00, 1.00, 2.00, '', '', 'SABADO', '2020-07-04', 1, '2020-07-04', NULL, NULL, 2.00),
(989, 5, 19, 'TOMATE', 1.00, 4.00, 4.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 4.00),
(990, 5, 19, 'PAPA BLANCA', 4.00, 1.50, 6.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 6.00),
(991, 5, 19, 'ARVEJA VERDE', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 6.00),
(992, 5, 19, 'FREJOL CASTILLA', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 7.00),
(993, 5, 19, 'POLLO', 1.00, 4.00, 4.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 4.00),
(994, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 4.00, 1.50, 6.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 6.00),
(995, 5, 18, 'PAPEL HIG RINDEMAX NARANJA DH SUAVE 24U', 1.00, 17.00, 17.00, '16.99', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 17.00),
(996, 5, 18, 'SALCHICHA DE POLLO 100GR', 2.00, 1.20, 2.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 2.40),
(997, 5, 18, 'SILLAO KIKKO 160CC', 1.00, 1.60, 1.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-04', 1, '2020-07-05', NULL, NULL, 1.60),
(998, 5, 19, 'HUEVOS A GRANEL', 1.46, 5.95, 8.70, '23 HUEVOS', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-04', 1, '2020-07-05', 1, '2020-07-05', 8.70),
(999, 8, 18, 'PASAJE BUS 23B', 2.00, 1.50, 3.00, '', '', 'LUNES', '2020-07-06', 1, '2020-07-06', NULL, NULL, 3.00),
(1000, 5, 19, 'POLLO PARTE PIERNA', 0.64, 7.80, 5.00, '', '', 'MARTES', '2020-07-07', 1, '2020-07-07', NULL, NULL, 5.00),
(1001, 5, 19, 'PESCADO MERLUZA', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 7.00),
(1002, 5, 18, 'AJO MOLIDO', 1.00, 0.50, 0.50, '', 'MERCADO PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 0.50),
(1003, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', 'TIENDA PAN PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 2.00),
(1004, 5, 19, 'PAPA BLANCA', 4.00, 1.50, 6.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 6.00),
(1005, 5, 19, 'CEBOLLA', 0.50, 4.00, 2.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 2.00),
(1006, 5, 19, 'TOMATE', 0.50, 2.00, 1.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 1.00),
(1007, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 4.00, 1.50, 6.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 6.00),
(1008, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.40, 4.40, '4.39', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 4.40),
(1009, 5, 18, 'SALCHICHA DE POLLO', 2.00, 1.20, 2.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 2.40),
(1010, 5, 19, 'HUEVOS A GRANEL', 1.25, 5.90, 7.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-11', 1, '2020-07-11', NULL, NULL, 7.40),
(1011, 15, 18, 'RECARGA TELEFONO PAPA', 1.00, 10.00, 10.00, '', '', 'LUNES', '2020-07-13', 1, '2020-07-13', 1, '2020-07-13', 10.00),
(1012, 5, 19, 'POLLO PARTE PIERNA', 0.57, 7.50, 4.30, '', '', 'MIERCOLES', '2020-07-15', 1, '2020-07-15', NULL, NULL, 4.30),
(1013, 5, 18, 'EGRESO PERDIDO', 1.00, 14.30, 14.30, '', '', 'MIERCOLES', '2020-07-15', 1, '2020-07-15', 1, '2020-07-15', 14.30),
(1014, 5, 18, 'PAPA BLANCA', 4.00, 1.00, 4.00, '', 'TRICICLO CUARTO PALERMO VIEJITO', 'SABADO', '2020-07-18', 1, '2020-07-18', 1, '2020-07-18', 4.00),
(1015, 5, 19, 'TOMATE', 0.50, 4.00, 2.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 2.00),
(1016, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', 'TIENDA PALERMO', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 2.00),
(1017, 5, 19, 'POLLO', 0.43, 7.00, 3.00, '', '', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 3.00),
(1018, 6, 18, 'LAMISIL CREMA 1% GLAXO SMITHKLINE OT', 1.00, 23.00, 23.00, '23.3', 'MIFARMA', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 23.00),
(1019, 5, 19, 'ARROZ GRANEL', 4.35, 2.69, 11.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 11.70),
(1020, 5, 18, 'SAL DE COCINA MARINA EMSAL', 1.00, 1.80, 1.80, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 1.80),
(1021, 5, 18, 'CREMA ROCOT UCHUCUTA ALACENA', 1.00, 10.00, 10.00, '9.99', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 10.00),
(1022, 5, 19, 'HUEVOS A GRANEL', 1.14, 5.70, 6.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 6.50),
(1023, 5, 18, 'GALLETA SODA SAN JORGE', 1.00, 4.20, 4.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 4.20),
(1024, 5, 19, 'MANDARINA', 1.00, 3.00, 3.00, '', '', 'SABADO', '2020-07-18', 1, '2020-07-18', NULL, NULL, 3.00),
(1025, 5, 18, 'EGRESO PERDIDO', 1.00, 1.00, 1.00, '', '', 'LUNES', '2020-07-20', 1, '2020-07-20', NULL, NULL, 1.00),
(1026, 5, 19, 'POLLO', 0.48, 9.00, 4.30, '', '', 'LUNES', '2020-07-20', 1, '2020-07-20', NULL, NULL, 4.30),
(1027, 3, 18, 'PAGO CUARTO AGOSTO', 1.00, 400.00, 400.00, '', '', 'LUNES', '2020-07-20', 1, '2020-07-21', 1, '2020-07-21', 400.00),
(1028, 17, 18, 'APORTE CUMPLEAÑOS KATY SUBGERENTE', 1.00, 5.00, 5.00, '', '', 'JUEVES', '2020-07-23', 1, '2020-07-23', NULL, NULL, 5.00),
(1029, 5, 19, 'PAPA BLANCA', 3.87, 1.50, 5.80, '', '', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 5.80),
(1030, 8, 18, 'PASAJE BUS 23A', 2.00, 1.50, 3.00, '', '', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 3.00),
(1031, 6, 18, 'PROTECTOR FACIAL', 1.00, 8.50, 8.50, '', 'PLAZA MANCO CAPAC', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 8.50),
(1032, 6, 18, 'ROCIADOR', 1.00, 3.00, 3.00, '', 'PLAZA MANCO CAPAC', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 3.00),
(1033, 7, 18, 'MEMORIA RAM', 1.00, 90.00, 90.00, '', 'COMPU PLAZA', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 90.00),
(1034, 8, 18, 'PASAJE BUS 23B', 2.00, 1.00, 2.00, '', '', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 2.00),
(1035, 5, 18, 'GARBANZO', 1.00, 8.40, 8.40, '', '', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 8.40),
(1036, 5, 18, 'LENTEJA', 1.00, 6.00, 6.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 6.00),
(1037, 5, 19, 'CEBOLLA', 0.50, 2.00, 1.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 1.00),
(1038, 5, 19, 'TOMATE', 1.00, 4.00, 4.00, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 4.00),
(1039, 5, 19, 'HIGADO', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 7.00),
(1040, 5, 18, 'AJI COLORADO', 1.00, 0.50, 0.50, '', 'MERCADO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 0.50),
(1041, 5, 18, 'PEGAMENTO', 2.00, 1.00, 2.00, '', 'COSTADO MERCADILLO PALERMO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 2.00),
(1042, 5, 19, 'MANDARINA', 2.00, 1.50, 3.00, '', 'TRICICLO', 'SABADO', '2020-07-25', 1, '2020-07-25', NULL, NULL, 3.00),
(1043, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 3.00, 1.50, 4.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 4.50),
(1044, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 0.10),
(1045, 5, 18, 'SALCHICHA DE POLLO 100GR', 2.00, 1.20, 2.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 2.40),
(1046, 5, 18, 'CAFE KIRMA LATA 190GR', 1.00, 18.90, 18.90, '190GR', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 18.90),
(1047, 5, 18, 'SILLAO KIKKO 160CC', 1.00, 1.60, 1.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 1.60),
(1048, 5, 19, 'HUEVOS A GRANEL', 0.61, 5.40, 3.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-07-25', 1, '2020-07-26', NULL, NULL, 3.30),
(1049, 5, 19, 'POLLO PIERNA', 0.51, 7.20, 3.70, '', '', 'MIERCOLES', '2020-07-22', 1, '2020-07-26', NULL, NULL, 3.70),
(1050, 8, 18, 'PASAJE BUS 23B', 2.00, 1.50, 3.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 3.00),
(1051, 15, 18, 'MOTO FUMIGADORA', 1.00, 1750.00, 1750.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 1750.00),
(1052, 8, 18, 'PASAJE AUTO', 1.00, 10.00, 10.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 10.00),
(1053, 15, 18, 'PASAJE QORIBUS', 1.00, 35.00, 35.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 35.00),
(1054, 5, 18, 'ENVIO CARGO', 1.00, 15.00, 15.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 15.00),
(1055, 8, 18, 'PASAJE BUS 23B', 2.00, 1.50, 3.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 3.00),
(1056, 5, 19, 'POLLO PIERNA', 0.50, 8.00, 4.00, '', 'TIENDA PALERMO', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 4.00),
(1057, 15, 18, 'APORTE GASTOS PAPA', 1.00, 1500.00, 1500.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', 1, '2020-07-28', 1500.00),
(1058, 15, 18, 'GASTOS CESAR', 1.00, 100.00, 100.00, '', '', 'MARTES', '2020-07-28', 1, '2020-07-28', NULL, NULL, 100.00),
(1059, 4, 18, 'PAGO ENTEL 16 JULIO - 15 AGOSTO', 1.00, 74.00, 74.00, '', '', 'VIERNES', '2020-07-31', 1, '2020-07-31', 1, '2020-07-31', 74.00),
(1060, 8, 18, 'PASAJE VIAJE CESAR Y RETORNO NERIO', 1.00, 15.50, 15.50, '', '', 'MARTES', '2020-07-28', 1, '2020-07-31', 1, '2020-07-31', 15.50),
(1061, 5, 18, 'CUADERNO A4 100H', 1.00, 3.20, 3.20, '', '', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 3.20),
(1062, 5, 19, 'PIERNITAS DE POLLO', 0.17, 5.79, 1.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 1.00),
(1063, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.40, 4.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 4.40),
(1064, 5, 18, 'SALSA DE AJI TARI 400GR', 1.00, 10.00, 10.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 10.00),
(1065, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 0.10),
(1066, 5, 18, 'SAZONADORES GLUTAMATO NAKAMITO 100GR', 1.00, 1.70, 1.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 1.70),
(1067, 5, 19, 'AZUCAR RUBIA GRANEL', 2.39, 2.59, 6.20, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-01', 1, '2020-08-01', NULL, NULL, 6.20),
(1068, 5, 18, '4 IMPRESION Y 4 COPIAS', 1.00, 1.60, 1.60, '4 X 0.3 IMPRESION\n4 × 0.2 COPIA', '', 'MIERCOLES', '2020-08-05', 1, '2020-08-05', NULL, NULL, 1.60),
(1069, 5, 19, 'POLLO 2 PIERNAS', 0.38, 8.00, 3.00, '', 'TIENDA POLLO COSTADO MERCADILLO PALERMO', 'MIERCOLES', '2020-08-05', 1, '2020-08-05', NULL, NULL, 3.00),
(1070, 5, 19, 'TOMATE', 0.52, 5.00, 2.60, '', 'TIENDA FRENTE CUARTO PALERMO', 'MIERCOLES', '2020-08-05', 1, '2020-08-05', NULL, NULL, 2.60),
(1071, 5, 18, 'PASAJE BUS 23A', 2.00, 1.50, 3.00, '', '', 'MARTES', '2020-08-04', 1, '2020-08-05', NULL, NULL, 3.00),
(1072, 4, 18, 'PLAN BITEL 29.9', 1.00, 30.00, 30.00, '29.90 + 0.10 QUE SE LLEVO DE COMISION', 'MANCO CAPAC Y GRAU', 'MARTES', '2020-08-04', 1, '2020-08-05', NULL, NULL, 30.00),
(1073, 6, 18, 'PROTECTOR FACIAL', 1.00, 5.00, 5.00, '', 'FERIA AV. MANCO CAPAC', 'MARTES', '2020-08-04', 1, '2020-08-05', NULL, NULL, 5.00),
(1074, 5, 19, 'MARACUYA', 0.80, 2.50, 2.00, '', 'TRICICLO CUARTO PALERMO', 'MIERCOLES', '2020-08-05', 1, '2020-08-05', NULL, NULL, 2.00),
(1075, 5, 19, 'ARROZ GRANEL', 3.35, 2.69, 9.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 9.00),
(1076, 5, 18, 'HUANCAINA WALIBI DOY PACK', 1.00, 16.90, 16.90, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 16.90),
(1077, 5, 18, 'SALCHICHA DE POLLO 100GR', 2.00, 1.20, 2.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 2.40),
(1078, 5, 19, 'HUEVOS A GRANEL', 1.41, 5.40, 7.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 7.60),
(1079, 5, 18, 'FIDEO TALLARIN GRUESO ALIANZA 500GR', 3.00, 1.50, 4.50, '1.9', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 4.50),
(1080, 5, 19, 'PAPA BLANCA', 2.46, 1.30, 3.20, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 3.20),
(1081, 5, 19, 'POLLO PIERNA', 0.57, 8.00, 4.60, '', 'TIENDA POLLO PALERMO', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 4.60),
(1082, 5, 19, 'PAN FRANCES', 2.00, 1.00, 2.00, '', 'PALERMO', 'SABADO', '2020-08-08', 1, '2020-08-09', NULL, NULL, 2.00),
(1083, 10, 18, 'IMPRESION CONTRATO PRONABEC', 6.00, 0.30, 1.80, '', '', 'VIERNES', '2020-08-14', 1, '2020-08-14', NULL, NULL, 1.80),
(1084, 7, 18, 'PAPEL LUSTRE AZUL', 1.00, 0.50, 0.50, '', '', 'VIERNES', '2020-08-14', 1, '2020-08-14', NULL, NULL, 0.50),
(1085, 7, 18, 'PAPEL LUSTRE AZUL', 2.00, 0.50, 1.00, '', '', 'JUEVES', '2020-08-13', 1, '2020-08-14', 1, '2020-08-14', 1.00),
(1086, 10, 18, 'ESCANEO DOCUMENTOS', 3.00, 0.50, 1.50, '', '', 'VIERNES', '2020-08-14', 1, '2020-08-14', NULL, NULL, 1.50),
(1087, 10, 18, 'COPIA', 1.00, 0.10, 0.10, '', '', 'VIERNES', '2020-08-14', 1, '2020-08-14', NULL, NULL, 0.10),
(1088, 8, 18, 'PASAJE BUS 23A', 2.00, 1.50, 3.00, 'IDA Y VUELTA PLAZA MANCO CAPAC', '', 'SABADO', '2020-08-15', 1, '2020-08-15', NULL, NULL, 3.00),
(1089, 5, 18, 'BROASTER', 1.00, 5.00, 5.00, '', 'PLAZA MANCO CAPAC', 'SABADO', '2020-08-15', 1, '2020-08-15', NULL, NULL, 5.00),
(1090, 5, 19, 'DURAZNO', 0.50, 5.00, 2.50, '', '', 'SABADO', '2020-08-15', 1, '2020-08-16', NULL, NULL, 2.50),
(1091, 7, 18, 'PAPEL ALUMINIO', 1.00, 8.90, 8.90, '', '', 'SABADO', '2020-08-15', 1, '2020-08-16', 1, '2020-08-16', 8.90),
(1092, 5, 18, 'CREMA HUANCAINA ALACENA 85CC', 1.00, 2.90, 2.90, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-15', 1, '2020-08-16', NULL, NULL, 2.90),
(1093, 6, 18, 'JABON NAT ALOE Y OLIVA PALMOLIVE', 1.00, 7.20, 7.20, '3X120GM', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-15', 1, '2020-08-16', 1, '2020-08-16', 7.20),
(1094, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-15', 1, '2020-08-16', NULL, NULL, 0.10),
(1095, 3, 18, 'PAGO CUARTO SETIEMBRE', 1.00, 400.00, 400.00, 'ALQUILER CUARTO 350 + REPARACION 50', '', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 400.00),
(1096, 5, 18, 'PAN', 2.00, 1.00, 2.00, '', 'TIENDA PAN PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 2.00),
(1097, 5, 19, 'TOMATE', 1.00, 3.00, 3.00, '', 'TRICICLO PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 3.00),
(1098, 5, 18, 'BOLSA NEGRA', 1.00, 0.10, 0.10, '', 'TRICICLO PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 0.10),
(1099, 5, 19, 'HUEVO', 0.50, 5.60, 2.80, '', 'TIENDA POLLO PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 2.80),
(1100, 5, 18, 'PALTA', 3.00, 1.00, 3.00, '', 'CARRETA PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 3.00),
(1101, 5, 18, 'PLATANO', 1.00, 1.00, 1.00, '5 PLATANOS', 'TRICICLO PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 1.00),
(1102, 5, 18, 'MARACUYA', 0.73, 3.00, 2.20, '', 'TIENDA FRENTE CUARTO PALERMO', 'LUNES', '2020-08-17', 1, '2020-08-17', NULL, NULL, 2.20);
INSERT INTO egreso (id, id_tipo_egreso, id_unidad_medida, nombre, cantidad, precio, total, descripcion, ubicacion, dia, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod, total_egreso) VALUES
(1103, 5, 18, 'IMPRESION', 6.00, 0.30, 1.80, '', '', 'MARTES', '2020-08-18', 1, '2020-08-18', NULL, NULL, 1.80),
(1104, 23, 18, 'MATRICULA CESAR', 1.00, 832.00, 832.00, '', '', 'MARTES', '2020-08-18', 1, '2020-08-19', NULL, NULL, 832.00),
(1105, 11, 18, 'FICHA C4 RENIEC', 1.00, 7.00, 7.00, '', '', 'MARTES', '2020-08-18', 1, '2020-08-19', NULL, NULL, 7.00),
(1106, 23, 18, 'DEPOSITO COMPRA MATERIALES ELI', 1.00, 160.00, 160.00, '', '', 'JUEVES', '2020-08-20', 1, '2020-08-21', NULL, NULL, 160.00),
(1107, 8, 18, 'PASAJE PALERMO - MANCO CAPAC', 1.00, 1.00, 1.00, '', '', 'SABADO', '2020-08-22', 1, '2020-08-22', 1, '2020-08-22', 1.00),
(1108, 8, 18, 'PASAJE MANCO CAPAC - PALERMO', 1.00, 1.50, 1.50, '', '', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 1.50),
(1109, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 4.00, 1.50, 6.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 6.00),
(1110, 5, 18, 'MAYONESA ALACENA 475GR', 1.00, 7.50, 7.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 7.50),
(1111, 5, 18, 'SALCHICHA DE POLLO 100GR', 2.00, 1.20, 2.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 2.40),
(1112, 5, 18, 'HUEVOS A GRANEL', 0.74, 5.00, 3.72, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 3.72),
(1113, 5, 18, 'POLLO PARTE PIERNA', 0.38, 8.00, 3.00, '', 'MERCADILLO PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 3.00),
(1114, 5, 18, 'PAN FRANCES', 2.00, 1.00, 2.00, '10 PANES', 'TIENDA PAN PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 2.00),
(1115, 5, 18, 'PALTA', 5.00, 1.00, 5.00, '', 'CARRETA', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 5.00),
(1116, 5, 18, 'TARI', 1.00, 7.00, 7.00, '', 'MERCADO PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 7.00),
(1117, 7, 18, 'SILICONA LIQUIDA PEQUEÑO', 1.00, 1.50, 1.50, '', 'MERCADO PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 1.50),
(1118, 5, 18, 'GARBANZO', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 8.00),
(1119, 5, 18, 'LIMOSNA', 1.00, 1.00, 1.00, '', '', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 1.00),
(1120, 5, 19, 'TOMATE', 0.51, 3.50, 1.80, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 1.80),
(1121, 7, 18, 'LAPTOP HP CORE I5 10MA', 1.00, 2550.00, 2550.00, 'I5 10MA GENERACION\n8GB RAM\nWINDOWS HOME ORIGINAL', 'TIENDA ENTRADA WILSON', 'SABADO', '2020-08-22', 1, '2020-08-22', NULL, NULL, 2550.00),
(1122, 7, 18, 'ADAPTADOR TOMACORRINTE DE 3 A 2', 1.00, 3.00, 3.00, '', 'PALERMO', 'LUNES', '2020-08-24', 1, '2020-08-24', NULL, NULL, 3.00),
(1123, 6, 18, 'DETERGENTE ACE 800GR', 1.00, 7.90, 7.90, '', 'MASS PALERMO', 'LUNES', '2020-08-24', 1, '2020-08-24', NULL, NULL, 7.90),
(1124, 11, 18, 'IMPRESIÓN', 4.00, 0.30, 1.20, '', '', 'MIERCOLES', '2020-08-26', 1, '2020-08-26', 1, '2020-08-26', 1.20),
(1125, 11, 18, 'FOTOCOPIA', 2.00, 0.10, 0.20, '', '', 'MIERCOLES', '2020-08-26', 1, '2020-08-26', NULL, NULL, 0.20),
(1126, 8, 18, 'PASAJE BUS', 1.00, 1.20, 1.20, '', '', 'MIERCOLES', '2020-08-26', 1, '2020-08-26', NULL, NULL, 1.20),
(1127, 4, 18, 'PAGO BITEL 25 JULIO - 26 AGOSTO', 1.00, 21.22, 21.22, '', '', 'MARTES', '2020-08-25', 1, '2020-08-26', NULL, NULL, 21.22),
(1128, 4, 18, 'PAGO ENTEL 16 AGOSTO - 15 SETIEMBRE', 1.00, 74.00, 74.00, '', '', 'VIERNES', '2020-08-28', 1, '2020-08-28', NULL, NULL, 74.00),
(1129, 7, 18, 'EXTENSION TOMACORRIENTES', 1.00, 15.00, 15.00, '', '', 'VIERNES', '2020-08-28', 1, '2020-08-28', NULL, NULL, 15.00),
(1130, 8, 18, 'PASAJE BUS 23B', 1.00, 1.50, 1.50, '', '', 'SABADO', '2020-08-29', 1, '2020-08-29', NULL, NULL, 1.50),
(1131, 7, 18, 'MOUSE LOGITECH', 1.00, 30.00, 30.00, 'NO EMITE SONIDO\nRIMETEC 20600059476\nBOLETA DE VENTA\n001-020464', '', 'SABADO', '2020-08-29', 1, '2020-08-29', 1, '2020-08-30', 30.00),
(1132, 8, 18, 'PASAJE BUS NARANJA', 1.00, 2.00, 2.00, '', '', 'SABADO', '2020-08-29', 1, '2020-08-29', NULL, NULL, 2.00),
(1133, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.40, 4.40, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 4.40),
(1134, 5, 18, 'SALCHICHA DE POLLO 100GR', 2.00, 1.20, 2.40, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 2.40),
(1135, 5, 18, 'ESPONJA VERDE ABRA 9X13 C ROBIN 6 UNID', 1.00, 2.50, 2.50, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 2.50),
(1136, 5, 19, 'HUEVOS A GRANEL', 1.04, 5.00, 5.20, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 5.20),
(1137, 5, 18, 'FOSFORO 40 LUCES INTI X 10', 1.00, 2.60, 2.60, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 2.60),
(1138, 5, 18, 'TROZOS ATUN ACEITE VEG A-1 LATA 170GR', 2.00, 3.90, 7.80, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', 1, '2020-08-30', 7.80),
(1139, 5, 19, 'TOMATE', 2.00, 0.50, 1.00, '2KILOS 1 SOL', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 1.00),
(1140, 5, 19, 'FREJOL CASTILLA', 1.00, 7.00, 7.00, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 7.00),
(1141, 5, 18, 'RECIPIENTE CAUCHO', 1.00, 7.00, 7.00, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 7.00),
(1142, 5, 19, 'POLLO MEDIA PIERNA', 0.50, 8.00, 4.00, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 4.00),
(1143, 5, 19, 'MANDARINA', 2.00, 1.50, 3.00, '', '', 'SABADO', '2020-08-29', 1, '2020-08-30', NULL, NULL, 3.00),
(1144, 11, 18, 'LEGALIZACION DE FIRMA NOTARIALMENTE POR PANDEMIA', 1.00, 16.00, 16.00, '', '', 'LUNES', '2020-08-31', 1, '2020-09-01', NULL, NULL, 16.00),
(1145, 11, 18, 'IMPRESION FORMATO 06 PRONABEC', 2.00, 0.50, 1.00, 'RENUNCIA A BECA', '', 'LUNES', '2020-08-31', 1, '2020-09-01', 1, '2020-09-01', 1.00),
(1146, 8, 18, 'PASAJE BUS 23A', 1.00, 1.00, 1.00, '', '', 'MARTES', '2020-09-01', 1, '2020-09-01', NULL, NULL, 1.00),
(1147, 8, 18, 'PASAJE BUS SOL DE ORO', 1.00, 2.00, 2.00, '', '', 'MARTES', '2020-09-01', 1, '2020-09-01', NULL, NULL, 2.00),
(1148, 11, 18, 'ESCANEADO', 2.00, 0.50, 1.00, '', '', 'MARTES', '2020-09-01', 1, '2020-09-01', NULL, NULL, 1.00),
(1149, 8, 18, 'PASAJE BUS23A', 1.00, 1.00, 1.00, '', '', 'VIERNES', '2020-09-04', 1, '2020-09-04', NULL, NULL, 1.00),
(1150, 8, 18, 'PASAJE BUS 23A', 1.00, 1.50, 1.50, '', '', 'VIERNES', '2020-09-04', 1, '2020-09-04', NULL, NULL, 1.50),
(1151, 5, 18, 'PEPSI 500ML', 1.00, 2.00, 2.00, '', '', 'VIERNES', '2020-09-04', 1, '2020-09-04', NULL, NULL, 2.00),
(1152, 5, 19, 'MARACUYA', 1.12, 2.50, 2.80, '', '', 'VIERNES', '2020-09-04', 1, '2020-09-04', NULL, NULL, 2.80),
(1153, 11, 18, 'FOTOCOPIA DNI', 1.00, 0.50, 0.50, '', '', 'LUNES', '2020-08-31', 1, '2020-09-04', NULL, NULL, 0.50),
(1154, 5, 18, 'GAS SANTI GAS', 1.00, 35.00, 35.00, '10KG DE GLP\nBOLET 001-005339', '', 'VIERNES', '2020-09-04', 1, '2020-09-04', NULL, NULL, 35.00),
(1155, 6, 18, 'CORTE CABELLO', 1.00, 12.00, 12.00, '', 'PALERMO', 'SABADO', '2020-09-05', 1, '2020-09-05', NULL, NULL, 12.00),
(1156, 5, 18, 'PAPEL HIGIENICO BOREAL', 1.00, 12.60, 12.60, 'BE29-00349420\nRUC 20100070970', 'MASS PALERMO', 'SABADO', '2020-09-05', 1, '2020-09-05', 1, '2020-09-05', 12.60),
(1157, 5, 19, 'POLLO PIERNA', 0.47, 8.00, 3.80, '', 'MERCADO PALERMO', 'SABADO', '2020-09-05', 1, '2020-09-05', NULL, NULL, 3.80),
(1158, 5, 18, 'TARI 400GR', 1.00, 8.50, 8.50, '', 'MERCADO PALERMO', 'SABADO', '2020-09-05', 1, '2020-09-05', NULL, NULL, 8.50),
(1159, 12, 18, 'ZAPATILLA SKECHERS', 1.00, 230.00, 230.00, '', 'POLVOS AZULES', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 230.00),
(1160, 7, 18, 'CUBRE TECLADO NUMERICO', 1.00, 7.00, 7.00, '', 'WILSON', 'SABADO', '2020-09-12', 1, '2020-09-13', 1, '2020-09-13', 7.00),
(1161, 12, 18, 'CORREA DE CUERO', 1.00, 14.00, 14.00, '', 'AV GRAU', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 14.00),
(1162, 8, 18, 'PASAJE BUS 23B', 1.00, 1.50, 1.50, '', '', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 1.50),
(1163, 8, 18, 'PASAJE BUS 23B', 1.00, 1.50, 1.50, '', '', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 1.50),
(1164, 5, 18, 'FIDEO SPAGUETTI', 3.00, 1.50, 4.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', 1, '2020-09-13', 4.50),
(1165, 5, 19, 'PIERNITAS DE POLLO IMPORTADA', 0.39, 6.49, 2.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 2.50),
(1166, 5, 18, 'FIDEO CODO RAYADO ALIANZA 250GR', 3.00, 0.77, 2.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', 1, '2020-09-13', 2.30),
(1167, 5, 18, 'SALSA DE AJI TARI 400GR', 1.00, 8.30, 8.30, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 8.30),
(1168, 5, 19, 'AZUCAR RUBIA GRANEL', 2.86, 2.59, 7.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 7.40),
(1169, 5, 19, 'SAL DE COCINA MARINA EMSAL 1KG', 1.00, 1.80, 1.80, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 1.80),
(1170, 5, 19, 'HUEVOS A GRANEL', 1.14, 5.60, 6.40, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 6.40),
(1171, 5, 18, 'GRATED DE SARDINA BELTRAN', 2.00, 2.30, 4.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 4.60),
(1172, 5, 19, 'TOMATE', 0.50, 3.00, 1.50, '', 'TRICICLO CUARTO PALERMO', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 1.50),
(1173, 5, 18, 'MANDARINA', 1.00, 1.00, 1.00, '', '', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 1.00),
(1174, 5, 18, 'EGRESO PERDIDO', 1.00, 4.00, 4.00, '', '', 'SABADO', '2020-09-12', 1, '2020-09-13', NULL, NULL, 4.00),
(1175, 11, 18, 'ESCANEO ORDEN COMPRA', 1.00, 0.50, 0.50, '', '', 'LUNES', '2020-09-14', 1, '2020-09-15', NULL, NULL, 0.50),
(1176, 23, 18, 'PAGO INTERNET CASA ELI', 1.00, 50.00, 50.00, '10 SOLES ADELANTO SIGUIENTE MES SOLO PAGAR 30', '', 'LUNES', '2020-09-14', 1, '2020-09-15', NULL, NULL, 50.00),
(1177, 5, 19, 'MANDARINA', 1.00, 2.00, 2.00, '', 'TRICICLO PALERMO', 'JUEVES', '2020-09-17', 1, '2020-09-17', NULL, NULL, 2.00),
(1178, 5, 19, 'CHIRIMOYA', 0.80, 5.00, 4.00, '', 'TIENDA FRUTA PALERMO', 'JUEVES', '2020-09-17', 1, '2020-09-17', NULL, NULL, 4.00),
(1179, 3, 18, 'PAGO CUARTO 16 SETIEMBRE - 15 OCTUBRE', 1.00, 350.00, 350.00, '', '', 'JUEVES', '2020-09-17', 1, '2020-09-17', 1, '2020-09-18', 350.00),
(1180, 5, 19, 'ZANAHORIA', 0.50, 3.00, 1.50, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.50),
(1181, 5, 19, 'ARVEJA VERDE', 0.38, 5.00, 1.90, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.90),
(1182, 5, 18, 'APIO', 1.00, 2.00, 2.00, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 2.00),
(1183, 5, 19, 'POLLO', 0.56, 7.00, 3.90, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 3.90),
(1184, 5, 19, 'PALLAR', 1.00, 8.00, 8.00, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 8.00),
(1185, 5, 19, 'PAPA PERUANITA', 1.00, 3.70, 3.70, '', 'MERCADO PALERMO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 3.70),
(1186, 8, 18, 'PASAJE 23A', 1.00, 1.00, 1.00, '', '', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.00),
(1187, 5, 18, 'LED LAMPARA PARA TECLADO', 1.00, 10.00, 10.00, '', 'COMPUPLAZA', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 10.00),
(1188, 5, 19, 'ZAPALLO', 0.33, 3.00, 1.00, '', 'TRICICLO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.00),
(1189, 5, 18, 'PLATANO', 5.00, 0.30, 1.50, '', 'TRICICLO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.50),
(1190, 5, 19, 'MANDARINA', 1.00, 2.00, 2.00, '', 'TRICICLO', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 2.00),
(1191, 5, 19, 'MARACUYA', 0.40, 3.50, 1.40, '', '', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 1.40),
(1192, 5, 19, 'ARROZ GRANEL', 2.45, 2.69, 6.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 6.60),
(1193, 5, 18, 'BOLSA BIODEGRADABLE', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 0.10),
(1194, 6, 18, 'CEPILLO DEN COLGATE EXTCLEAN DURO 2PZ', 1.00, 5.50, 5.50, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-09-19', 1, '2020-09-19', NULL, NULL, 5.50),
(1195, 5, 18, 'FIDEO SPAGUETTI ALIANZA 500GR', 3.00, 1.50, 4.50, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 4.50),
(1196, 5, 18, 'ACEITE VEGETAL MERKAT 900ML', 1.00, 4.40, 4.40, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 4.40),
(1197, 6, 18, 'JABON NAT ALOE Y OLIVA PALMOLIVE 3X120G', 1.00, 7.20, 7.20, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 7.20),
(1198, 6, 18, 'PASTA DENTAL TRIPACK TRIP ACC DENTO 75M', 1.00, 9.00, 9.00, '8.99', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 9.00),
(1199, 5, 19, 'HUEVOS A GRANEL', 0.98, 5.60, 5.50, '', 'MAXIAHORRO IQUITOS', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 5.50),
(1200, 5, 19, 'POLLO PIERNA', 0.56, 8.00, 4.50, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 4.50),
(1201, 5, 19, 'TOMATE', 0.57, 3.50, 2.00, '', 'MERCADO PALERMO', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 2.00),
(1202, 5, 18, 'PLATANO', 5.00, 0.40, 2.00, '', 'TRICICLO PALERMO', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 2.00),
(1203, 5, 19, 'MARACUYA', 1.12, 2.50, 2.80, '', 'TIENDA FRENTE CUARTO PALERMO', 'MIERCOLES', '2020-09-23', 1, '2020-09-23', NULL, NULL, 2.80),
(1204, 5, 19, 'QUESO', 0.39, 14.00, 5.50, '', 'CALLE PALERMO', 'VIERNES', '2020-09-25', 1, '2020-09-25', NULL, NULL, 5.50),
(1205, 5, 19, 'PAPA BLANCA', 2.50, 1.00, 2.50, '', 'TRICICLO PALERMO', 'VIERNES', '2020-09-25', 1, '2020-09-25', NULL, NULL, 2.50),
(1206, 5, 18, 'CHOCLO', 1.00, 1.20, 1.20, '', 'TRICICLO CUARTO PALERMO', 'VIERNES', '2020-09-25', 1, '2020-09-25', NULL, NULL, 1.20),
(1207, 5, 19, 'CEBOLLA', 0.52, 2.50, 1.30, '', 'TRICICLO CUARTO PALERMO', 'VIERNES', '2020-09-25', 1, '2020-09-25', NULL, NULL, 1.30),
(1208, 5, 19, 'ZAPALLO', 0.50, 2.00, 1.00, '', 'TRICICLO CUARTO PALERMO', 'VIERNES', '2020-09-25', 1, '2020-09-25', NULL, NULL, 1.00),
(1209, 5, 19, 'PESCADO BONITO', 1.79, 7.00, 12.50, '', 'MERCADO PALERMO', 'SABADO', '2020-09-26', 1, '2020-09-26', NULL, NULL, 12.50),
(1210, 5, 19, 'DURASNO', 0.50, 5.00, 2.50, '', 'PALERMO', 'SABADO', '2020-09-26', 1, '2020-09-26', NULL, NULL, 2.50),
(1211, 4, 18, 'PAGO BITEL 25 SETIEMBRE - 24 NOVIEMBRE', 1.00, 29.90, 29.90, '', '', 'SABADO', '2020-09-26', 1, '2020-09-28', 1, '2020-09-28', 29.90),
(1212, 4, 18, 'PAGO ENTEL 16 SETIEMBRE - 15 OCTUBRE', 1.00, 74.00, 74.00, '', '', 'LUNES', '2020-09-28', 1, '2020-09-28', NULL, NULL, 74.00),
(1213, 11, 18, 'PAGO PARA CDS SUSALUD', 1.00, 17.00, 17.00, '', '', 'MARTES', '2020-09-29', 1, '2020-09-29', NULL, NULL, 17.00),
(1214, 5, 18, 'IMPRESION Y COPIAS', 1.00, 3.00, 3.00, '9 IMPRESION 3 COPIAS', '', 'MIERCOLES', '2020-09-30', 1, '2020-09-30', NULL, NULL, 3.00),
(1215, 5, 18, 'TARI', 1.00, 8.80, 8.80, '', '', 'MIERCOLES', '2020-09-30', 1, '2020-09-30', NULL, NULL, 8.80),
(1216, 5, 18, 'MENTITAS', 1.00, 2.00, 2.00, '', '', 'MIERCOLES', '2020-09-30', 1, '2020-09-30', NULL, NULL, 2.00),
(1217, 5, 18, 'MANDARINA', 1.00, 2.00, 2.00, '', '', 'MIERCOLES', '2020-09-30', 1, '2020-09-30', NULL, NULL, 2.00),
(1218, 5, 18, 'PLATANO', 1.00, 1.50, 1.50, '1 MANO', '', 'MIERCOLES', '2020-09-30', 1, '2020-09-30', NULL, NULL, 1.50),
(1219, 5, 19, 'GRANADILLA', 0.58, 5.00, 2.90, '', '', 'VIERNES', '2020-10-02', 1, '2020-10-02', NULL, NULL, 2.90),
(1220, 5, 19, 'PAPA BLANCA', 1.88, 0.80, 1.50, '', '', 'VIERNES', '2020-10-02', 1, '2020-10-02', NULL, NULL, 1.50),
(1221, 5, 19, 'ARROZ GRANEL', 3.61, 2.69, 9.70, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 9.70),
(1222, 5, 18, 'LAVAVAJILLAS LESLY LIMON 400GR', 1.00, 2.00, 2.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 2.00),
(1223, 5, 18, 'TROZOS DE ATUN EN AC. VEGETAL MERKAT 170GR', 2.00, 3.80, 7.60, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 7.60),
(1224, 5, 18, 'BOLSA BIODEGRADABLE ASA BLANCA 17X20', 1.00, 0.10, 0.10, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 0.10),
(1225, 5, 19, 'HUEVOS A GRANEL', 0.54, 5.60, 3.00, '', 'MAXIAHORRO IQUITOS', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 3.00),
(1226, 5, 19, 'CHANCHO', 0.50, 20.00, 10.00, '', '', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 10.00),
(1227, 5, 19, 'TOMATE', 1.00, 2.00, 2.00, '', 'CARRETILLA', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 2.00),
(1228, 5, 19, 'MARACUYA', 0.96, 2.50, 2.40, '', 'TIENDA CUARTO PALERMO', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 2.40),
(1229, 5, 19, 'MANDARINA', 0.50, 3.00, 1.50, '', 'TRICICLO', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 1.50),
(1230, 5, 18, 'PLATANO', 1.00, 2.00, 2.00, '1 MANO', 'TRICICLO', 'SABADO', '2020-10-03', 1, '2020-10-03', NULL, NULL, 2.00),
(1231, 5, 19, 'TOMATE', 0.25, 2.00, 0.50, '', 'CARRETA VIEJITO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 0.50),
(1232, 5, 19, 'PALLARES', 1.00, 6.80, 6.80, '', 'MERCADO PALERMO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 6.80),
(1233, 5, 19, 'FREJOL CASTILLA', 1.00, 6.80, 6.80, '', 'MERCADO PALERMO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 6.80),
(1234, 5, 19, 'GARBANZO', 1.00, 7.50, 7.50, '', 'MERCADO PALERMO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 7.50),
(1235, 5, 18, 'PLATANO', 1.00, 1.50, 1.50, '', 'TRICICLO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 1.50),
(1236, 5, 19, 'MANDARINA', 1.00, 2.50, 2.50, '', 'TRICICLO', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 2.50),
(1237, 5, 19, 'MARACUYA', 0.85, 2.00, 1.70, '', 'TIENDA FRENTE PALERML', 'SABADO', '2020-10-10', 1, '2020-10-12', 1, '2020-10-12', 1.70),
(1238, 6, 18, 'COLLAR ARMY Y ENRIZADORES', 1.00, 54.07, 54.07, '', '', 'LUNES', '2020-10-05', 1, '2020-10-12', NULL, NULL, 54.07),
(1239, 23, 18, 'CABEZAL', 1.00, 130.00, 130.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 130.00),
(1240, 23, 18, 'CAJA RAYOS X', 1.00, 178.00, 178.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 178.00),
(1241, 23, 18, 'CAJA NEWCAINA', 2.00, 61.00, 122.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 122.00),
(1242, 23, 18, 'FORCET', 2.00, 20.00, 40.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 40.00),
(1243, 23, 18, 'MICROBRUSH', 1.00, 9.00, 9.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 9.00),
(1244, 23, 18, 'CAJA AGUJA NOP', 1.00, 18.00, 18.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 18.00),
(1245, 23, 18, 'KID PERNO', 1.00, 68.00, 68.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 68.00),
(1246, 23, 18, 'ESPEJOS', 5.00, 10.00, 50.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 50.00),
(1247, 15, 18, 'PASAJE CESAR', 1.00, 70.00, 70.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 70.00),
(1248, 15, 18, 'REMUNERACION CESAR', 1.00, 200.00, 200.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 200.00),
(1249, 5, 18, 'CHAUFA', 2.00, 10.00, 20.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 20.00),
(1250, 8, 18, 'PASAJE TERMINAL LUNA PIZARRO', 3.00, 1.00, 3.00, '', '', 'JUEVES', '2020-10-15', 1, '2020-10-17', NULL, NULL, 3.00),
(1251, 5, 18, 'EGRESO PERDIDO', 1.00, 7.90, 7.90, '', '', 'MARTES', '2020-10-13', 1, '2020-10-17', NULL, NULL, 7.90),
(1252, 5, 18, 'PASAJE 23A', 2.00, 1.00, 2.00, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 2.00),
(1253, 7, 18, 'MEMORIA RAM DDR3 SODIM 8GB PC312800 KINGSTOM', 1.00, 80.00, 80.00, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', 1, '2020-10-17', 80.00),
(1254, 7, 18, 'DISCO SOLIDO 480GB', 1.00, 230.00, 230.00, '', 'COMPUPLAZA', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 230.00),
(1255, 7, 18, 'CASE ADAPTADOR DISCO DURO', 1.00, 30.00, 30.00, '35 REBAJADO', 'COMPUPLAZA', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 30.00),
(1256, 5, 19, 'POLLO', 0.53, 8.50, 4.50, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 4.50),
(1257, 5, 19, 'HUEVO', 1.00, 5.40, 5.40, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 5.40),
(1258, 5, 19, 'MARACUYA', 0.70, 2.00, 1.40, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 1.40),
(1259, 5, 19, 'TOMATE', 0.92, 2.50, 2.30, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 2.30),
(1260, 5, 19, 'MANGO', 2.00, 2.50, 5.00, '', '', 'SABADO', '2020-10-17', 1, '2020-10-17', NULL, NULL, 5.00),
(1261, 3, 18, 'ALQUILER CUARTO 16 OCT - 15 NOV', 1.00, 350.00, 350.00, '', '', 'SABADO', '2020-10-17', 1, '2020-10-20', NULL, NULL, 350.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla ingreso
--

CREATE TABLE ingreso (
  id bigint(20) UNSIGNED NOT NULL,
  id_tipo_ingreso int(10) UNSIGNED NOT NULL,
  id_movimiento_banco bigint(20) UNSIGNED DEFAULT NULL,
  nombre varchar(150) NOT NULL,
  monto decimal(8,2) UNSIGNED NOT NULL,
  observacion varchar(500) DEFAULT NULL,
  fecha date NOT NULL,
  id_estado int(10) UNSIGNED NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL
);

--
-- Volcado de datos para la tabla ingreso
--

INSERT INTO ingreso (id, id_tipo_ingreso, id_movimiento_banco, nombre, monto, observacion, fecha, id_estado, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod) VALUES
(1, 31, 3, 'RETIRO - INTERBANK', 29.90, 'RETIRO PAGO BITEL', '2019-10-21', 1, 1, '2019-12-02', NULL, NULL),
(2, 31, 9, 'RETIRO - INTERBANK', 2500.00, 'RETIRO PAPA', '2019-11-05', 1, 1, '2019-12-02', NULL, NULL),
(3, 31, 10, 'RETIRO - INTERBANK', 500.00, 'RETIRO PAPA', '2019-11-07', 1, 1, '2019-12-02', NULL, NULL),
(4, 31, 14, 'RETIRO - INTERBANK', 220.00, 'RETIRO CATRE', '2019-11-17', 1, 1, '2019-12-02', NULL, NULL),
(5, 31, 16, 'RETIRO - INTERBANK', 29.90, 'RETIRO BITEL', '2019-11-21', 1, 1, '2019-12-02', NULL, NULL),
(6, 31, 27, 'RETIRO - INTERBANK', 250.00, 'RETIRO CORTE Y PASAJE AYACUCHO', '2019-12-22', 1, 1, '2019-12-22', NULL, NULL),
(7, 31, 29, 'RETIRO - INTERBANK', 29.90, 'RETIRO PAGO BITEL', '2019-12-23', 1, 1, '2019-12-23', NULL, NULL),
(8, 31, 30, 'RETIRO - INTERBANK', 220.00, 'RETIRO VIAJE AYACUCHO', '2019-12-23', 1, 1, '2019-12-24', NULL, NULL),
(9, 31, 35, 'RETIRO - INTERBANK', 320.00, 'RETIRO BUFFET Y PASAJES', '2019-12-29', 1, 1, '2019-12-29', NULL, NULL),
(10, 31, 36, 'RETIRO - INTERBANK', 2000.00, 'RETIRO PAPA', '2020-01-02', 1, 1, '2020-01-02', NULL, NULL),
(11, 31, 42, 'RETIRO - INTERBANK', 40.49, 'RETIRO GASTOS ALIMENTOS', '2020-01-10', 1, 1, '2020-01-11', NULL, NULL),
(12, 31, 1, 'RETIRO - BANCO DE LA NACION', 100.00, 'RETIRO GASTOS', '2019-10-12', 1, 1, '2019-12-02', NULL, NULL),
(13, 31, 2, 'RETIRO - BANCO DE LA NACION', 22.04, 'RETIRO GASTOS', '2019-10-20', 1, 1, '2019-12-02', NULL, NULL),
(14, 31, 4, 'RETIRO - BANCO DE LA NACION', 450.00, 'RETIRO GASTOS', '2019-10-22', 1, 1, '2019-12-02', NULL, NULL),
(15, 31, 5, 'RETIRO - BANCO DE LA NACION', 250.00, 'RETIRO GASTOS', '2019-10-25', 1, 1, '2019-12-02', NULL, NULL),
(16, 31, 6, 'RETIRO - BANCO DE LA NACION', 450.00, 'RETIRO GASTOS', '2019-10-29', 1, 1, '2019-12-02', NULL, NULL),
(17, 31, 13, 'RETIRO - BANCO DE LA NACION', 300.00, 'RETIRO CUARTO', '2019-11-12', 1, 1, '2019-12-02', NULL, NULL),
(18, 31, 19, 'RETIRO - BANCO DE LA NACION', 250.00, 'RETIRO CATRE', '2019-11-27', 1, 1, '2019-12-02', NULL, NULL),
(19, 31, 20, 'RETIRO - BANCO DE LA NACION', 400.00, 'RETIRO LICUADORA', '2019-11-30', 1, 1, '2019-12-02', NULL, NULL),
(20, 31, 25, 'RETIRO - BANCO DE LA NACION', 150.00, 'RETIRO BUFFET', '2019-12-06', 1, 1, '2019-12-07', NULL, NULL),
(21, 31, 26, 'RETIRO - BANCO DE LA NACION', 400.00, 'RETIRO LICUADORA Y OLLA ROCERA', '2019-12-20', 1, 1, '2019-12-20', NULL, NULL),
(22, 31, 34, 'RETIRO - BANCO DE LA NACION', 150.00, 'RETIRO AUDIFONOS', '2019-12-27', 1, 1, '2019-12-28', NULL, NULL),
(23, 32, NULL, 'RETORNO POR MATERIALES DENTALES', 100.00, 'RETORNO POR ENCARGO DE MATERIALES DENTALES', '2020-01-02', 0, 1, '2020-01-12', NULL, NULL),
(24, 31, 43, 'RETIRO - INTERBANK', 29.90, 'RETIRO PAGO BITEL', '2020-01-13', 1, 1, '2020-01-13', NULL, NULL),
(25, 31, 44, 'RETIRO - BANCO DE LA NACION', 20.00, 'RETIRO FOTO', '2020-01-16', 1, 1, '2020-01-16', NULL, NULL),
(26, 31, 45, 'RETIRO - BANCO DE LA NACION', 2.49, 'RETIRO AZUCAR OFICINA', '2020-01-16', 1, 1, '2020-01-16', NULL, NULL),
(27, 31, 46, 'RETIRO - INTERBANK', 20.00, 'RETIRO PASAJE UNIVERSIDAD CIENTIFICA', '2020-01-18', 1, 1, '2020-01-18', NULL, NULL),
(28, 31, 47, 'RETIRO - INTERBANK', 400.00, 'RETIRO PAGO CUARTO', '2020-01-19', 1, 1, '2020-01-20', NULL, NULL),
(29, 31, 48, 'RETIRO - INTERBANK', 11.09, 'RETIRO COMPRA ALIMENTOS', '2020-01-27', 1, 1, '2020-01-28', NULL, NULL),
(30, 31, 49, 'RETIRO - INTERBANK', 220.00, 'RETIRO GASTOS', '2020-01-28', 1, 1, '2020-01-29', NULL, NULL),
(31, 32, NULL, 'CHEQUE PAGO FLV JNE', 600.00, 'INGRESO POR LABORES DESEMPEÑADOS DURANTE LAS ELECCIONES CONGRESALES EXCEPCIONALES 2020', '2020-02-11', 0, 1, '2020-02-11', NULL, NULL),
(33, 31, 55, 'RETIRO - INTERBANK', 500.00, 'RETIRO PRESTAMO URBAY', '2020-02-12', 1, 1, '2020-02-15', NULL, NULL),
(34, 31, 56, 'RETIRO - INTERBANK', 2500.00, 'RETIRO PAPA', '2020-02-15', 1, 1, '2020-02-15', NULL, NULL),
(35, 32, NULL, 'RETORNO MATERIALES ELI', 450.00, 'CORRESPONDIENTE A COMPRAS DE ENERO Y FEBRERO', '2020-02-15', 0, 1, '2020-02-17', 1, '2020-02-17'),
(36, 31, 57, 'RETIRO - INTERBANK', 29.90, 'RETIRO PAGO BITEL', '2020-02-17', 1, 1, '2020-02-18', NULL, NULL),
(37, 31, 58, 'RETIRO - INTERBANK', 20.00, 'RETIRO CAMBIO TARJETA', '2020-02-18', 1, 1, '2020-02-19', NULL, NULL),
(38, 31, 59, 'RETIRO - INTERBANK', 400.00, 'RETIRO CUARTO', '2020-02-19', 1, 1, '2020-02-20', NULL, NULL),
(39, 31, 61, 'RETIRO - INTERBANK', 9.70, 'RETIRO COMPRA MENESTRAS', '2020-02-20', 1, 1, '2020-02-21', NULL, NULL),
(40, 31, 65, 'RETIRO - INTERBANK', 63.60, 'RETIRO BUFFET', '2020-02-29', 1, 1, '2020-03-01', NULL, NULL),
(41, 31, 66, 'RETIRO - BANCO DE LA NACION', 200.00, 'RETIRO GASTOS', '2020-02-29', 1, 1, '2020-03-01', NULL, NULL),
(42, 31, 70, 'RETIRO - INTERBANK', 29.90, 'RETIRO PAGO BITEL ABRIL', '2020-03-08', 1, 1, '2020-03-08', NULL, NULL),
(43, 31, 71, 'RETIRO - INTERBANK', 600.00, 'RETIRO COMPRA MATERIALES DENTALES', '2020-03-11', 1, 1, '2020-03-11', NULL, NULL),
(44, 31, 72, 'RETIRO - INTERBANK', 30.99, 'RETIRO VIVERES', '2020-03-13', 1, 1, '2020-03-14', NULL, NULL),
(45, 31, 73, 'RETIRO - INTERBANK', 800.00, 'RETIRO COMPRA MATERIALES Y ALQUILER', '2020-03-14', 1, 1, '2020-03-15', NULL, NULL),
(46, 31, 74, 'RETIRO - INTERBANK', 500.00, 'RETIRO PAGO CUARTO ABRIL', '2020-03-15', 1, 1, '2020-03-15', NULL, NULL),
(47, 31, 75, 'RETIRO - INTERBANK', 47.45, 'RETIRO COMPRA BIBERES', '2020-03-15', 1, 1, '2020-03-16', NULL, NULL),
(48, 31, 76, 'RETIRO - INTERBANK', 500.00, 'RETIRO VIVERES ABRIL', '2020-03-17', 1, 1, '2020-03-17', NULL, NULL),
(49, 31, 77, 'RETIRO - INTERBANK', 3000.00, 'RETIRO PRESTAMO JHONY', '2020-03-18', 1, 1, '2020-03-21', NULL, NULL),
(50, 31, 78, 'RETIRO - INTERBANK', 3000.00, 'RETIRO PRESTAMO JHONY', '2020-03-20', 1, 1, '2020-03-21', NULL, NULL),
(51, 31, 79, 'RETIRO - INTERBANK', 3000.00, 'RETIRO INTERBANK', '2020-03-21', 1, 1, '2020-03-21', NULL, NULL),
(52, 31, 91, 'RETIRO - INTERBANK', 5.00, 'RECARGA TELEFONO PAPA', '2020-04-08', 1, 1, '2020-04-10', NULL, NULL),
(53, 31, 92, 'RETIRO - INTERBANK', 29.90, 'PAGO BITEL ABRIL', '2020-04-10', 1, 1, '2020-04-11', NULL, NULL),
(54, 31, 94, 'RETIRO - BANCO DE LA NACION', 101.52, 'PAGO TELEFONO CESAR', '2020-04-13', 1, 1, '2020-04-14', NULL, NULL),
(55, 32, NULL, 'INGRESO BONO MAMA', 380.00, '', '2020-04-24', 0, 1, '2020-04-24', NULL, NULL),
(56, 31, 95, 'RETIRO - INTERBANK', 450.00, 'RETIRO PAGO CUARTO', '2020-04-24', 1, 1, '2020-04-24', NULL, NULL),
(57, 31, 96, 'RETIRO - INTERBANK', 49.90, 'RETIRO PAGO CELULAR JHONY', '2020-04-26', 1, 1, '2020-04-27', NULL, NULL),
(58, 32, NULL, 'BONO INDEPENDIENTE MAMA', 380.00, 'BONO INDEPENDIENTE MAMA 380', '2020-05-02', 0, 1, '2020-05-02', NULL, NULL),
(59, 31, 101, 'RETIRO - INTERBANK', 488.00, 'PENSION ABRIL UNIVERSIDAD CONTINENTAL CESAR', '2020-05-02', 1, 1, '2020-05-02', NULL, NULL),
(60, 31, 103, 'RETIRO - BANCO DE LA NACION', 550.00, 'RETIRO GASTOS', '2020-05-09', 1, 1, '2020-05-10', NULL, NULL),
(61, 31, 106, 'RETIRO - BANCO DE LA NACION', 199.00, 'PAGO MODEM ENTEL', '2020-05-11', 1, 1, '2020-05-13', NULL, NULL),
(62, 31, 110, 'RETIRO - INTERBANK', 101.52, 'PAGO TELEF. CESAR MAYO', '2020-05-20', 1, 1, '2020-05-22', NULL, NULL),
(63, 31, 112, 'RETIRO - BANCO DE LA NACION', 12.00, 'RENOVACION TARJETA MULTIRED', '2020-05-20', 1, 1, '2020-05-22', NULL, NULL),
(64, 31, 113, 'RETIRO - INTERBANK', 79.67, 'PAGO ENTEL HOGAR', '2020-05-29', 1, 1, '2020-05-30', NULL, NULL),
(65, 31, 115, 'RETIRO - INTERBANK', 488.00, 'PENSION UNIV CESAR MAYO', '2020-05-30', 1, 1, '2020-05-30', NULL, NULL),
(67, 31, 124, 'RETIRO - INTERBANK', 88.17, 'PAGO TELEF. CESAR JUNIO', '2020-06-12', 1, 1, '2020-06-14', NULL, NULL),
(68, 31, 125, 'RETIRO - INTERBANK', 10.00, 'RECARGA PAPA', '2020-06-19', 1, 1, '2020-06-19', NULL, NULL),
(69, 31, 128, 'RETIRO - BANCO DE LA NACION', 500.00, 'PAGO CUARTO', '2020-06-20', 1, 1, '2020-06-20', NULL, NULL),
(70, 31, 131, 'RETIRO - INTERBANK', 122.00, 'PENSION CESAR JUNIO ATRAZ', '2020-06-23', 1, 1, '2020-06-26', NULL, NULL),
(71, 31, 132, 'RETIRO - INTERBANK', 122.00, 'PENSION CESAR JUNIO ATRAZ', '2020-06-23', 1, 1, '2020-06-26', NULL, NULL),
(72, 31, 133, 'RETIRO - INTERBANK', 610.00, 'PENSION CESAR JUNIO', '2020-06-23', 1, 1, '2020-06-26', NULL, NULL),
(74, 31, 136, 'RETIRO - INTERBANK', 74.00, 'INTERNET ENTEL JUNIO', '2020-06-27', 1, 1, '2020-07-01', NULL, NULL),
(75, 31, 145, 'RETIRO - INTERBANK', 10.00, 'RECARGA TELEFONO PAPA', '2020-07-13', 1, 1, '2020-07-13', NULL, NULL),
(76, 31, 146, 'RETIRO - BANCO DE LA NACION', 950.00, 'PAGO CUARTO Y COMPRAS', '2020-07-18', 1, 1, '2020-07-18', NULL, NULL),
(77, 31, 150, 'RETIRO - INTERBANK', 5.00, 'CUOTA CUMPLEAÑOS KATY SUB GERENTE ESSALU', '2020-07-23', 1, 1, '2020-07-23', NULL, NULL),
(78, 31, 151, 'RETIRO - INTERBANK', 1750.00, 'RETIRO MOTO FUMIGADORA SR420', '2020-07-28', 1, 1, '2020-07-28', NULL, NULL),
(79, 31, 152, 'RETIRO - INTERBANK', 1500.00, 'PENSION CESAR', '2020-07-28', 1, 1, '2020-07-28', NULL, NULL),
(80, 31, 154, 'RETIRO - INTERBANK', 74.00, 'PAGO ENTEL JULIO', '2020-07-31', 1, 1, '2020-07-31', NULL, NULL),
(81, 31, 161, 'RETIRO - BANCO DE LA NACION', 450.00, 'PAGO CUARTO Y ALIMENTACION', '2020-08-15', 1, 1, '2020-08-16', NULL, NULL),
(82, 31, 162, 'RETIRO - INTERBANK', 832.00, 'RETIRO MATICULA CESAR', '2020-08-18', 1, 1, '2020-08-19', NULL, NULL),
(83, 31, 166, 'RETIRO - INTERBANK', 160.00, 'PRESTAMO COMPRA MATERIALES ELI', '2020-08-20', 1, 1, '2020-08-21', NULL, NULL),
(84, 31, 167, 'RETIRO - BANCO DE LA NACION', 19.62, 'RETIRO COMPRAS VIVERES', '2020-08-22', 1, 1, '2020-08-22', NULL, NULL),
(85, 31, 168, 'RETIRO - INTERBANK', 2550.00, 'RETIRO COMPRA LAPTOP', '2020-08-22', 1, 1, '2020-08-22', NULL, NULL),
(86, 31, 169, 'RETIRO - INTERBANK', 21.22, 'PAGO BITEL AGOSTO', '2020-08-25', 1, 1, '2020-08-26', NULL, NULL),
(87, 31, 170, 'RETIRO - INTERBANK', 450.00, 'ALQUILER CUARTO Y COMPRA VIVERES', '2020-08-26', 1, 1, '2020-08-27', NULL, NULL),
(88, 31, 174, 'RETIRO - INTERBANK', 74.00, 'PAGO ENTEL 16 AGOSTO - 15 SETIEMBRE', '2020-08-28', 1, 1, '2020-08-28', NULL, NULL),
(89, 31, 180, 'RETIRO - BANCO DE LA NACION', 320.00, 'RETIRO COMPRA ZAPATO', '2020-09-12', 1, 1, '2020-09-13', NULL, NULL),
(90, 31, 184, 'RETIRO - INTERBANK', 50.00, 'PAGO INTERNET CASA ELI', '2020-09-14', 1, 1, '2020-09-15', NULL, NULL),
(91, 31, 185, 'RETIRO - INTERBANK', 450.00, 'RETIRO PAGO CUARTO SETIEMBRE', '2020-09-17', 1, 1, '2020-09-17', NULL, NULL),
(92, 31, 186, 'RETIRO - INTERBANK', 29.90, 'PAGO BITEL 25 SETIEMBRE - 24 OCTUBRE', '2020-09-26', 1, 1, '2020-09-28', NULL, NULL),
(93, 31, 188, 'RETIRO - INTERBANK', 74.00, 'PAGO ENTEL 16 SETIEMBRE - 15 OCTUBRE', '2020-09-28', 1, 1, '2020-09-28', NULL, NULL),
(94, 31, 189, 'RETIRO - INTERBANK', 17.00, 'PAGO PARA CDS SUSALUD', '2020-09-29', 1, 1, '2020-09-29', NULL, NULL),
(95, 31, 195, 'RETIRO - SCOTIABANK', 54.07, 'DEBITO COMPRAS', '2020-10-05', 1, 1, '2020-10-05', NULL, NULL),
(96, 31, 200, 'RETIRO - INTERBANK', 450.00, 'COMPRA MATERIALES ELI', '2020-10-15', 1, 1, '2020-10-17', NULL, NULL),
(97, 31, 201, 'RETIRO - INTERBANK', 500.00, 'RETIRO PAGO CESAR', '2020-10-15', 1, 1, '2020-10-17', NULL, NULL),
(98, 31, 202, 'RETIRO - INTERBANK', 800.00, 'RETIRO CUARTO Y GASTOS DISCOS MEMORIA', '2020-10-17', 1, 1, '2020-10-17', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla maestra
--

CREATE TABLE maestra (
  id bigint(20) UNSIGNED NOT NULL,
  id_maestra_padre int(10) UNSIGNED DEFAULT NULL,
  orden int(10) UNSIGNED NOT NULL,
  nombre varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  codigo varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  valor varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL,
  id_tabla int(11) UNSIGNED DEFAULT NULL
);

--
-- Volcado de datos para la tabla maestra
--

INSERT INTO maestra (id, id_maestra_padre, orden, nombre, codigo, valor, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod, id_tabla) VALUES
(1, 0, 0, 'TIPO EGRESO', 'TE', '1', 1, '2019-11-13', 1, '2020-01-14', 1),
(2, 0, 0, 'UNIDAD MEDIDA', 'UM', '2', 1, '2019-11-13', 1, '2020-01-14', 2),
(3, 1, 1, 'CUARTO', 'C', '', 1, '2019-11-13', NULL, NULL, NULL),
(4, 1, 2, 'TELEFONIA', 'ST', '', 1, '2019-11-13', 1, '2020-01-14', NULL),
(5, 1, 3, 'ALIMENTACION', 'AL', '', 1, '2019-11-13', NULL, NULL, NULL),
(6, 1, 4, 'ASEO', 'AS', '', 1, '2019-11-13', NULL, NULL, NULL),
(7, 1, 5, 'HABITACIONAL', 'HAB', '', 1, '2019-11-13', NULL, NULL, NULL),
(8, 1, 6, 'PASAJE', 'PSJ', '', 1, '2019-11-13', NULL, NULL, NULL),
(9, 1, 7, 'MEDICINA', 'MED', '', 1, '2019-11-13', NULL, NULL, NULL),
(10, 1, 8, 'EDUCACION', 'EDU', '', 1, '2019-11-13', NULL, NULL, NULL),
(11, 1, 9, 'TRAMITE DOCUMENTARIO', 'TD', '', 1, '2019-11-13', NULL, NULL, NULL),
(12, 1, 10, 'ROPA', 'RP', '', 1, '2019-11-13', NULL, NULL, NULL),
(13, 1, 11, 'VIAJE', 'VJ', '', 1, '2019-11-13', NULL, NULL, NULL),
(14, 1, 12, 'REGALOS', 'RG', '', 1, '2019-11-13', NULL, NULL, NULL),
(15, 1, 13, 'FAMILIA', 'FM', '', 1, '2019-11-13', NULL, NULL, NULL),
(16, 1, 14, 'ENCARGO', 'ECG', '', 1, '2019-11-13', NULL, NULL, NULL),
(17, 1, 15, 'OCACIONAL', 'OCA', '', 1, '2019-11-13', NULL, NULL, NULL),
(18, 2, 1, 'UNIDAD', 'UN', '', 1, '2019-11-13', NULL, NULL, NULL),
(19, 2, 2, 'KILOGRAMO', 'KG', '', 1, '2019-11-13', NULL, NULL, NULL),
(20, 2, 3, 'PAQUETE', 'PQ', '', 1, '2019-11-13', NULL, NULL, NULL),
(21, 2, 4, 'BOTELLA', 'BT', '', 1, '2019-11-13', NULL, NULL, NULL),
(22, 2, 5, 'BOLSA', 'BL', '', 1, '2019-11-17', NULL, NULL, NULL),
(23, 1, 16, 'PRESTAMO', 'PR', '', 1, '2019-11-24', NULL, NULL, NULL),
(24, 0, 0, 'TIPO MOVIMIENTO', 'TM', '3', 1, '2019-12-02', 1, '2020-01-14', 3),
(25, 24, 1, 'DEPOSITO', 'DP', '1', 1, '2019-12-02', NULL, NULL, NULL),
(26, 24, 2, 'RETIRO', 'RT', '2', 1, '2019-12-02', NULL, NULL, NULL),
(27, 24, 3, 'TRANSFERENCIA', 'TR', '3', 1, '2019-12-02', NULL, NULL, NULL),
(28, 24, 4, 'DESCUENTOS', 'DES', '4', 1, '2019-12-02', NULL, NULL, NULL),
(29, 24, 5, 'INTERES', 'INT', '5', 1, '2019-12-02', NULL, NULL, NULL),
(30, 0, 0, 'TIPO INGRESO', 'TI', '4', 1, '2020-01-02', 1, '2020-01-14', NULL),
(31, 30, 1, 'RETIRO CUENTA', 'RC', '1', 1, '2020-01-02', NULL, NULL, NULL),
(32, 30, 2, 'INGRESO EFECTIVO', 'IE', '2', 1, '2020-01-02', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla mensaje
--

CREATE TABLE mensaje (
  id bigint(20) NOT NULL,
  descripcion varchar(10) DEFAULT NULL,
  fecha date DEFAULT NULL
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla migrations
--

CREATE TABLE migrations (
  id int(10) UNSIGNED NOT NULL,
  migration varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  batch int(11) NOT NULL
);

--
-- Volcado de datos para la tabla migrations
--

INSERT INTO migrations (id, migration, batch) VALUES
(10, '2019_11_03_012457_create_egreso_table', 1),
(11, '2019_11_03_162159_create_maestra_table', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla movimiento_banco
--

CREATE TABLE movimiento_banco (
  id bigint(20) UNSIGNED NOT NULL,
  id_cuenta_banco bigint(20) UNSIGNED NOT NULL,
  id_tipo_movimiento int(11) UNSIGNED NOT NULL,
  detalle varchar(50) NOT NULL,
  monto decimal(8,2) UNSIGNED NOT NULL,
  fecha date NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL
);

--
-- Volcado de datos para la tabla movimiento_banco
--

INSERT INTO movimiento_banco (id, id_cuenta_banco, id_tipo_movimiento, detalle, monto, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod) VALUES
(1, 2, 26, 'RETIRO GASTOS', 100.00, '2019-10-12', 1, '2019-12-02', NULL, NULL),
(2, 2, 26, 'RETIRO GASTOS', 22.04, '2019-10-20', 1, '2019-12-02', NULL, NULL),
(3, 1, 26, 'RETIRO PAGO BITEL', 29.90, '2019-10-21', 1, '2019-12-02', NULL, NULL),
(4, 2, 26, 'RETIRO GASTOS', 450.00, '2019-10-22', 1, '2019-12-02', NULL, NULL),
(5, 2, 26, 'RETIRO GASTOS', 250.00, '2019-10-25', 1, '2019-12-02', NULL, NULL),
(6, 2, 26, 'RETIRO GASTOS', 450.00, '2019-10-29', 1, '2019-12-02', NULL, NULL),
(7, 2, 29, 'INTERES OCTUBRE', 0.22, '2019-10-31', 1, '2019-12-02', NULL, NULL),
(8, 1, 29, 'INTERES OCTUBRE', 1.05, '2019-10-31', 1, '2019-12-02', NULL, NULL),
(9, 1, 26, 'RETIRO PAPA', 2500.00, '2019-11-05', 1, '2019-12-02', NULL, NULL),
(10, 1, 26, 'RETIRO PAPA', 500.00, '2019-11-07', 1, '2019-12-02', NULL, NULL),
(11, 1, 25, 'SUELDO OCTUBRE', 4590.00, '2019-11-07', 1, '2019-12-02', NULL, NULL),
(12, 1, 28, 'ITF', 0.20, '2019-11-07', 1, '2019-12-02', NULL, NULL),
(13, 2, 26, 'RETIRO CUARTO', 300.00, '2019-11-12', 1, '2019-12-02', NULL, NULL),
(14, 1, 26, 'RETIRO CATRE', 220.00, '2019-11-17', 1, '2019-12-02', NULL, NULL),
(15, 1, 25, 'GARANTIA CUARTO', 350.00, '2019-11-20', 1, '2019-12-02', NULL, NULL),
(16, 1, 26, 'RETIRO BITEL', 29.90, '2019-11-21', 1, '2019-12-02', NULL, NULL),
(17, 1, 27, 'MOVIMIENTO A CUENTA BN', 1400.00, '2019-11-26', 1, '2019-12-02', NULL, NULL),
(18, 2, 25, 'TRANSFERENCIA DE INTERBANK', 1400.00, '2019-11-26', 1, '2019-12-02', NULL, NULL),
(19, 2, 26, 'RETIRO CATRE', 250.00, '2019-11-27', 1, '2019-12-02', NULL, NULL),
(20, 2, 26, 'RETIRO LICUADORA', 400.00, '2019-11-30', 1, '2019-12-02', NULL, NULL),
(21, 1, 29, 'INTERES NOVIEMBRE', 1.10, '2019-11-30', 1, '2019-12-02', NULL, NULL),
(22, 2, 29, 'INTERES NOVIEMBRE', 0.05, '2019-11-30', 1, '2019-12-02', NULL, NULL),
(23, 1, 25, 'PAGO NOVIEMBRE', 4455.00, '2019-12-05', 1, '2019-12-06', NULL, NULL),
(24, 1, 28, 'ITF PAGO NOVIEMBRE', 0.20, '2019-12-05', 1, '2019-12-06', NULL, NULL),
(25, 2, 26, 'RETIRO BUFFET', 150.00, '2019-12-06', 1, '2019-12-07', NULL, NULL),
(26, 2, 26, 'RETIRO LICUADORA Y OLLA ROCERA', 400.00, '2019-12-20', 1, '2019-12-20', NULL, NULL),
(27, 1, 26, 'RETIRO CORTE Y PASAJE AYACUCHO', 250.00, '2019-12-22', 1, '2019-12-22', NULL, NULL),
(29, 1, 26, 'RETIRO PAGO BITEL', 29.90, '2019-12-23', 1, '2019-12-23', NULL, NULL),
(30, 1, 26, 'RETIRO VIAJE AYACUCHO', 220.00, '2019-12-23', 1, '2019-12-24', NULL, NULL),
(31, 1, 25, 'PAGO ASESORIA PRACTICAS', 100.00, '2019-12-24', 1, '2019-12-24', NULL, NULL),
(32, 1, 25, 'SUELDO DICIEMBRE', 4455.00, '2019-12-26', 1, '2019-12-26', NULL, NULL),
(33, 1, 28, 'ITF DEPOSITO', 0.20, '2019-12-26', 1, '2019-12-26', NULL, NULL),
(34, 2, 26, 'RETIRO AUDIFONOS', 150.00, '2019-12-27', 1, '2019-12-28', NULL, NULL),
(35, 1, 26, 'RETIRO BUFFET Y PASAJES', 320.00, '2019-12-29', 1, '2019-12-29', NULL, NULL),
(36, 1, 26, 'RETIRO PAPA', 2000.00, '2020-01-02', 1, '2020-01-02', NULL, NULL),
(37, 2, 29, 'INTERES DICEMBRE', 0.08, '2019-12-31', 1, '2020-01-03', NULL, NULL),
(38, 1, 29, 'INTERES DICIEMBRE', 1.58, '2019-12-31', 1, '2020-01-03', NULL, NULL),
(41, 1, 28, 'ITF RETIRO', 0.10, '2020-01-02', 1, '2020-01-11', NULL, NULL),
(42, 1, 26, 'RETIRO GASTOS ALIMENTOS', 40.49, '2020-01-10', 1, '2020-01-11', NULL, NULL),
(43, 1, 26, 'RETIRO PAGO BITEL', 29.90, '2020-01-13', 1, '2020-01-13', NULL, NULL),
(44, 2, 26, 'RETIRO FOTO', 20.00, '2020-01-16', 1, '2020-01-16', NULL, NULL),
(45, 2, 26, 'RETIRO AZUCAR OFICINA', 2.49, '2020-01-16', 1, '2020-01-16', NULL, NULL),
(46, 1, 26, 'RETIRO PASAJE UNIVERSIDAD CIENTIFICA', 20.00, '2020-01-18', 1, '2020-01-18', NULL, NULL),
(47, 1, 26, 'RETIRO PAGO CUARTO', 400.00, '2020-01-19', 1, '2020-01-20', NULL, NULL),
(48, 1, 26, 'RETIRO COMPRA ALIMENTOS', 11.09, '2020-01-27', 1, '2020-01-28', NULL, NULL),
(49, 1, 26, 'RETIRO GASTOS', 220.00, '2020-01-28', 1, '2020-01-29', NULL, NULL),
(50, 1, 29, 'INTERES ENERO', 1.72, '2020-01-31', 1, '2020-02-01', NULL, NULL),
(51, 2, 29, 'INTERES ENERO', 0.01, '2020-01-31', 1, '2020-02-01', NULL, NULL),
(52, 1, 25, 'SUELTO ENERO', 5100.00, '2020-02-03', 1, '2020-02-04', NULL, NULL),
(53, 1, 28, 'IFT AUTOMATICA', 0.25, '2020-02-03', 1, '2020-02-04', NULL, NULL),
(55, 1, 26, 'RETIRO PRESTAMO URBAY', 500.00, '2020-02-12', 1, '2020-02-15', NULL, NULL),
(56, 1, 26, 'RETIRO PAPA', 2500.00, '2020-02-15', 1, '2020-02-15', NULL, NULL),
(57, 1, 26, 'RETIRO PAGO BITEL', 29.90, '2020-02-17', 1, '2020-02-18', NULL, NULL),
(58, 1, 26, 'RETIRO CAMBIO TARJETA', 20.00, '2020-02-18', 1, '2020-02-19', NULL, NULL),
(59, 1, 26, 'RETIRO CUARTO', 400.00, '2020-02-19', 1, '2020-02-20', NULL, NULL),
(60, 1, 25, 'RETORNO PRESTAMO', 525.00, '2020-02-20', 1, '2020-02-21', NULL, NULL),
(61, 1, 26, 'RETIRO COMPRA MENESTRAS', 9.70, '2020-02-20', 1, '2020-02-21', NULL, NULL),
(62, 1, 28, 'ITF', 0.10, '2020-02-17', 1, '2020-02-21', NULL, NULL),
(63, 2, 25, 'RETORNO PRESTAMO JONNY', 200.00, '2020-02-25', 1, '2020-02-27', NULL, NULL),
(64, 1, 29, 'INTERES FEBRERO', 1.88, '2020-02-29', 1, '2020-03-01', NULL, NULL),
(65, 1, 26, 'RETIRO BUFFET', 63.60, '2020-02-29', 1, '2020-03-01', NULL, NULL),
(66, 2, 26, 'RETIRO GASTOS', 200.00, '2020-02-29', 1, '2020-03-01', NULL, NULL),
(67, 2, 29, 'INTERES FEBRERO', 0.01, '2020-03-01', 1, '2020-03-02', NULL, NULL),
(68, 1, 25, 'PAGO FEBRERO', 4950.00, '2020-03-05', 1, '2020-03-06', NULL, NULL),
(69, 1, 28, 'IFT AUTOMA', 0.20, '2020-03-05', 1, '2020-03-06', NULL, NULL),
(70, 1, 26, 'RETIRO PAGO BITEL ABRIL', 29.90, '2020-03-08', 1, '2020-03-08', NULL, NULL),
(71, 1, 26, 'RETIRO COMPRA MATERIALES DENTALES', 600.00, '2020-03-11', 1, '2020-03-11', NULL, NULL),
(72, 1, 26, 'RETIRO VIVERES', 30.99, '2020-03-13', 1, '2020-03-14', NULL, NULL),
(73, 1, 26, 'RETIRO COMPRA MATERIALES Y ALQUILER', 800.00, '2020-03-14', 1, '2020-03-15', NULL, NULL),
(74, 1, 26, 'RETIRO PAGO CUARTO ABRIL', 500.00, '2020-03-15', 1, '2020-03-15', NULL, NULL),
(75, 1, 26, 'RETIRO COMPRA BIBERES', 47.45, '2020-03-15', 1, '2020-03-16', NULL, NULL),
(76, 1, 26, 'RETIRO VIVERES ABRIL', 500.00, '2020-03-17', 1, '2020-03-17', NULL, NULL),
(77, 1, 26, 'RETIRO PRESTAMO JHONY', 3000.00, '2020-03-18', 1, '2020-03-21', NULL, NULL),
(78, 1, 26, 'RETIRO PRESTAMO JHONY', 3000.00, '2020-03-20', 1, '2020-03-21', NULL, NULL),
(79, 1, 26, 'RETIRO INTERBANK', 3000.00, '2020-03-21', 1, '2020-03-21', NULL, NULL),
(83, 1, 28, 'ITF 00120297', 0.15, '2020-03-18', 1, '2020-03-30', NULL, NULL),
(84, 1, 28, 'ITF 00109023', 0.15, '2020-03-20', 1, '2020-03-30', NULL, NULL),
(85, 1, 28, 'ITF 00174801', 0.15, '2020-03-23', 1, '2020-03-30', NULL, NULL),
(86, 1, 29, 'INTERES GANADO MARZO', 1.82, '2020-03-31', 1, '2020-04-02', NULL, NULL),
(87, 1, 25, 'PAGO MARZO', 4950.00, '2020-04-01', 1, '2020-04-02', NULL, NULL),
(88, 1, 28, 'IFT AUTOMA', 0.20, '2020-04-01', 1, '2020-04-02', NULL, NULL),
(89, 2, 29, 'INTERES MARZO', 0.01, '2020-03-31', 1, '2020-04-02', NULL, NULL),
(90, 2, 25, 'DECRETO URGENCIA 027-2020 BONO COVID19', 380.00, '2020-04-07', 1, '2020-04-10', NULL, NULL),
(91, 1, 26, 'RECARGA TELEFONO PAPA', 5.00, '2020-04-08', 1, '2020-04-10', NULL, NULL),
(92, 1, 26, 'PAGO BITEL ABRIL', 29.90, '2020-04-10', 1, '2020-04-11', NULL, NULL),
(93, 1, 25, 'RETORNO DESCUENTOS AFP HABITAT (-0.05 ITF)', 1520.97, '2020-04-14', 1, '2020-04-14', NULL, NULL),
(94, 2, 26, 'PAGO TELEFONO CESAR', 101.52, '2020-04-13', 1, '2020-04-14', NULL, NULL),
(95, 1, 26, 'RETIRO PAGO CUARTO', 450.00, '2020-04-24', 1, '2020-04-24', NULL, NULL),
(96, 1, 26, 'RETIRO PAGO CELULAR JHONY', 49.90, '2020-04-26', 1, '2020-04-27', NULL, NULL),
(97, 2, 25, 'BONO COVID19 - DECRETO URGENCIA 027-2020', 380.00, '2020-04-28', 1, '2020-04-30', NULL, NULL),
(98, 1, 25, 'PAGO CUARTO MAMA', 300.00, '2020-04-28', 1, '2020-04-30', NULL, NULL),
(99, 1, 29, 'INTERES ABRIL', 1.74, '2020-04-30', 1, '2020-05-01', NULL, NULL),
(100, 2, 29, 'INTERES ABRIL', 0.06, '2020-04-30', 1, '2020-05-01', NULL, NULL),
(101, 1, 26, 'PENSION ABRIL UNIVERSIDAD CONTINENTAL CESAR', 488.00, '2020-05-02', 1, '2020-05-02', NULL, NULL),
(102, 2, 25, 'PAGO CUARTO NAZARENAS', 200.00, '2020-05-08', 1, '2020-05-10', NULL, NULL),
(103, 2, 26, 'RETIRO GASTOS', 550.00, '2020-05-09', 1, '2020-05-10', NULL, NULL),
(104, 1, 25, 'APORTE PRESTAMO CESAR', 30.00, '2020-05-04', 1, '2020-05-13', NULL, NULL),
(105, 1, 25, 'APORTE PRESTAMO CESAR', 60.00, '2020-05-11', 1, '2020-05-13', NULL, NULL),
(106, 2, 26, 'PAGO MODEM ENTEL', 199.00, '2020-05-11', 1, '2020-05-13', NULL, NULL),
(107, 2, 25, 'DEPOSITO ALQUILER CUARTO', 200.00, '2020-05-11', 1, '2020-05-13', NULL, NULL),
(108, 2, 25, 'DEPOSITO JHONY PAGO CESAR', 200.00, '2020-05-11', 1, '2020-05-13', NULL, NULL),
(109, 1, 25, 'PAGO SUELDO CSTI MAYO - PARTE 1', 1789.00, '2020-05-20', 1, '2020-05-22', NULL, NULL),
(110, 1, 26, 'PAGO TELEF. CESAR MAYO', 101.52, '2020-05-20', 1, '2020-05-22', NULL, NULL),
(111, 1, 25, 'SUELDO CSTI MAYO - PARTE 2', 411.00, '2020-05-22', 1, '2020-05-22', NULL, NULL),
(112, 2, 26, 'RENOVACION TARJETA MULTIRED', 12.00, '2020-05-20', 1, '2020-05-22', NULL, NULL),
(113, 1, 26, 'PAGO ENTEL HOGAR', 79.67, '2020-05-29', 1, '2020-05-30', NULL, NULL),
(114, 1, 29, 'INTERES MAYO', 1.90, '2020-05-31', 1, '2020-05-30', NULL, NULL),
(115, 1, 26, 'PENSION UNIV CESAR MAYO', 488.00, '2020-05-30', 1, '2020-05-30', NULL, NULL),
(116, 2, 25, 'DEPOSITO ALQUILER CUARTO', 150.00, '2020-05-28', 1, '2020-05-30', NULL, NULL),
(117, 2, 29, 'INTERES MAYO', 0.10, '2020-05-31', 1, '2020-06-01', NULL, NULL),
(118, 2, 25, 'ALUILER CUARTO', 200.00, '2020-06-04', 1, '2020-06-04', NULL, NULL),
(119, 1, 25, 'DEPOSITO VLADI PAGO 1', 100.00, '2020-06-05', 1, '2020-06-14', NULL, NULL),
(121, 1, 25, 'DEPOSITO AMIGO CESAR', 30.00, '2020-06-09', 1, '2020-06-14', NULL, NULL),
(122, 1, 25, 'DEPOSITO VLADI PAGO 2', 100.00, '2020-06-07', 1, '2020-06-14', NULL, NULL),
(123, 1, 25, 'DEPOSITO VLADI PAGO 3', 200.00, '2020-06-12', 1, '2020-06-14', NULL, NULL),
(124, 1, 26, 'PAGO TELEF. CESAR JUNIO', 88.17, '2020-06-12', 1, '2020-06-14', NULL, NULL),
(125, 1, 26, 'RECARGA PAPA', 10.00, '2020-06-19', 1, '2020-06-19', NULL, NULL),
(126, 1, 25, 'DEPOSITO VLADI PAGO 4', 100.00, '2020-06-18', 1, '2020-06-19', NULL, NULL),
(127, 2, 25, 'ALQUILER CUARTO MAMA', 150.00, '2020-06-15', 1, '2020-06-19', NULL, NULL),
(128, 2, 26, 'PAGO CUARTO', 500.00, '2020-06-20', 1, '2020-06-20', NULL, NULL),
(129, 2, 25, 'ALQUILER CUARTO MAMA', 300.00, '2020-06-20', 1, '2020-06-21', NULL, NULL),
(130, 1, 25, 'DEPOSITO X', 84.00, '2020-06-22', 1, '2020-06-26', NULL, NULL),
(131, 1, 26, 'PENSION CESAR JUNIO ATRAZ', 122.00, '2020-06-23', 1, '2020-06-26', NULL, NULL),
(132, 1, 26, 'PENSION CESAR JUNIO ATRAZ', 122.00, '2020-06-23', 1, '2020-06-26', NULL, NULL),
(133, 1, 26, 'PENSION CESAR JUNIO', 610.00, '2020-06-23', 1, '2020-06-26', NULL, NULL),
(134, 1, 25, 'DEPOSITO VLADI 5', 100.00, '2020-06-24', 1, '2020-06-26', NULL, NULL),
(136, 1, 26, 'INTERNET ENTEL JUNIO', 74.00, '2020-06-27', 1, '2020-07-01', NULL, NULL),
(137, 1, 25, 'DEPOSITO VLADI 6', 200.00, '2020-06-29', 1, '2020-07-01', NULL, NULL),
(138, 1, 29, 'INTERES JUNIO', 1.93, '2020-06-30', 1, '2020-07-03', NULL, NULL),
(139, 1, 25, 'DEPOSITO VLADI 7', 200.00, '2020-07-03', 1, '2020-07-03', NULL, NULL),
(140, 2, 29, 'INTERES JUNIO', 0.15, '2020-06-30', 1, '2020-07-03', NULL, NULL),
(141, 2, 25, 'ALQUILER CUARTO MAMA', 200.00, '2020-07-04', 1, '2020-07-05', NULL, NULL),
(142, 1, 25, 'DEPOSITO AMIGO CESAR', 100.00, '2020-07-03', 1, '2020-07-05', NULL, NULL),
(143, 2, 25, 'ALQUILER CUARTO MAMA', 200.00, '2020-07-07', 1, '2020-07-10', NULL, NULL),
(144, 1, 25, 'DEPOSITO VLADI 8', 200.00, '2020-07-10', 1, '2020-07-11', NULL, NULL),
(145, 1, 26, 'RECARGA TELEFONO PAPA', 10.00, '2020-07-13', 1, '2020-07-13', NULL, NULL),
(146, 2, 26, 'PAGO CUARTO Y COMPRAS', 950.00, '2020-07-18', 1, '2020-07-18', NULL, NULL),
(147, 1, 25, 'SUELDO JUNIO', 6000.00, '2020-07-22', 1, '2020-07-22', NULL, NULL),
(148, 1, 28, 'ITF AUTOMA', 0.30, '2020-07-22', 1, '2020-07-22', NULL, NULL),
(149, 1, 25, 'PAGO VLADI 9', 200.00, '2020-07-22', 1, '2020-07-23', NULL, NULL),
(150, 1, 26, 'CUOTA CUMPLEAÑOS KATY SUB GERENTE ESSALU', 5.00, '2020-07-23', 1, '2020-07-23', NULL, NULL),
(151, 1, 26, 'RETIRO MOTO FUMIGADORA SR420', 1750.00, '2020-07-28', 1, '2020-07-28', NULL, NULL),
(152, 1, 26, 'PENSION CESAR', 1500.00, '2020-07-28', 1, '2020-07-28', NULL, NULL),
(153, 1, 28, 'DESC PAGO MOTO FUMIGADORA', 0.10, '2020-07-28', 1, '2020-07-29', NULL, NULL),
(154, 1, 26, 'PAGO ENTEL JULIO', 74.00, '2020-07-31', 1, '2020-07-31', NULL, NULL),
(155, 1, 25, 'PAGO VLADI 10', 200.00, '2020-07-31', 1, '2020-07-31', NULL, NULL),
(156, 1, 29, 'INTERES JULIO', 2.19, '2020-07-31', 1, '2020-08-01', NULL, NULL),
(157, 2, 29, 'INTERES JULIO', 0.13, '2020-07-31', 1, '2020-08-01', NULL, NULL),
(158, 1, 25, 'SUELDO JULIO', 6000.00, '2020-08-10', 1, '2020-08-10', NULL, NULL),
(159, 1, 28, 'ITF AUTOMA', 0.30, '2020-08-10', 1, '2020-08-10', NULL, NULL),
(160, 2, 25, 'DEPOSITO CUARTO MAMA', 300.00, '2020-08-10', 1, '2020-08-10', NULL, NULL),
(161, 2, 26, 'PAGO CUARTO Y ALIMENTACION', 450.00, '2020-08-15', 1, '2020-08-16', NULL, NULL),
(162, 1, 26, 'RETIRO MATICULA CESAR', 832.00, '2020-08-18', 1, '2020-08-19', NULL, NULL),
(163, 3, 25, 'NOTA DE ABONO AGOSTO', 325.16, '2020-08-13', 1, '2020-08-19', NULL, NULL),
(164, 3, 28, 'CARGO POR IMPUESTO A LAS TRANSACCIONES FINANCIERAS', 0.05, '2020-08-17', 1, '2020-08-19', NULL, NULL),
(165, 3, 25, 'NOTA DE ABONO LAPTOP', 1625.84, '2020-08-17', 1, '2020-08-19', NULL, NULL),
(166, 1, 26, 'PRESTAMO COMPRA MATERIALES ELI', 160.00, '2020-08-20', 1, '2020-08-21', NULL, NULL),
(167, 2, 26, 'RETIRO COMPRAS VIVERES', 19.62, '2020-08-22', 1, '2020-08-22', NULL, NULL),
(168, 1, 26, 'RETIRO COMPRA LAPTOP', 2550.00, '2020-08-22', 1, '2020-08-22', NULL, NULL),
(169, 1, 26, 'PAGO BITEL AGOSTO', 21.22, '2020-08-25', 1, '2020-08-26', NULL, NULL),
(170, 1, 26, 'ALQUILER CUARTO Y COMPRA VIVERES', 450.00, '2020-08-26', 1, '2020-08-27', NULL, NULL),
(171, 1, 28, 'ITF 00377752', 0.10, '2020-08-24', 1, '2020-08-27', NULL, NULL),
(172, 1, 25, 'SUELDO AGOSTO', 6000.00, '2020-08-28', 1, '2020-08-28', NULL, NULL),
(173, 1, 28, 'ITF AUTOMA', 0.30, '2020-08-28', 1, '2020-08-28', NULL, NULL),
(174, 1, 26, 'PAGO ENTEL 16 AGOSTO - 15 SETIEMBRE', 74.00, '2020-08-28', 1, '2020-08-28', NULL, NULL),
(175, 3, 25, 'ABONO PRONABEC 2', 1260.00, '2020-08-28', 1, '2020-09-01', NULL, NULL),
(176, 3, 28, 'CARGO POR IMPUESTO A LAS TRANSACCIONES FINANCIERAS', 0.05, '2020-08-28', 1, '2020-09-02', NULL, NULL),
(177, 1, 29, 'INTERES AGOSTO', 2.75, '2020-08-31', 1, '2020-09-05', NULL, NULL),
(178, 2, 29, 'INTERES SETIEMBRE', 0.05, '2020-08-31', 1, '2020-09-06', NULL, NULL),
(179, 2, 25, 'DEPOSITO CUARTO MAMA', 200.00, '2020-09-09', 1, '2020-09-13', NULL, NULL),
(180, 2, 26, 'RETIRO COMPRA ZAPATO', 320.00, '2020-09-12', 1, '2020-09-13', NULL, NULL),
(181, 1, 25, 'PAGO ADELANTO APP PANADERIA', 150.00, '2020-09-07', 1, '2020-09-15', NULL, NULL),
(182, 1, 25, 'PAGO ADELANTO APP PANADERIA 2', 150.00, '2020-09-07', 1, '2020-09-15', NULL, NULL),
(183, 1, 25, 'DEPOSITO CLASES DAVID - PELAO', 50.00, '2020-09-14', 1, '2020-09-15', NULL, NULL),
(184, 1, 26, 'PAGO INTERNET CASA ELI', 50.00, '2020-09-14', 1, '2020-09-15', NULL, NULL),
(185, 1, 26, 'RETIRO PAGO CUARTO SETIEMBRE', 450.00, '2020-09-17', 1, '2020-09-17', NULL, NULL),
(186, 1, 26, 'PAGO BITEL 25 SETIEMBRE - 24 OCTUBRE', 29.90, '2020-09-26', 1, '2020-09-28', NULL, NULL),
(187, 3, 29, 'INTERES AGOSTO', 0.18, '2020-08-31', 1, '2020-09-28', NULL, NULL),
(188, 1, 26, 'PAGO ENTEL 16 SETIEMBRE - 15 OCTUBRE', 74.00, '2020-09-28', 1, '2020-09-28', NULL, NULL),
(189, 1, 26, 'PAGO PARA CDS SUSALUD', 17.00, '2020-09-29', 1, '2020-09-29', NULL, NULL),
(190, 1, 29, 'INTERES SETIEMBRE', 0.10, '2020-09-30', 1, '2020-10-02', NULL, NULL),
(191, 1, 27, 'TRANSFERENCIA SCOTIABANK', 100.00, '2020-10-02', 1, '2020-10-02', NULL, NULL),
(192, 3, 25, 'INTERES SETIEMBRE', 0.53, '2020-09-30', 1, '2020-10-02', NULL, NULL),
(193, 2, 25, 'INTERES SETIEMBRE', 0.01, '2020-09-30', 1, '2020-10-02', NULL, NULL),
(194, 4, 25, 'TRANSFERENCIA INTERBANK', 100.00, '2020-10-05', 1, '2020-10-05', NULL, NULL),
(195, 4, 26, 'DEBITO COMPRAS', 54.07, '2020-10-05', 1, '2020-10-05', NULL, NULL),
(196, 1, 25, 'SUELDO SETIEMBRE', 6000.00, '2020-10-05', 1, '2020-10-05', NULL, NULL),
(197, 1, 28, 'ITF AUTOMA', 0.30, '2020-10-05', 1, '2020-10-05', NULL, NULL),
(198, 1, 25, 'TRABAJOS DE CESAR', 50.00, '2020-10-12', 1, '2020-10-14', NULL, NULL),
(199, 2, 25, 'DE´PSITO CUARTO MAMA', 200.00, '2020-10-12', 1, '2020-10-14', NULL, NULL),
(200, 1, 26, 'COMPRA MATERIALES ELI', 450.00, '2020-10-15', 1, '2020-10-17', NULL, NULL),
(201, 1, 26, 'RETIRO PAGO CESAR', 500.00, '2020-10-15', 1, '2020-10-17', NULL, NULL),
(202, 1, 26, 'RETIRO CUARTO Y GASTOS DISCOS MEMORIA', 800.00, '2020-10-17', 1, '2020-10-17', NULL, NULL),
(203, 1, 25, 'PAGO PRESTAMO MATERIALES ELI', 615.00, '2020-10-19', 1, '2020-10-22', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla retorno_egreso
--

CREATE TABLE retorno_egreso (
  id bigint(20) UNSIGNED NOT NULL,
  id_egreso bigint(20) UNSIGNED NOT NULL,
  id_ingreso bigint(20) UNSIGNED DEFAULT NULL,
  id_movimiento_banco bigint(20) UNSIGNED DEFAULT NULL,
  monto decimal(8,2) UNSIGNED NOT NULL,
  fecha date NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL
);

--
-- Volcado de datos para la tabla retorno_egreso
--

INSERT INTO retorno_egreso (id, id_egreso, id_ingreso, id_movimiento_banco, monto, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod) VALUES
(1, 327, 23, NULL, 3.50, '2020-01-02', 1, '2020-01-12', NULL, NULL),
(2, 326, 23, NULL, 30.00, '2020-01-02', 1, '2020-01-12', NULL, NULL),
(3, 325, 23, NULL, 45.00, '2020-01-02', 1, '2020-01-12', NULL, NULL),
(4, 324, 23, NULL, 21.50, '2020-01-02', 1, '2020-01-12', NULL, NULL),
(21, 548, 35, NULL, 120.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(22, 547, 35, NULL, 12.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(23, 546, 35, NULL, 26.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(24, 545, 35, NULL, 7.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(25, 544, 35, NULL, 22.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(26, 543, 35, NULL, 14.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(27, 542, 35, NULL, 30.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(28, 541, 35, NULL, 18.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(29, 421, 35, NULL, 70.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(30, 420, 35, NULL, 2.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(31, 419, 35, NULL, 2.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(32, 418, 35, NULL, 40.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(33, 417, 35, NULL, 25.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(34, 416, 35, NULL, 25.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(35, 415, 35, NULL, 37.00, '2020-02-15', 0, '2020-02-15', NULL, NULL),
(36, 414, 35, NULL, 0.00, '2020-02-15', 0, '2020-02-15', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla saldo_mensual
--

CREATE TABLE saldo_mensual (
  id bigint(20) UNSIGNED NOT NULL,
  dia int(10) UNSIGNED NOT NULL,
  mes int(10) UNSIGNED NOT NULL,
  anio int(10) UNSIGNED NOT NULL,
  monto decimal(8,2) UNSIGNED NOT NULL,
  fecha date NOT NULL,
  id_usuario_crea int(10) UNSIGNED NOT NULL,
  fec_usuario_crea date NOT NULL,
  id_usuario_mod int(10) UNSIGNED DEFAULT NULL,
  fec_usuario_mod date DEFAULT NULL
);

--
-- Volcado de datos para la tabla saldo_mensual
--

INSERT INTO saldo_mensual (id, dia, mes, anio, monto, fecha, id_usuario_crea, fec_usuario_crea, id_usuario_mod, fec_usuario_mod) VALUES
(1, 10, 9, 2019, 50.00, '2019-10-10', 1, '2019-10-10', NULL, NULL),
(4, 1, 11, 2019, 603.00, '2019-12-01', 1, '2019-12-01', NULL, NULL),
(5, 1, 0, 2020, 197.70, '2020-01-02', 1, '2020-01-02', NULL, NULL),
(6, 1, 1, 2020, 196.10, '2020-02-01', 1, '2020-02-01', NULL, NULL),
(7, 1, 2, 2020, 250.00, '2020-03-01', 1, '2020-03-01', NULL, NULL),
(8, 1, 3, 2020, 385.60, '2020-04-01', 1, '2020-04-01', NULL, NULL),
(9, 1, 4, 2020, 430.40, '2020-05-01', 1, '2020-05-01', NULL, NULL),
(10, 1, 5, 2020, 441.80, '2020-06-01', 1, '2020-06-01', NULL, NULL),
(11, 1, 6, 2020, 201.40, '2020-07-03', 1, '2020-07-03', NULL, NULL),
(12, 1, 7, 2020, 176.70, '2020-08-01', 1, '2020-08-01', NULL, NULL),
(13, 1, 8, 2020, 337.10, '2020-09-01', 1, '2020-09-01', NULL, NULL),
(14, 1, 9, 2020, 233.30, '2020-10-01', 1, '2020-10-01', NULL, NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla cuenta_banco
--
ALTER TABLE cuenta_banco
  ADD PRIMARY KEY (id);

--
-- Indices de la tabla egreso
--
ALTER TABLE egreso
  ADD PRIMARY KEY (id);

--
-- Indices de la tabla ingreso
--
ALTER TABLE ingreso
  ADD PRIMARY KEY (id),
  ADD KEY fk_ingr_mov_banc (id_movimiento_banco);

--
-- Indices de la tabla maestra
--
ALTER TABLE maestra
  ADD PRIMARY KEY (id);

--
-- Indices de la tabla mensaje
--
ALTER TABLE mensaje
  ADD PRIMARY KEY (id);

--
-- Indices de la tabla migrations
--
ALTER TABLE migrations
  ADD PRIMARY KEY (id);

--
-- Indices de la tabla movimiento_banco
--
ALTER TABLE movimiento_banco
  ADD PRIMARY KEY (id),
  ADD KEY movimiento_banco_ibfk_1 (id_cuenta_banco);

--
-- Indices de la tabla retorno_egreso
--
ALTER TABLE retorno_egreso
  ADD PRIMARY KEY (id),
  ADD KEY fk_egre_ret_egre (id_egreso);

--
-- Indices de la tabla saldo_mensual
--
ALTER TABLE saldo_mensual
  ADD PRIMARY KEY (id);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla cuenta_banco
--
ALTER TABLE cuenta_banco
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla egreso
--
ALTER TABLE egreso
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1262;

--
-- AUTO_INCREMENT de la tabla ingreso
--
ALTER TABLE ingreso
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=99;

--
-- AUTO_INCREMENT de la tabla maestra
--
ALTER TABLE maestra
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla mensaje
--
ALTER TABLE mensaje
  MODIFY id bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla migrations
--
ALTER TABLE migrations
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla movimiento_banco
--
ALTER TABLE movimiento_banco
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=204;

--
-- AUTO_INCREMENT de la tabla retorno_egreso
--
ALTER TABLE retorno_egreso
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT de la tabla saldo_mensual
--
ALTER TABLE saldo_mensual
  MODIFY id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;
COMMIT;
