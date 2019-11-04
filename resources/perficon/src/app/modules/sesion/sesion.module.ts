import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { SesionRoutingModule } from './sesion-routing.module';
import { LoginComponent } from './components/login/login.component';
import { MaterialModule } from '../material.module';

@NgModule({
  declarations: [
    LoginComponent
  ],
  imports: [
    CommonModule,
    SesionRoutingModule,
    MaterialModule
  ]
})
export class SesionModule { }
