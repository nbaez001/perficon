<?php

namespace App\Http\Controllers\Configuration;

use App\Http\Controllers\Controller;
use App\Model\CuentaBanco;
use Illuminate\Http\Request;
use DateTime;
use DB;

class CuentaBancoController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function list()
    {
        $lista = DB::select('call PFC_L_CUENTA_BANCO()', []);
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
        $date = new DateTime($data['fecUsuarioCrea']);
        $result = $date->format('Y-m-d');

        $resp = DB::select('call PFC_I_CUENTA_BANCO(?,?,?,?,?,?)', [$data['nroCuenta'], $data['cci'], $data['nombre'], $data['saldo'], $data['idUsuarioCrea'], $result]);
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
        $objeto = DB::select('call PFC_S_CUENTA_BANCO(?)', [$data['id']]);
        return response()->json($objeto);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Model\CuentaBanco  $cuentaBanco
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateMod = new DateTime($data['fecUsuarioMod']);
        $fechaMod = $dateMod->format('Y-m-d');

        $resp = DB::select('call PFC_U_CUENTA_BANCO(?,?,?,?,?,?,?)', [$data['id'], $data['nroCuenta'], $data['cci'], $data['nombre'], $data['saldo'], $data['idUsuarioMod'], $fechaMod]);
        return response()->json($resp);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Model\CuentaBanco  $cuentaBanco
     * @return \Illuminate\Http\Response
     */
    public function destroy(CuentaBanco $cuentaBanco)
    {
        //
    }
}
