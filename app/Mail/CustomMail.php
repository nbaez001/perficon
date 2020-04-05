<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class CustomMail extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * Create a new message instance.
     *
     * @return void
     */
    public function __construct()
    {
        //
    }

    /**
     * Build the message.
     *
     * @return $this
     */
    public function build()
    {
        $location = storage_path("app/backups/2020-04-04_11-26.sql");
        return $this->view('custom_mail')->from('contacto@perficon.elnazarenovraem.edu.pe','Contacto perficon')->to('nbaez001@gmail.com')->subject('Email prueba')->attach($location);
    }
}
