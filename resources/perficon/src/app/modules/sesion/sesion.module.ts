import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LoginComponent } from './components/login/login.component';
import { RegistrarComponent } from './components/registrar/registrar.component';
import { NotFoundComponent } from './components/not-found/not-found.component';
import { ErrorComponent } from './components/error/error.component';
import { SesionRoutingModule } from './sesion-routing.module';
import { MaterialModule } from '../material.module';
import { SesionComponent } from './sesion.component';

@NgModule({
  declarations: [
    LoginComponent,
    RegistrarComponent,
    NotFoundComponent,
    ErrorComponent
  ],
  imports: [
    CommonModule,
    SesionRoutingModule
  ]
})
export class SesionModule { }
