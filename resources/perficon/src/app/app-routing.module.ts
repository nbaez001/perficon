import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { SesionComponent } from './modules/sesion/sesion.component';
import { IntranetComponent } from './modules/intranet/intranet.component';

const rootRoutes: Routes = [
  {
    path: '',
    redirectTo: 'sesion',
    pathMatch: 'full'
  }, {
    path: '',
    component: SesionComponent,
    children: [
      {
        path: 'sesion',
        loadChildren: './modules/sesion/sesion.module#SesionModule',
        data: { title: 'Session' }
      }
    ]
  }, {
    path: '',
    component: IntranetComponent,
    children: [
      {
        path: 'intranet',
        loadChildren: './modules/intranet/intranet.module#IntranetModule',
        data: { title: 'Intranet' }
      }
    ]
  }, {
    path: '**',
    redirectTo: 'sesion/404'
  }
];

@NgModule({
  imports: [RouterModule.forRoot(rootRoutes, { useHash: true })],
  exports: [RouterModule]
})
export class AppRoutingModule { }
