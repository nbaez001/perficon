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


