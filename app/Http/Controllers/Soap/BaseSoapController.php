<?php

namespace App\Http\Controllers\Soap;

use App\Http\Controllers\Controller;
use App\Http\Dto\PersonaResponse;

class BaseSoapController extends Controller
{
    protected static $options;
    protected static $context;
    protected static $wsdl;

    public function __construct()
    {
    }

    public static function setWsdl($service)
    {
        return self::$wsdl = $service;
    }

    public static function getWsdl()
    {
        return self::$wsdl;
    }

    protected static function generateContext()
    {
        self::$options = [
            'http' => [
                'user_agent' => 'PHPSoapClient'
            ]
        ];
        return self::$context = stream_context_create(self::$options);
    }

    public function parsePersonaDato($xmlObject)
    {
        $pers = new PersonaResponse();
        $pers->setApellidoCasada($xmlObject->ApellidoCasada);
        $pers->setApellidoMaterno($xmlObject->ApellidoMaterno);
        $pers->setApellidoPaterno($xmlObject->ApellidoPaterno);
        $pers->setDireccionDomicilio($xmlObject->DireccionDomicilio);
        $pers->setDistDomicilio($xmlObject->DistDomicilio);
        $pers->setDptoDomicilio($xmlObject->DptoDomicilio);
        $pers->setFechaNacimiento($xmlObject->FechaNacimiento);
        $pers->setNombres($xmlObject->Nombres);
        $pers->setNumeroDocumento($xmlObject->NumeroDocumento);
        $pers->setProvDomicilio($xmlObject->ProvDomicilio);
        $pers->setSexo($xmlObject->Sexo);
        $pers->setUbigeoDistDomicilio($xmlObject->UbigeoDistDomicilio);
        $pers->setUbigeoDptoDomicilio($xmlObject->UbigeoDptoDomicilio);
        $pers->setUbigeoProvDomicilio($xmlObject->UbigeoProvDomicilio);

        return $pers;
    }
}
