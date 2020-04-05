<?php

namespace App\Http\Dto;

class ApiOutResponse
{
    public $rCodigo;
    public $rMensaje;
    public $result;

    public function __construct($rCodigo, $rMensaje, $result)
    {
        $this->rCodigo = $rCodigo;
        $this->rMensaje = $rMensaje;
        $this->result = $result;
    }

    public function getRCodigo()
    {
        return $this->rCodigo;
    }

    public function setRCodigo($rCodigo)
    {
        $this->rCodigo = $rCodigo;
    }

    public function getRMensaje()
    {
        return $this->rMensaje;
    }

    public function setRMensaje($rMensaje)
    {
        $this->rMensaje = $rMensaje;
    }

    public function getResult()
    {
        return $this->result;
    }

    public function setResult($result)
    {
        $this->result = $result;
    }
}
