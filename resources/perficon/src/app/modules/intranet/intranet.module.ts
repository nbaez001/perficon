import { NgModule } from '@angular/core';
import { CommonModule, DatePipe, DecimalPipe } from '@angular/common';

import { IntranetRoutingModule } from './intranet-routing.module';
import { HomeComponent } from './components/home/home.component';
import { MaterialModule } from '../material.module';
import { NavbarComponent } from './components/shared/navbar/navbar.component';
import { BandejaEgresosComponent } from './components/bandeja-egresos/bandeja-egresos.component';
import { Ng4LoadingSpinnerModule } from 'ng4-loading-spinner';
import { ConfiguracionMaestraComponent } from './components/configuracion-maestra/configuracion-maestra.component';
import { RegMaestraComponent } from './components/configuracion-maestra/reg-maestra/reg-maestra.component';
import { RegMaestraChildComponent } from './components/configuracion-maestra/reg-maestra-child/reg-maestra-child.component';
import { RegEgresoComponent } from './components/bandeja-egresos/reg-egreso/reg-egreso.component';
import { MAT_DATE_LOCALE } from '@angular/material';
import { CuentaBancoComponent } from './components/cuenta-banco/cuenta-banco.component';
import { RegCuentaBancoComponent } from './components/cuenta-banco/reg-cuenta-banco/reg-cuenta-banco.component';
import { MovimientoBancoComponent } from './components/movimiento-banco/movimiento-banco.component';
import { RegMovBancoComponent } from './components/movimiento-banco/reg-mov-banco/reg-mov-banco.component';
import { ConfirmComponent } from './components/shared/confirm/confirm.component';
import { BandejaIngresosComponent } from './components/bandeja-ingresos/bandeja-ingresos.component';
import { RegIngresoComponent } from './components/bandeja-ingresos/reg-ingreso/reg-ingreso.component';
import { BuscEgresoComponent } from './components/bandeja-ingresos/busc-egreso/busc-egreso.component';

@NgModule({
  entryComponents: [
    RegMaestraComponent,
    RegMaestraChildComponent,
    RegEgresoComponent,
    RegCuentaBancoComponent,
    RegMovBancoComponent,
    ConfirmComponent,
    RegIngresoComponent,
    BuscEgresoComponent,
  ],
  declarations: [
    RegMaestraComponent,
    RegMaestraChildComponent,
    RegEgresoComponent,
    RegCuentaBancoComponent,
    RegMovBancoComponent,
    ConfirmComponent,
    RegIngresoComponent,
    BuscEgresoComponent,

    HomeComponent,
    NavbarComponent,
    BandejaEgresosComponent,
    ConfiguracionMaestraComponent,
    CuentaBancoComponent,
    MovimientoBancoComponent,
    BandejaIngresosComponent,
  ],
  imports: [
    CommonModule,
    IntranetRoutingModule,
    MaterialModule,
    Ng4LoadingSpinnerModule.forRoot()
  ],
  providers: [
    DatePipe,
    DecimalPipe,
    { provide: MAT_DATE_LOCALE, useValue: 'en-GB' }//DATEPICKER MUESTRA LA FECHA EN FORMATO DD/MM/YYYY
  ]
})
export class IntranetModule { }
