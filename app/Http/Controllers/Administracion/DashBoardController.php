<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use DateTime;
use DB;
use Storage;

class DashBoardController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function pieChart(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_S_PIE_CHART(?,?)', [$data['anio'], $data['idTabla']]);
        return $resp;
    }

    /**
     * Show the form for creating a new resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function lineChart(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_S_LINE_CHART(?,?)', [$data['anio'], $data['mes']]);
        return $resp;
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function barChart(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_S_BAR_CHART(?,?,?,?,?)', [$data['anio'], $data['mes'], $data['dia'], $data['cantDias'], $data['cantDiasPrev']]);
        return response()->json($resp);
    }

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function sumaCategoria(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $resp = DB::select('call PFC_S_SUMA_CATEGORIA(?,?,?)', [$data['anio'], $data['mes'], $data['idTabla']]);
        return $resp;
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        //
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

    /**
     * Display a listing of the resource.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function getFile(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        if (Storage::disk('local')->exists($data['url'])) {
            return Storage::disk('local')->get($data['url']);
        }

        throw new FileNotFoundException(sprintf('File not found: %s', $filename), 404);
    }
}
