import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { IntranetRoutingModule } from './intranet-routing.module';
import { HomeComponent } from './components/home/home.component';
import { MaterialModule } from '../material.module';
import { NavbarComponent } from './components/shared/navbar/navbar.component';
import { BandejaEgresosComponent } from './components/bandeja-egresos/bandeja-egresos.component';
import { Ng4LoadingSpinnerModule } from 'ng4-loading-spinner';

@NgModule({
  declarations: [
    HomeComponent,
    NavbarComponent,
    BandejaEgresosComponent
  ],
  imports: [
    CommonModule,
    IntranetRoutingModule,
    MaterialModule,
    Ng4LoadingSpinnerModule.forRoot()
  ]
})
export class IntranetModule { }
