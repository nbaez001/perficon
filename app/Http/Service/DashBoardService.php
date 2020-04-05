<?php

namespace App\Http\Service;

use App\Http\Dao\DashBoardDao;

class DashBoardService
{
    public function lineChart($req)
    {
        $dashDao = new DashBoardDao();
        return $dashDao->lineChart($req);
    }
}
