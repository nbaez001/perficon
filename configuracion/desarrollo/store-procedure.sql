DROP PROCEDURE IF EXISTS PFC_S_EMPRESA_LICENCIA;

DELIMITER $$

CREATE PROCEDURE PFC_S_EMPRESA_LICENCIA (IN P_RUC VARCHAR(11),OUT R_CODIGO INT, OUT R_MENSAJE VARCHAR(250), OUT R_OBJETO VARCHAR(10))  BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1 R_CODIGO = RETURNED_SQLSTATE,R_MENSAJE = MESSAGE_TEXT;
		ROLLBACK;
		SELECT R_CODIGO, R_MENSAJE;
	END;
START TRANSACTION;
	SET R_CODIGO = 0;
	SET R_MENSAJE = 'OPERACION EXITOSA';
	SELECT DATE_FORMAT(E.LICENCIA,'%Y-%m-%d') INTO R_OBJETO
    FROM EMPRESA E WHERE E.RUC = P_RUC;
	
	SELECT R_CODIGO AS 'R_CODIGO', R_MENSAJE AS 'R_MENSAJE', R_OBJETO AS 'R_OBJETO';
END$$

-- CALLING
CALL PFC_S_EMPRESA_LICENCIA('20602899161', @R_CODIGO, @R_MENSAJE,@R_OBJETO);
SELECT @R_CODIGO AS R_CODIGO, @R_MENSAJE AS R_MENSAJE;