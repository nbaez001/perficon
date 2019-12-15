<?php

use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Route::middleware('auth:api')->get('/user', function (Request $request) {
//     return $request->user();
// });

// Route::resource('maestra/lista', 'Configuration\MaestraController@list');
// Route::apiResource('', 'Configuration\MaestraController');
Route::post('maestra/lista', 'Configuration\MaestraController@list');
Route::post('maestra/store', 'Configuration\MaestraController@store');
Route::post('maestra/update', 'Configuration\MaestraController@update');
Route::post('maestra/show', 'Configuration\MaestraController@show');

Route::post('egreso/lista', 'Administracion\EgresoController@list');
Route::post('egreso/store', 'Administracion\EgresoController@store');
Route::post('egreso/update', 'Administracion\EgresoController@update');
Route::post('egreso/show', 'Administracion\EgresoController@show');

Route::post('cuenta-banco/lista', 'Configuration\CuentaBancoController@list');
Route::post('cuenta-banco/store', 'Configuration\CuentaBancoController@store');
Route::post('cuenta-banco/update', 'Configuration\CuentaBancoController@update');
Route::post('cuenta-banco/show', 'Configuration\CuentaBancoController@show');

Route::post('movimiento-banco/lista', 'Administracion\MovimientoBancoController@list');
Route::post('movimiento-banco/store', 'Administracion\MovimientoBancoController@store');
Route::post('movimiento-banco/delete', 'Administracion\MovimientoBancoController@destroy');
Route::post('movimiento-banco/show', 'Administracion\MovimientoBancoController@show');

Route::post('saldo-mensual/obtener', 'Administracion\SaldoMensualController@obtener');
Route::post('saldo-mensual/calcular', 'Administracion\SaldoMensualController@calcular');
Route::post('saldo-mensual/obtener-actual', 'Administracion\SaldoMensualController@obtenerActual');

Route::post('dashboard/pie-chart', 'Administracion\DashBoardController@pieChart');
Route::post('dashboard/line-chart', 'Administracion\DashBoardController@lineChart');
Route::post('dashboard/bar-chart', 'Administracion\DashBoardController@barChart');