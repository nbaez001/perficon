<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use App\Model\Ingreso;
use Illuminate\Http\Request;
use DateTime;
use DB;

class IngresoController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @param  Request  $request
     * @return \Illuminate\Http\Response
     */
    public function list(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $resultInicio = null;
        $resultFin = null;
        if ($data['fechaInicio'] != null) {
            $dateInicio = new DateTime($data['fechaInicio']);
            $resultInicio = $dateInicio->format('Y-m-d');
        }
        if ($data['fechaFin'] != null) {
            $dateFin = new DateTime($data['fechaFin']);
            $resultFin = $dateFin->format('Y-m-d');
        }

        $lista = DB::select('call PFC_L_INGRESO(?,?,?,?)', [$data['idTipoIngreso'], $data['indicio'], $resultInicio, $resultFin]);
        return response()->json($lista);
    }

    /**
     * Show the form for creating a new resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateCrea = new DateTime($data['fecUsuarioCrea']);
        $resultCrea = $dateCrea->format('Y-m-d');
        $date = new DateTime($data['fecha']);
        $result = $date->format('Y-m-d');

        $resp = DB::select('call PFC_I_INGRESO(?,?,?,?,?,?,?,?,?)', [$data['idTipoIngreso'], $data['nombre'], $data['monto'], $data['observacion'], $result, $data['idEstado'], $data['idUsuarioCrea'], $resultCrea, $data['json']]);
        return response()->json($resp);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Model\Ingreso  $ingreso
     * @return \Illuminate\Http\Response
     */
    public function show(Ingreso $ingreso)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateMod = new DateTime($data['fecUsuarioMod']);
        $resultMod = $dateMod->format('Y-m-d');
        $date = new DateTime($data['fecha']);
        $result = $date->format('Y-m-d');

        $resp = DB::select('call PFC_U_INGRESO(?,?,?,?,?,?,?,?,?)', [$data['id'], $data['idTipoIngreso'], $data['nombre'], $data['monto'], $data['observacion'], $result, $data['idUsuarioMod'], $resultMod, $data['json']]);
        return response()->json($resp);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Model\Ingreso  $ingreso
     * @return \Illuminate\Http\Response
     */
    public function destroy(Ingreso $ingreso)
    {
        //
    }

    /**
     * Display a listing of the resource.
     *
     * @param  Request  $request
     * @return \Illuminate\Http\Response
     */
    public function listaEgresoRetorno(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $lista = DB::select('call PFC_L_EGRESO_RET(?)', [$data['id']]);
        return response()->json($lista);
    }
}
