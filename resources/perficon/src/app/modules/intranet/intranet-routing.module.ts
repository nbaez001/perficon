import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { HomeComponent } from './components/home/home.component';
import { BandejaEgresosComponent } from './components/bandeja-egresos/bandeja-egresos.component';

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
      }
    ]
  }
];

@NgModule({
  imports: [RouterModule.forChild(intranetRoutes)],
  exports: [RouterModule]
})
export class IntranetRoutingModule { }
