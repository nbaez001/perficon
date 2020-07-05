<?php

namespace App\Http\Service;

use App\Http\Dao\WalletDao;
use App\Http\Dto\Request\BuscarWalletRequest;

class WalletService
{
    private $walletDao;

    function __construct()
    {
        $this->walletDao = new WalletDao();
    }

    public function listarWallet(BuscarWalletRequest $req)
    {
        return $this->walletDao->listarWallet($req);
    }
}
