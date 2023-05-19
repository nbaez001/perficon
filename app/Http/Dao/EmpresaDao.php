<?php

namespace App\Http\Dao;

use App\Http\Dto\ApiOutResponse;
use DB;

class EmpresaDao
{
    public function obtenerLicencia($req)
    {
        $rs = DB::select('call PFC_S_EMPRESA_LICENCIA(?,@R_CODIGO,@R_MENSAJE,@R_OBJETO)', [$req['ruc']]);
        $resp = DB::select('select @R_CODIGO as rcodigo, @R_MENSAJE as rmensaje, @R_OBJETO as robjeto');

        $out = new ApiOutResponse($resp[0]->rcodigo, $resp[0]->rmensaje,  $resp[0]->robjeto);
        return $out;
    }
}
