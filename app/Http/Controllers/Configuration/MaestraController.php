<?php

namespace App\Http\Controllers\Configuration;

use App\Http\Controllers\Controller;
use App\Model\Maestra;
use Illuminate\Http\Request;
use DB;

class MaestraController extends Controller
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
        $lista = DB::select('call PFC_L_MAESTRA(?)', [$data['idMaestraPadre']]);
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
        $resp = DB::select('call PFC_I_MAESTRA(?,?,?,?,?,?,?)', [$data['idMaestraPadre'], $data['orden'], $data['nombre'], $data['codigo'], $data['valor'], $data['idUsuarioCrea'], $data['fecUsuarioCrea']]);
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
        $objeto = DB::select('call PFC_S_MAESTRA(?)', [$data['id']]);
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
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_U_MAESTRA(?,?,?,?,?,?,?,?,?,?)', [$data['id'], $data['idMaestraPadre'], $data['orden'], $data['nombre'], $data['codigo'], $data['valor'], $data['idUsuarioCrea'], $data['fecUsuarioCrea'], $data['idUsuarioMod'], $data['fecUsuarioMod']]);
        return response()->json($resp);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Model\Maestra  $maestra
     * @return \Illuminate\Http\Response
     */
    public function destroy(Maestra $maestra)
    {
        //
    }
}
