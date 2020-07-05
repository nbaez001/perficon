<?php

namespace App\Http\Service;

use App\Http\Dao\CuentaBancoDao;
use App\Http\Dto\Request\BuscarCuentaBancoRequest;

class CuentaBancoService
{
    private $cuentaBancoDao;

    function __construct()
    {
        $this->cuentaBancoDao = new CuentaBancoDao();
    }

    public function listarCuentaBanco(BuscarCuentaBancoRequest $req)
    {
        return $this->cuentaBancoDao->listarCuentaBanco($req);
    }
}
