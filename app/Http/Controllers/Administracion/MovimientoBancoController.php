<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use App\Model\MovimientoBanco;
use Illuminate\Http\Request;
use DateTime;
use DB;

class MovimientoBancoController extends Controller
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

        $lista = DB::select('call PFC_L_MOVIMIENTO_BANCO(?,?,?,?)', [$data['idCuentaBanco'], $data['indicio'], $resultInicio, $resultFin]);
        return response()->json($lista);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateCrea = new DateTime($data['fecUsuarioCrea']);
        $fechaCrea = $dateCrea->format('Y-m-d');
        $date = new DateTime($data['fecha']);
        $fecha = $date->format('Y-m-d');

        $resp = DB::select('call PFC_I_MOVIMIENTO_BANCO(?,?,?,?,?,?,?,?)', [$data['idCuentaBanco'], $data['idTipoMovimiento'], $data['valTipoMovimiento'], $data['detalle'], $data['monto'], $fecha, $data['idUsuarioCrea'], $fechaCrea]);
        return response()->json($resp);
    }

    /**
     * Display the specified resource.
     *
     * @param  Request  $request
     * @return \Illuminate\Http\Response
     */
    public function show(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $objeto = DB::select('call PFC_S_MOVIMIENTO_BANCO(?)', [$data['id']]);
        return response()->json($objeto);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request)
    {
        // $data = json_decode($request->getContent(), true);

        // $dateMod = new DateTime($data['fecUsuarioMod']);
        // $fechaMod = $dateMod->format('Y-m-d');
        // $date = new DateTime($data['fecha']);
        // $fecha = $date->format('Y-m-d');

        // $resp = DB::select('call PFC_U_MOVIMIENTO_BANCO(?,?,?,?,?,?,?,?)', [$data['id'], $data['idCuentaBanco'], $data['idTipoMovimiento'], $data['detalle'], $data['nombre'], $fecha, $data['idUsuarioMod'], $fechaMod]);
        // return response()->json($resp);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function destroy(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $resp = DB::select('call PFC_D_MOVIMIENTO_BANCO(?,?,?,?)', [$data['id'], $data['idCuentaBanco'], $data['idTipoMovimiento'], $data['monto']]);
        return response()->json($resp);
    }
}
