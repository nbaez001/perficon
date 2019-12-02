<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCuentaBancoTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('cuenta_banco', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('nro_cuenta', 20);
            $table->string('cci', 20);
            $table->string('nombre', 50);
            $table->decimal('saldo', 8, 2);
            $table->unsignedInteger('id_usuario_crea');
            $table->date('fec_usuario_crea');
            $table->unsignedInteger('id_usuario_mod')->nullable();
            $table->date('fec_usuario_mod')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('cuenta_banco');
    }
}
