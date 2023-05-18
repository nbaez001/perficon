-- phpMyAdmin SQL Dump
-- version 4.9.4
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 04-03-2020 a las 15:57:13
-- Versión del servidor: 10.3.22-MariaDB
-- Versión de PHP: 7.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `elnazare_perficon`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_C_SALDO_MENSUAL` (IN `dia` INT, IN `mes` INT, IN `anio` INT, IN `fecha` DATE, IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_D_MOVIMIENTO_BANCO` (IN `idt` BIGINT, IN `id_cuenta_banco` BIGINT, IN `id_tipo_movimiento` INT, IN `monto` DECIMAL(8,2))  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_I_CUENTA_BANCO` (IN `nro_cuenta` VARCHAR(20), IN `cci` VARCHAR(20), IN `nombre` VARCHAR(50), IN `saldo` DECIMAL(8,2), IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_I_EGRESO` (IN `id_tipo_egreso` INT, IN `id_unidad_medida` INT, IN `nombre` VARCHAR(100), IN `cantidad` DECIMAL(8,2), IN `precio` DECIMAL(8,2), IN `total` DECIMAL(8,2), IN `descripcion` VARCHAR(500), IN `ubicacion` VARCHAR(100), IN `dia` VARCHAR(10), IN `fecha` DATE, IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_I_INGRESO` (IN `id_tipo_ingreso` INT, IN `nombre` VARCHAR(150), IN `monto` DECIMAL(8,2), IN `observacion` VARCHAR(500), IN `fecha` DATE, IN `id_estado` INT, IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE, IN `json` JSON)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_I_MAESTRA` (IN `id_maestra_padre` INT, IN `orden` INT, IN `nombre` VARCHAR(100), IN `codigo` VARCHAR(10), IN `valor` VARCHAR(50), IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_I_MOVIMIENTO_BANCO` (IN `id_cuenta_banco` BIGINT, IN `id_tipo_movimiento` INT, IN `val_tipo_movimiento` INT, IN `detalle` VARCHAR(50), IN `monto` DECIMAL(8,2), IN `fecha` DATE, IN `id_usuario_crea` INT, IN `fec_usuario_crea` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_CUENTA_BANCO` ()  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_EGRESO` (IN `id_tipo_egreso` INT, IN `dia` VARCHAR(10), IN `indicio` VARCHAR(50), IN `fecha_inicio` DATE, IN `fecha_fin` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_EGRESO_RET` (IN `id_ingreso` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_INGRESO` (IN `id_tipo_ingreso` INT, IN `indicio` VARCHAR(50), IN `fecha_inicio` DATE, IN `fecha_fin` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_MAESTRA` (IN `id_maestra_padre` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_L_MOVIMIENTO_BANCO` (IN `id_cuenta_banco` INT, IN `indicio` VARCHAR(50), IN `fecha_inicio` DATE, IN `fecha_fin` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_BAR_CHART` (IN `anio` INT, IN `mes` INT, IN `dia` INT, IN `cant_dias` INT, IN `cant_dias_prev` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_CUENTA_BANCO` (IN `id` BIGINT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_EGRESO` ()  BEGIN
  SELECT * FROM egreso;
END$$

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_LINE_CHART` (IN `anio` INT, IN `mes` INT)  BEGIN
DECLARE rcodigo INT unsigned DEFAULT 0;
DECLARE rmensaje varchar(100) DEFAULT '';
DECLARE vcontador INT unsigned DEFAULT 1;
DECLARE vjson varchar(600) DEFAULT '[]';
DECLARE vanio INT unsigned DEFAULT anio;
DECLARE vmes INT unsigned DEFAULT (mes + 1);
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 rcodigo = RETURNED_SQLSTATE,rmensaje = MESSAGE_TEXT;
		ROLLBACK;
		SELECT rcodigo, rmensaje;
	END;
START TRANSACTION;
	SET rmensaje = 'Consulta exitosa';
	simple_loop: LOOP
		SELECT JSON_ARRAY_APPEND(vjson,'$', JSON_OBJECT('label',(vmes-1),'data',(SELECT IF(SUM(e.total) IS NULL, 0, SUM(e.total)) FROM egreso e WHERE YEAR(e.fecha) = vanio AND MONTH(e.fecha) = vmes))) INTO vjson;
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
	SELECT rcodigo AS 'rcodigo', rmensaje AS 'rmensaje', vjson AS 'result';
END$$

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_MAESTRA` (IN `id` BIGINT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_MOVIMIENTO_BANCO` (IN `id` BIGINT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_PIE_CHART` (IN `anio` INT, IN `id_tabla` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_SALDO_ACTUAL` (IN `dia` INT, IN `mes` INT, IN `anio` INT, IN `fecha` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_SALDO_MENSUAL` (IN `mes` INT, IN `anio` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_S_SUMA_CATEGORIA` (IN `anio` INT, IN `mes` INT, IN `id_tabla` INT)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_U_CUENTA_BANCO` (IN `id` INT, IN `nro_cuenta` VARCHAR(20), IN `cci` VARCHAR(20), IN `nombre` VARCHAR(50), IN `saldo` DECIMAL(8,2), IN `id_usuario_mod` INT, IN `fec_usuario_mod` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_U_EGRESO` (IN `id` INT, IN `id_tipo_egreso` INT, IN `id_unidad_medida` INT, IN `nombre` VARCHAR(100), IN `cantidad` DECIMAL(8,2), IN `precio` DECIMAL(8,2), IN `total` DECIMAL(8,2), IN `descripcion` VARCHAR(500), IN `ubicacion` VARCHAR(100), IN `dia` VARCHAR(10), IN `fecha` DATE, IN `id_usuario_mod` INT, IN `fec_usuario_mod` DATE)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_U_INGRESO` (IN `id` INT, IN `id_tipo_ingreso` INT, IN `nombre` VARCHAR(150), IN `monto` DECIMAL(8,2), IN `observacion` VARCHAR(500), IN `fecha` DATE, IN `id_usuario_mod` INT, IN `fec_usuario_mod` DATE, IN `json` JSON)  BEGIN
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

CREATE DEFINER=`elnazare`@`localhost` PROCEDURE `PFC_U_MAESTRA` (IN `id` BIGINT, IN `id_maestra_padre` INT, IN `orden` INT, IN `nombre` VARCHAR(100), IN `codigo` VARCHAR(10), IN `valor` VARCHAR(50), IN `id_usuario_mod` INT, IN `fec_usuario_mod` DATE)  BEGIN
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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuenta_banco`
--

CREATE TABLE `cuenta_banco` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nro_cuenta` varchar(20) NOT NULL,
  `cci` varchar(20) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `saldo` decimal(8,2) UNSIGNED NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `cuenta_banco`
--

INSERT INTO `cuenta_banco` (`id`, `nro_cuenta`, `cci`, `nombre`, `saldo`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`) VALUES
(1, '2003131017214', '00320001313101721436', 'INTERBANK', 17612.38, 1, '2019-12-02', NULL, NULL),
(2, '04058587007', '01800000405858700700', 'BANCO DE LA NACION', 58.54, 1, '2019-12-02', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `egreso`
--

CREATE TABLE `egreso` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `id_tipo_egreso` int(10) UNSIGNED NOT NULL,
  `id_unidad_medida` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `cantidad` decimal(8,2) UNSIGNED NOT NULL,
  `precio` decimal(8,2) UNSIGNED NOT NULL,
  `total` decimal(8,2) UNSIGNED NOT NULL,
  `descripcion` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ubicacion` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dia` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha` date NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL,
  `total_egreso` decimal(8,2) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `egreso`
--

INSERT INTO `egreso` (`id`, `id_tipo_egreso`, `id_unidad_medida`, `nombre`, `cantidad`, `precio`, `total`, `descripcion`, `ubicacion`, `dia`, `fecha`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`, `total_egreso`) VALUES
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
INSERT INTO `egreso` (`id`, `id_tipo_egreso`, `id_unidad_medida`, `nombre`, `cantidad`, `precio`, `total`, `descripcion`, `ubicacion`, `dia`, `fecha`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`, `total_egreso`) VALUES
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
(632, 5, 18, 'FIDEOS BELLS', 2.00, 1.40, 2.80, '', 'MASS PALERMO', 'MARTES', '2020-03-03', 1, '2020-03-04', NULL, NULL, 2.80);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ingreso`
--

CREATE TABLE `ingreso` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `id_tipo_ingreso` int(10) UNSIGNED NOT NULL,
  `id_movimiento_banco` bigint(20) UNSIGNED DEFAULT NULL,
  `nombre` varchar(150) NOT NULL,
  `monto` decimal(8,2) UNSIGNED NOT NULL,
  `observacion` varchar(500) DEFAULT NULL,
  `fecha` date NOT NULL,
  `id_estado` int(10) UNSIGNED NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `ingreso`
--

INSERT INTO `ingreso` (`id`, `id_tipo_ingreso`, `id_movimiento_banco`, `nombre`, `monto`, `observacion`, `fecha`, `id_estado`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`) VALUES
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
(41, 31, 66, 'RETIRO - BANCO DE LA NACION', 200.00, 'RETIRO GASTOS', '2020-02-29', 1, 1, '2020-03-01', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `maestra`
--

CREATE TABLE `maestra` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `id_maestra_padre` int(10) UNSIGNED DEFAULT NULL,
  `orden` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `codigo` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL,
  `id_tabla` int(11) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `maestra`
--

INSERT INTO `maestra` (`id`, `id_maestra_padre`, `orden`, `nombre`, `codigo`, `valor`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`, `id_tabla`) VALUES
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
-- Estructura de tabla para la tabla `mensaje`
--

CREATE TABLE `mensaje` (
  `id` bigint(20) NOT NULL,
  `descripcion` varchar(10) DEFAULT NULL,
  `fecha` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(10, '2019_11_03_012457_create_egreso_table', 1),
(11, '2019_11_03_162159_create_maestra_table', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimiento_banco`
--

CREATE TABLE `movimiento_banco` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `id_cuenta_banco` bigint(20) UNSIGNED NOT NULL,
  `id_tipo_movimiento` int(11) UNSIGNED NOT NULL,
  `detalle` varchar(50) NOT NULL,
  `monto` decimal(8,2) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `movimiento_banco`
--

INSERT INTO `movimiento_banco` (`id`, `id_cuenta_banco`, `id_tipo_movimiento`, `detalle`, `monto`, `fecha`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`) VALUES
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
(67, 2, 29, 'INTERES FEBRERO', 0.01, '2020-03-01', 1, '2020-03-02', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `retorno_egreso`
--

CREATE TABLE `retorno_egreso` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `id_egreso` bigint(20) UNSIGNED NOT NULL,
  `id_ingreso` bigint(20) UNSIGNED DEFAULT NULL,
  `id_movimiento_banco` bigint(20) UNSIGNED DEFAULT NULL,
  `monto` decimal(8,2) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `retorno_egreso`
--

INSERT INTO `retorno_egreso` (`id`, `id_egreso`, `id_ingreso`, `id_movimiento_banco`, `monto`, `fecha`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`) VALUES
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
-- Estructura de tabla para la tabla `saldo_mensual`
--

CREATE TABLE `saldo_mensual` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `dia` int(10) UNSIGNED NOT NULL,
  `mes` int(10) UNSIGNED NOT NULL,
  `anio` int(10) UNSIGNED NOT NULL,
  `monto` decimal(8,2) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `id_usuario_crea` int(10) UNSIGNED NOT NULL,
  `fec_usuario_crea` date NOT NULL,
  `id_usuario_mod` int(10) UNSIGNED DEFAULT NULL,
  `fec_usuario_mod` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `saldo_mensual`
--

INSERT INTO `saldo_mensual` (`id`, `dia`, `mes`, `anio`, `monto`, `fecha`, `id_usuario_crea`, `fec_usuario_crea`, `id_usuario_mod`, `fec_usuario_mod`) VALUES
(1, 10, 9, 2019, 50.00, '2019-10-10', 1, '2019-10-10', NULL, NULL),
(4, 1, 11, 2019, 603.00, '2019-12-01', 1, '2019-12-01', NULL, NULL),
(5, 1, 0, 2020, 197.70, '2020-01-02', 1, '2020-01-02', NULL, NULL),
(6, 1, 1, 2020, 196.10, '2020-02-01', 1, '2020-02-01', NULL, NULL),
(7, 1, 2, 2020, 250.00, '2020-03-01', 1, '2020-03-01', NULL, NULL);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cuenta_banco`
--
ALTER TABLE `cuenta_banco`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `egreso`
--
ALTER TABLE `egreso`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `ingreso`
--
ALTER TABLE `ingreso`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_ingr_mov_banc` (`id_movimiento_banco`);

--
-- Indices de la tabla `maestra`
--
ALTER TABLE `maestra`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `mensaje`
--
ALTER TABLE `mensaje`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `movimiento_banco`
--
ALTER TABLE `movimiento_banco`
  ADD PRIMARY KEY (`id`),
  ADD KEY `movimiento_banco_ibfk_1` (`id_cuenta_banco`);

--
-- Indices de la tabla `retorno_egreso`
--
ALTER TABLE `retorno_egreso`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_egre_ret_egre` (`id_egreso`);

--
-- Indices de la tabla `saldo_mensual`
--
ALTER TABLE `saldo_mensual`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cuenta_banco`
--
ALTER TABLE `cuenta_banco`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `egreso`
--
ALTER TABLE `egreso`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=633;

--
-- AUTO_INCREMENT de la tabla `ingreso`
--
ALTER TABLE `ingreso`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT de la tabla `maestra`
--
ALTER TABLE `maestra`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `mensaje`
--
ALTER TABLE `mensaje`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT de la tabla `movimiento_banco`
--
ALTER TABLE `movimiento_banco`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=68;

--
-- AUTO_INCREMENT de la tabla `retorno_egreso`
--
ALTER TABLE `retorno_egreso`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT de la tabla `saldo_mensual`
--
ALTER TABLE `saldo_mensual`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
