import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HomeComponent } from './components/home/home.component';
import { BandejaEgresosComponent } from './components/bandeja-egresos/bandeja-egresos.component';
import { ConfiguracionMaestraComponent } from './components/configuracion-maestra/configuracion-maestra.component';
import { CuentaBancoComponent } from './components/cuenta-banco/cuenta-banco.component';
import { MovimientoBancoComponent } from './components/movimiento-banco/movimiento-banco.component';
import { BandejaIngresosComponent } from './components/bandeja-ingresos/bandeja-ingresos.component';

const intranetRoutes: Routes = [
  {
    path: '',
    children: [
      {
        path: '',
        redirectTo: 'home',
        pathMatch: 'full'
      }, {
        path: 'home',
        component: HomeComponent,
        data: { title: 'Home' }
      }, {
        path: 'bandeja-egresos',
        component: BandejaEgresosComponent,
        data: { title: 'Bandeja egresos' }
      }, {
        path: 'bandeja-ingresos',
        component: BandejaIngresosComponent,
        data: { title: 'Bandeja ingresos' }
      }, {
        path: 'bandeja-movimientos',
        component: MovimientoBancoComponent,
        data: { title: 'Bandeja movimientos' }
      }, {
        path: 'configuracion-maestras',
        component: ConfiguracionMaestraComponent,
        data: { title: 'Configuracion maestras' }
      }, {
        path: 'cuenta-banco',
        component: CuentaBancoComponent,
        data: { title: 'Cuentas bancarias' }
      }
    ]
  }
];

@NgModule({
  imports: [RouterModule.forChild(intranetRoutes)],
  exports: [RouterModule]
})
export class IntranetRoutingModule { }
