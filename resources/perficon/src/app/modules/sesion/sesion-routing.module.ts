import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Routes, RouterModule } from '@angular/router';
import { RegistrarComponent } from './components/registrar/registrar.component';
import { LoginComponent } from './components/login/login.component';
import { NotFoundComponent } from './components/not-found/not-found.component';
import { ErrorComponent } from './components/error/error.component';

const sesionRoutes: Routes = [
  {
    path: '',
    children: [{
      path: 'registrar',
      component: RegistrarComponent,
      data: { title: 'Registrar' }
    }, {
      path: 'login',
      component: LoginComponent,
      data: { title: 'Login' }
    }, {
      path: '404',
      component: NotFoundComponent,
      data: { title: 'No encontrado' }
    }, {
      path: 'error',
      component: ErrorComponent,
      data: { title: 'Error' }
    }]
  }
];

@NgModule({
  imports: [RouterModule.forChild(sesionRoutes)],
  exports: [RouterModule]
})
export class SesionRoutingModule { }
