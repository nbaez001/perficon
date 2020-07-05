<?php

namespace App\Http\Dao;

use App\Http\Dto\ApiOutResponse;
use App\Http\Dto\Request\BuscarCuentaBancoRequest;
use App\Http\Dto\Response\CuentaBancoResponse;
use DB;

class CuentaBancoDao
{
    public function listarCuentaBanco(BuscarCuentaBancoRequest $req)
    {
        $rs = DB::select('call PFC_L_CUENTA_BANCO(?,?,@cod,@msg)', [$req->getFechaInicio(), $req->getFechaFin()]);
        $resp = DB::select('select @cod as rcodigo, @msg as rmensaje');

        $lista = array();
        if ($resp[0]->rcodigo == 0) {
            foreach ($rs as $i => $val) {
                $obj = new CuentaBancoResponse();
                $obj->setId(intval($val->ID));
                $obj->setNroCuenta($val->NRO_CUENTA);
                $obj->setCci($val->CCI);
                $obj->setNombre($val->NOMBRE);
                $obj->setMonto(floatval($val->MONTO));
                $obj->setIdUsuarioCrea(intval($val->ID_USUARIO_CREA));
                $obj->setFecUsuarioCrea($val->FEC_USUARIO_CREA);
                $obj->setIdUsuarioMod(intval($val->ID_USUARIO_MOD));
                $obj->setFecUsuarioMod($val->FEC_USUARIO_MOD);

                $lista[] = $obj;
            }
        }

        $out = new ApiOutResponse($resp[0]->rcodigo, $resp[0]->rmensaje, $lista);
        return $out;
    }
}
