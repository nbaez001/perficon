<?php

namespace App\Http\Controllers\Cuenta;

use App\Http\Controllers\Controller;
use App\Http\Dto\Request\BuscarWalletRequest;
use App\Http\Service\WalletService;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    private $walletService;

    function __construct()
    {
        $this->walletService = new WalletService();
    }


    public function listarWallet(Request $request)
    {
        $req = new BuscarWalletRequest($request);
        return response()->json($this->walletService->listarWallet($req));
    }
}
