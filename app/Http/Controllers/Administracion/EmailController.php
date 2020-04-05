<?php

namespace App\Http\Controllers\Administracion;

use App\Http\Controllers\Controller;
use App\Mail\CustomMail;
use App\Mail\SendMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class EmailController extends Controller
{
    /**
     * Send a new email.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function sendEmail(Request $request)
    {
        $datos = json_decode($request->getContent(), true);

        $data = array(
            'destinatario' => $datos['destinatario'],
            'asunto' => $datos['asunto'],
            'mensaje' => $datos['mensaje'],
            'url' => $datos['url']
        );
        Mail::send(new SendMail($data));
        return response()->json('{codigo:0}');
    }

    /**
     * Send custom a new email.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function customEmail(Request $request)
    {
        $datos = json_decode($request->getContent(), true);

        $data = array(
            'destinatario' => $datos['destinatario'],
            'asunto' => $datos['asunto'],
            'mensaje' => $datos['mensaje'],
            'url' => $datos['url']
        );
        Mail::send(new CustomMail());
        return response()->json('{codigo:0}');
    }
}
