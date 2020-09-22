<?php

namespace App\Http\Dto;

class PersonaResponse
{
    public $ApellidoCasada;
    public $ApellidoMaterno;
    public $ApellidoPaterno;
    public $DireccionDomicilio;
    public $DistDomicilio;
    public $DptoDomicilio;
    public $FechaNacimiento;
    public $Nombres;
    public $NumeroDocumento;
    public $ProvDomicilio;
    public $Sexo;
    public $UbigeoDistDomicilio;
    public $UbigeoDptoDomicilio;
    public $UbigeoProvDomicilio;

    public function __construct()
    {
    }


    /**
     * Get the value of ApellidoCasada
     */
    public function getApellidoCasada()
    {
        return $this->ApellidoCasada;
    }

    /**
     * Set the value of ApellidoCasada
     *
     * @return  self
     */
    public function setApellidoCasada($ApellidoCasada)
    {
        $this->ApellidoCasada = $ApellidoCasada;

        return $this;
    }

    /**
     * Get the value of ApellidoMaterno
     */
    public function getApellidoMaterno()
    {
        return $this->ApellidoMaterno;
    }

    /**
     * Set the value of ApellidoMaterno
     *
     * @return  self
     */
    public function setApellidoMaterno($ApellidoMaterno)
    {
        $this->ApellidoMaterno = $ApellidoMaterno;

        return $this;
    }

    /**
     * Get the value of ApellidoPaterno
     */
    public function getApellidoPaterno()
    {
        return $this->ApellidoPaterno;
    }

    /**
     * Set the value of ApellidoPaterno
     *
     * @return  self
     */
    public function setApellidoPaterno($ApellidoPaterno)
    {
        $this->ApellidoPaterno = $ApellidoPaterno;

        return $this;
    }

    /**
     * Get the value of DireccionDomicilio
     */
    public function getDireccionDomicilio()
    {
        return $this->DireccionDomicilio;
    }

    /**
     * Set the value of DireccionDomicilio
     *
     * @return  self
     */
    public function setDireccionDomicilio($DireccionDomicilio)
    {
        $this->DireccionDomicilio = $DireccionDomicilio;

        return $this;
    }

    /**
     * Get the value of DistDomicilio
     */
    public function getDistDomicilio()
    {
        return $this->DistDomicilio;
    }

    /**
     * Set the value of DistDomicilio
     *
     * @return  self
     */
    public function setDistDomicilio($DistDomicilio)
    {
        $this->DistDomicilio = $DistDomicilio;

        return $this;
    }

    /**
     * Get the value of DptoDomicilio
     */
    public function getDptoDomicilio()
    {
        return $this->DptoDomicilio;
    }

    /**
     * Set the value of DptoDomicilio
     *
     * @return  self
     */
    public function setDptoDomicilio($DptoDomicilio)
    {
        $this->DptoDomicilio = $DptoDomicilio;

        return $this;
    }

    /**
     * Get the value of FechaNacimiento
     */
    public function getFechaNacimiento()
    {
        return $this->FechaNacimiento;
    }

    /**
     * Set the value of FechaNacimiento
     *
     * @return  self
     */
    public function setFechaNacimiento($FechaNacimiento)
    {
        $this->FechaNacimiento = $FechaNacimiento;

        return $this;
    }

    /**
     * Get the value of Nombres
     */
    public function getNombres()
    {
        return $this->Nombres;
    }

    /**
     * Set the value of Nombres
     *
     * @return  self
     */
    public function setNombres($Nombres)
    {
        $this->Nombres = $Nombres;

        return $this;
    }

    /**
     * Get the value of NumeroDocumento
     */
    public function getNumeroDocumento()
    {
        return $this->NumeroDocumento;
    }

    /**
     * Set the value of NumeroDocumento
     *
     * @return  self
     */
    public function setNumeroDocumento($NumeroDocumento)
    {
        $this->NumeroDocumento = $NumeroDocumento;

        return $this;
    }

    /**
     * Get the value of ProvDomicilio
     */
    public function getProvDomicilio()
    {
        return $this->ProvDomicilio;
    }

    /**
     * Set the value of ProvDomicilio
     *
     * @return  self
     */
    public function setProvDomicilio($ProvDomicilio)
    {
        $this->ProvDomicilio = $ProvDomicilio;

        return $this;
    }

    /**
     * Get the value of Sexo
     */
    public function getSexo()
    {
        return $this->Sexo;
    }

    /**
     * Set the value of Sexo
     *
     * @return  self
     */
    public function setSexo($Sexo)
    {
        $this->Sexo = $Sexo;

        return $this;
    }

    /**
     * Get the value of UbigeoDistDomicilio
     */
    public function getUbigeoDistDomicilio()
    {
        return $this->UbigeoDistDomicilio;
    }

    /**
     * Set the value of UbigeoDistDomicilio
     *
     * @return  self
     */
    public function setUbigeoDistDomicilio($UbigeoDistDomicilio)
    {
        $this->UbigeoDistDomicilio = $UbigeoDistDomicilio;

        return $this;
    }

    /**
     * Get the value of UbigeoDptoDomicilio
     */
    public function getUbigeoDptoDomicilio()
    {
        return $this->UbigeoDptoDomicilio;
    }

    /**
     * Set the value of UbigeoDptoDomicilio
     *
     * @return  self
     */
    public function setUbigeoDptoDomicilio($UbigeoDptoDomicilio)
    {
        $this->UbigeoDptoDomicilio = $UbigeoDptoDomicilio;

        return $this;
    }

    /**
     * Get the value of UbigeoProvDomicilio
     */
    public function getUbigeoProvDomicilio()
    {
        return $this->UbigeoProvDomicilio;
    }

    /**
     * Set the value of UbigeoProvDomicilio
     *
     * @return  self
     */
    public function setUbigeoProvDomicilio($UbigeoProvDomicilio)
    {
        $this->UbigeoProvDomicilio = $UbigeoProvDomicilio;

        return $this;
    }
}
