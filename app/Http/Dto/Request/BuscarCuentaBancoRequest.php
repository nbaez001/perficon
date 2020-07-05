<?php

namespace App\Http\Dto\Request;

class BuscarCuentaBancoRequest
{
    public $fechaInicio;
    public $fechaFin;

    function __construct($req)
    {
        $this->setFechaInicio($req['fechaInicio']);
        $this->setFechaFin($req['fechaFin']);
    }


    /**
     * Get the value of fechaInicio
     */
    public function getFechaInicio()
    {
        return $this->fechaInicio;
    }

    /**
     * Set the value of fechaInicio
     *
     * @return  self
     */
    public function setFechaInicio($fechaInicio)
    {
        $this->fechaInicio = $fechaInicio;

        return $this;
    }



    /**
     * Get the value of fechaFin
     */
    public function getFechaFin()
    {
        return $this->fechaFin;
    }

    /**
     * Set the value of fechaFin
     *
     * @return  self
     */
    public function setFechaFin($fechaFin)
    {
        $this->fechaFin = $fechaFin;

        return $this;
    }
}
