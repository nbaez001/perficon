<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateMaestraTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('maestra', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedInteger('id_maestra_padre')->nullable();
            $table->unsignedInteger('orden');
            $table->string('nombre',100);
            $table->string('codigo',10);
            $table->string('valor',50)->nullable();
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
        Schema::dropIfExists('maestra');
    }
}
