<?php

namespace App\Http\Dao;

use App\Http\Dto\ApiOutResponse;
use App\Http\Dto\LineChartResponse;
use DB;

class DashBoardDao
{
    public function lineChart($req)
    {
        $rs = DB::select('call PFC_S_LINE_CHART(?,?,@cod,@msg)', [$req['anio'], $req['mes']]);
        $resp = DB::select('select @cod as rcodigo, @msg as rmensaje');

        $lista = array();
        foreach ($rs as $i => $val) {
            $obj = new LineChartResponse();
            $obj->setLabel($val->label);
            $obj->setData(floatval($val->data));
            $obj->setDataIng(floatval($val->dataIng));
            $obj->setDataIngMov(floatval($val->dataIngMov));

            $lista[] = $obj;
        }

        $out = new ApiOutResponse($resp[0]->rcodigo, $resp[0]->rmensaje, $lista);
        return $out;
    }
}
