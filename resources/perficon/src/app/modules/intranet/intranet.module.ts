import { NgModule } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';

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

@NgModule({
  entryComponents: [
    RegMaestraComponent,
    RegMaestraChildComponent,
    RegEgresoComponent
  ],
  declarations: [
    HomeComponent,
    NavbarComponent,
    BandejaEgresosComponent,
    ConfiguracionMaestraComponent,

    RegMaestraComponent,
    RegMaestraChildComponent,
    RegEgresoComponent
  ],
  imports: [
    CommonModule,
    IntranetRoutingModule,
    MaterialModule,
    Ng4LoadingSpinnerModule.forRoot()
  ],
  providers: [
    DatePipe
  ]
})
export class IntranetModule { }
