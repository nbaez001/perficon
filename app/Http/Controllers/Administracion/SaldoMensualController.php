<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use App\Model\SaldoMensual;
use Illuminate\Http\Request;
use DB;
use DateTime;

class SaldoMensualController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function list()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function calcular(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateMod = new DateTime($data['fecUsuarioCrea']);
        $fechaCrea = $dateMod->format('Y-m-d');
        $date = new DateTime($data['fecha']);
        $fecha = $date->format('Y-m-d');

        $resp = DB::select('call PFC_S_SALDO_MENSUAL(?,?)', [$data['mes'], $data['anio']]);
        if (sizeof($resp) > 0) {
            //YA EXISTE RETORNAR TRUE
        } else {
            $resp = DB::select('call PFC_C_SALDO_MENSUAL(?,?,?,?,?,?)', [$data['dia'], $data['mes'], $data['anio'], $fecha, $data['idUsuarioCrea'], $fechaCrea]);
        }
        return response()->json($resp);
    }

    /**
     * Show the form for creating a new resource.
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function obtenerActual(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $date = new DateTime($data['fecha']);
        $fecha = $date->format('Y-m-d');

        $resp = DB::select('call PFC_S_SALDO_ACTUAL(?,?,?,?)', [$data['dia'], $data['mes'], $data['anio'], $fecha]);
        return response()->json($resp);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function obtener(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_S_SALDO_MENSUAL(?,?)', [$data['mes'], $data['anio']]);
        return response()->json($resp);
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Model\SaldoMensual  $saldoMensual
     * @return \Illuminate\Http\Response
     */
    public function edit(SaldoMensual $saldoMensual)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Model\SaldoMensual  $saldoMensual
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, SaldoMensual $saldoMensual)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Model\SaldoMensual  $saldoMensual
     * @return \Illuminate\Http\Response
     */
    public function destroy(SaldoMensual $saldoMensual)
    {
        //
    }
}
