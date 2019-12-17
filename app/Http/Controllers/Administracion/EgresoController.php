<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use DateTime;
use DB;

class EgresoController extends Controller
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

        $lista = DB::select('call PFC_L_EGRESO(?,?,?,?,?)', [$data['idTipoEgreso'], $data['dia'], $data['indicio'], $resultInicio, $resultFin]);
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
        $resultCrea = $dateCrea->format('Y-m-d');
        $date = new DateTime($data['fecha']);
        $result = $date->format('Y-m-d');

        $resp = DB::select('call PFC_I_EGRESO(?,?,?,?,?,?,?,?,?,?,?,?)', [$data['idTipoEgreso'], $data['idUnidadMedida'], $data['nombre'], $data['cantidad'], $data['precio'], $data['total'], $data['descripcion'], $data['ubicacion'], $data['dia'], $result, $data['idUsuarioCrea'], $resultCrea]);
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
        // $data = json_decode($request->getContent(), true);
        // $objeto = DB::select('call PFC_S_EGRESO(?)', [$data['id']]);
        // return response()->json($objeto);
    }

    /**
     * Update the specified resource in storage.
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

        $resp = DB::select('call PFC_U_EGRESO(?,?,?,?,?,?,?,?,?,?,?,?,?)', [$data['id'], $data['idTipoEgreso'], $data['idUnidadMedida'], $data['nombre'], $data['cantidad'], $data['precio'], $data['total'], $data['descripcion'], $data['ubicacion'], $data['dia'], $result, $data['idUsuarioMod'], $resultMod]);
        return response()->json($resp);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        //
    }
}
