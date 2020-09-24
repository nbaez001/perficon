<?php

namespace App\Http\Controllers\Soap;

use App\Http\Dto\ApiOutResponse;
use Illuminate\Http\Request;

class PersonaController extends BaseSoapController
{
    private $service;

    public function buscarPersona(Request $request)
    {
        $ipAdress = $request->ip();
        $position = strripos($ipAdress, ".", 0);
        $ipAdress = substr($ipAdress, 0, $position + 1) . "*";

        $flgPermitido = false;
        $data = json_decode($request->getContent(), true);
        $ipPermitidas = ["127.0.0.*", "148.102.113.*"];

        foreach ($ipPermitidas as $i => $value) {
            if ($value == $ipAdress) {
                $flgPermitido = true;
            }
        }

        if ($flgPermitido) {
            try {
                self::setWsdl('http://sdv.midis.gob.pe/Sis_WS/App/ReniecPersona_Servicio.svc?wsdl');
                $this->service = InstanceSoapClient::init();
                // $peticion = {};
                $response = $this->service->ConsultarPorNumeroDeDocumento(['peticion' => ['Clave' => '@Pais_LInEU0WWhE', 'NumeroDeDocumento' => $data['dni'], 'Usuario' => 'APP09']]);
                // dd($cities);
                $objeto = $response->ConsultarPorNumeroDeDocumentoResult;
                if ($objeto->Codigo == '0000') {
                    $persona = $this->parsePersonaDato($objeto->PersonaDato);
                    return response()->json(new ApiOutResponse(0, $objeto->Mensaje, $persona));
                } else {
                    return response()->json(new ApiOutResponse(1, $objeto->Codigo + '-' + $objeto->Mensaje, null));
                }
            } catch (\Exception $e) {
                return response()->json(new ApiOutResponse(500, $e->getMessage(), null));
            }
        } else {
            return response()->json(new ApiOutResponse(-1, 'NO PERMITIDO', null));
        }
    }

    public function getIp()
    {
        foreach (array('HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_X_FORWARDED', 'HTTP_X_CLUSTER_CLIENT_IP', 'HTTP_FORWARDED_FOR', 'HTTP_FORWARDED', 'REMOTE_ADDR') as $key) {
            if (array_key_exists($key, $_SERVER) === true) {
                foreach (explode(',', $_SERVER[$key]) as $ip) {
                    $ip = trim($ip); // just to be safe
                    if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) !== false) {
                        return $ip;
                    }
                }
            }
        }
    }
}
