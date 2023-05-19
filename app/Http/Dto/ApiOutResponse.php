<?php

namespace App\Http\Dto;

class ApiOutResponse
{
    public $rcodigo;
    public $rmensaje;
    public $robjeto;

    public function __construct($rcodigo, $rmensaje, $robjeto)
    {
        $this->rcodigo = $rcodigo;
        $this->rmensaje = $rmensaje;
        $this->robjeto = $robjeto;
    }

    public function getRcodigo()
    {
        return $this->rcodigo;
    }

    public function setRcodigo($rcodigo)
    {
        $this->rcodigo = $rcodigo;
    }

    public function getRmensaje()
    {
        return $this->rmensaje;
    }

    public function setRmensaje($rmensaje)
    {
        $this->rmensaje = $rmensaje;
    }

    public function getRobjeto()
    {
        return $this->robjeto;
    }

    public function setRobjeto($robjeto)
    {
        $this->robjeto = $robjeto;
    }
}
