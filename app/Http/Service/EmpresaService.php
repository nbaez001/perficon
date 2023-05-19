<?php

namespace App\Http\Service;

use App\Http\Dao\EmpresaDao;

class EmpresaService
{
    public function obtenerLicencia($req)
    {
        $dashDao = new EmpresaDao();
        return $dashDao->obtenerLicencia($req);
    }
}
