import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { LoginComponent } from './components/login/login.component';

const sesionRoutes: Routes = [
  {
    path: '',
    children: [
      {
        path: '',
        redirectTo: 'login',
        pathMatch: 'full'
      }, {
        path: 'login',
        component: LoginComponent,
        data: { title: 'Login' }
      }
    ]
  }
];

@NgModule({
  imports: [RouterModule.forChild(sesionRoutes)],
  exports: [RouterModule]
})
export class SesionRoutingModule { }
