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
     * @return \Illuminate\Http\Response
     */
    public function list()
    {
        $lista = DB::select('call PFC_S_MAESTRA(?)', [0]);
        return response()->json($lista);
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
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
     * @param  \App\Model\Maestra  $maestra
     * @return \Illuminate\Http\Response
     */
    public function show(Maestra $maestra)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  \App\Model\Maestra  $maestra
     * @return \Illuminate\Http\Response
     */
    public function edit(Maestra $maestra)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Model\Maestra  $maestra
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Maestra $maestra)
    {
        //
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
