import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LayoutModule } from '@angular/cdk/layout';
import { MatToolbarModule, MatButtonModule, MatSidenavModule, MatIconModule, MatListModule, MatInputModule, MatCardModule, MatGridListModule, MatMenuModule, MatExpansionModule, MatSelectModule, MatTableModule, MatPaginatorModule, MatDialogModule, MatTooltipModule, MatCheckboxModule, MatDatepickerModule, MatNativeDateModule } from '@angular/material';
import { ResponsiveRowsDirective } from '../core/directives/responsive-rows.directive';
import { ReactiveFormsModule } from '@angular/forms';
import { UppercaseDirective } from '../core/directives/uppercase.directive';

@NgModule({
  declarations: [
    ResponsiveRowsDirective, //DIRECTIVA GRID RESPONSIVE
    UppercaseDirective //DIRECTIVA UPPERCASE
  ],
  imports: [
    ReactiveFormsModule,
    
    CommonModule,
    LayoutModule,
    MatToolbarModule,
    MatButtonModule,
    MatSidenavModule,
    MatIconModule,
    MatListModule,
    MatInputModule,
    MatCardModule,
    MatGridListModule,
    MatMenuModule,
    MatExpansionModule,
    MatSelectModule,
    MatTableModule,
    MatPaginatorModule,
    MatDialogModule,
    MatTooltipModule,
    MatCheckboxModule,
    MatDatepickerModule,
    MatNativeDateModule
  ],
  exports: [
    ReactiveFormsModule,
    
    MatButtonModule,
    LayoutModule,
    MatToolbarModule,
    MatButtonModule,
    MatSidenavModule,
    MatIconModule,
    MatListModule,
    MatInputModule,
    MatCardModule,
    MatGridListModule,
    MatMenuModule,
    MatExpansionModule,
    MatSelectModule,
    MatTableModule,
    MatPaginatorModule,
    MatDialogModule,
    MatTooltipModule,
    MatCheckboxModule,
    MatDatepickerModule,
    MatNativeDateModule,

    ResponsiveRowsDirective, //DIRECTIVA GRID RESPONSIVE
    UppercaseDirective //DIRECTIVA UPPERCASE
  ]
})
export class MaterialModule { }
