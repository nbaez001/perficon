<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateMovimientoBancoTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('movimiento_banco', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('id_cuenta_banco');
            $table->string('detalle', 50);
            $table->decimal('saldo', 8, 2);
            $table->date('fecha');
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
        Schema::dropIfExists('movimiento_banco');
    }
}
