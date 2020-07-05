<?php

namespace App\Http\Dto\Response;

class WalletResponse
{
    public $id;
    public $nombre;
    public $monto;
    public $idUsuarioCrea;
    public $fecUsuarioCrea;
    public $idUsuarioMod;
    public $fecUsuarioMod;

    /**
     * Get the value of id
     */
    public function getId()
    {
        return $this->id;
    }

    /**
     * Set the value of id
     *
     * @return  self
     */
    public function setId($id)
    {
        $this->id = $id;

        return $this;
    }

    /**
     * Get the value of nombre
     */
    public function getNombre()
    {
        return $this->nombre;
    }

    /**
     * Set the value of nombre
     *
     * @return  self
     */
    public function setNombre($nombre)
    {
        $this->nombre = $nombre;

        return $this;
    }

    /**
     * Get the value of idUsuarioCrea
     */
    public function getIdUsuarioCrea()
    {
        return $this->idUsuarioCrea;
    }

    /**
     * Set the value of idUsuarioCrea
     *
     * @return  self
     */
    public function setIdUsuarioCrea($idUsuarioCrea)
    {
        $this->idUsuarioCrea = $idUsuarioCrea;

        return $this;
    }

    /**
     * Get the value of fecUsuarioCrea
     */
    public function getFecUsuarioCrea()
    {
        return $this->fecUsuarioCrea;
    }

    /**
     * Set the value of fecUsuarioCrea
     *
     * @return  self
     */
    public function setFecUsuarioCrea($fecUsuarioCrea)
    {
        $this->fecUsuarioCrea = $fecUsuarioCrea;

        return $this;
    }

    /**
     * Get the value of idUsuarioMod
     */
    public function getIdUsuarioMod()
    {
        return $this->idUsuarioMod;
    }

    /**
     * Set the value of idUsuarioMod
     *
     * @return  self
     */
    public function setIdUsuarioMod($idUsuarioMod)
    {
        $this->idUsuarioMod = $idUsuarioMod;

        return $this;
    }

    /**
     * Get the value of fecUsuarioMod
     */
    public function getFecUsuarioMod()
    {
        return $this->fecUsuarioMod;
    }

    /**
     * Set the value of fecUsuarioMod
     *
     * @return  self
     */
    public function setFecUsuarioMod($fecUsuarioMod)
    {
        $this->fecUsuarioMod = $fecUsuarioMod;

        return $this;
    }

    /**
     * Get the value of monto
     */
    public function getMonto()
    {
        return $this->monto;
    }

    /**
     * Set the value of monto
     *
     * @return  self
     */
    public function setMonto($monto)
    {
        $this->monto = $monto;

        return $this;
    }
}
