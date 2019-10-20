import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material';
import { SesionComponent } from './sesion/sesion.component';
import { RouterModule } from '@angular/router';

@NgModule({
  declarations: [
    SesionComponent
  ],
  imports: [
    CommonModule,
    RouterModule,
    MatButtonModule
  ],
  exports: [
    MatButtonModule,
    SesionComponent
  ]
})
export class MaterialModule { }
