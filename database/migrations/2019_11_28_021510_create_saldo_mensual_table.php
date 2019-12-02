<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateSaldoMensualTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('saldo_mensual', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('dia');
            $table->unsignedInteger('mes');
            $table->unsignedInteger('anio');
            $table->decimal('monto', 8, 2);
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
        Schema::dropIfExists('saldo_mensual');
    }
}
