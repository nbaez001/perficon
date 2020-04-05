<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Storage;

class SendMail extends Mailable
{
    use Queueable, SerializesModels;

    public $data;
    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct($data)
    {
        $this->data = $data;
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        $location = storage_path($this->data['url']);
        return $this->attach($location)->from('contacto@perficon.elnazarenovraem.edu.pe', 'Contacto perficon')->to($this->data['destinatario'])->subject($this->data['asunto'])->view('dynamic_email_template')->with('data', $this->data);
    }
}
