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
