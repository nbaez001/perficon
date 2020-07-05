<?php

namespace App\Http\Dao;

use App\Http\Dto\ApiOutResponse;
use App\Http\Dto\Request\BuscarWalletRequest;
use App\Http\Dto\Response\WalletResponse;
use DB;

class WalletDao
{
    public function listarWallet(BuscarWalletRequest $req)
    {
        $rs = DB::select('call PFC_L_WALLET(?,?,@cod,@msg)', [$req->getFechaInicio(), $req->getFechaFin()]);
        $resp = DB::select('select @cod as rcodigo, @msg as rmensaje');

        $lista = array();
        if ($resp[0]->rcodigo == 0) {
            foreach ($rs as $i => $val) {
                $obj = new WalletResponse();
                $obj->setId(intval($val->ID));
                $obj->setNombre($val->NOMBRE);
                $obj->setMonto($val->MONTO);
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
