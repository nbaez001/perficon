<?php

namespace App\Http\Controllers\Configuration;

use App\Http\Controllers\Controller;
use App\Http\Dto\Request\BuscarCuentaBancoRequest;
use App\Http\Service\CuentaBancoService;
use App\Model\CuentaBanco;
use Illuminate\Http\Request;
use DateTime;
use DB;

class CuentaBancoController extends Controller
{
    private $cuentaBancoService;

    function __construct()
    {
        $this->cuentaBancoService = new CuentaBancoService();
    }

    public function list(Request $request)
    {
        $req = new BuscarCuentaBancoRequest($request);
        return response()->json($this->cuentaBancoService->listarCuentaBanco($req));
    }

    public function store(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $date = new DateTime($data['fecUsuarioCrea']);
        $result = $date->format('Y-m-d');

        $resp = DB::select('call PFC_I_CUENTA_BANCO(?,?,?,?,?,?)', [$data['nroCuenta'], $data['cci'], $data['nombre'], $data['saldo'], $data['idUsuarioCrea'], $result]);
        return response()->json($resp);
    }

    public function show(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        $objeto = DB::select('call PFC_S_CUENTA_BANCO(?)', [$data['id']]);
        return response()->json($objeto);
    }

    public function update(Request $request)
    {
        $data = json_decode($request->getContent(), true);

        $dateMod = new DateTime($data['fecUsuarioMod']);
        $fechaMod = $dateMod->format('Y-m-d');

        $resp = DB::select('call PFC_U_CUENTA_BANCO(?,?,?,?,?,?,?)', [$data['id'], $data['nroCuenta'], $data['cci'], $data['nombre'], $data['saldo'], $data['idUsuarioMod'], $fechaMod]);
        return response()->json($resp);
    }
}
