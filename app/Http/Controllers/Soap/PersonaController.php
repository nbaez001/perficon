<?php

namespace App\Http\Controllers\Soap;

use Illuminate\Http\Request;

class PersonaController extends BaseSoapController
{
    private $service;

    public function buscarPersona(Request $request)
    {
        $data = json_decode($request->getContent(), true);
        try {
            self::setWsdl('http://sdv.midis.gob.pe/Sis_WS/App/ReniecPersona_Servicio.svc?wsdl');
            $this->service = InstanceSoapClient::init();
            // $peticion = {};
            $response = $this->service->ConsultarPorNumeroDeDocumento(['peticion' => ['Clave' => '@Pais_LInEU0WWhE', 'NumeroDeDocumento' => $data['dni'], 'Usuario' => 'APP09']]);
            // dd($cities);
            $persona = $response->ConsultarPorNumeroDeDocumentoResult;
            $datos = $this->parsePersonaDato($persona->PersonaDato);
            return response()->json($datos);
        } catch (\Exception $e) {
            return $e->getMessage();
        }
    }
}
