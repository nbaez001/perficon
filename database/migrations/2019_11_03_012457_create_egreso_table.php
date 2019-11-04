<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateEgresoTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('egreso', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('id_tipo_egreso');
            $table->unsignedInteger('id_unidad_medida');
            $table->string('motivo', 100);
            $table->unsignedInteger('cantidad');
            $table->decimal('precio', 8, 2);
            $table->decimal('subtotal', 8, 2);
            $table->string('observacion', 500)->nullable();
            $table->string('ubicacion', 100)->nullable();
            $table->string('dia', 10);
            $table->date('fecha');
            $table->string('id_usuario_crea', 50);
            $table->date('fec_usuario_crea');
            $table->string('id_usuario_mod', 50)->nullable();
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
        Schema::dropIfExists('egreso');
    }
}
