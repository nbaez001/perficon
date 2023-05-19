<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Service\EmpresaService;

class EmpresaController extends Controller
{
    /**
     * Return the licence of a company
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function obtenerLicencia(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $empresaService = new EmpresaService();
        return response()->json($empresaService->obtenerLicencia($data));
    }
}
