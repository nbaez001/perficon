import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog, MAT_DIALOG_DATA } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';

@Component({
  selector: 'app-reg-maestra',
  templateUrl: './reg-maestra.component.html',
  styleUrls: ['./reg-maestra.component.scss']
})
export class RegMaestraComponent implements OnInit {
  listaMaestra: Maestra[];
  displayedColumns: string[];
  dataSource: MatTableDataSource<Maestra>;

  maestraGrp: FormGroup;
  messages = {
    'nombre': {
      'required': 'Field is required'
    },
    'codigo': {
      'required': 'Field is required'
    },
    'valor': {
      'required': 'Field is required'
    }
  };

  formErrors = {
    'nombre': '',
    'codigo': '',
    'valor': ''
  };

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.spinnerService.show();

    this.maestraGrp = this.fb.group({
      nombre: ['', [Validators.required]],
      codigo: ['', [Validators.required]],
      valor: ['', []]
    });

    this.maestraGrp.valueChanges.subscribe((val: any) => {
      console.log(JSON.stringify(val));
      this.logValidationErrors(this.maestraGrp, this.messages, this.formErrors);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    // this.banMonitoreoFrmGrp.get('estadoMonitoreoFrmCtrl').setValue(ESTADO_MONITOREO.pendienteInformacion);
    this.spinnerService.hide();
  }

  validateForm(): void {
    this.logValidationErrors(this.maestraGrp, this.messages, this.formErrors);
  }

  logValidationErrors(group: FormGroup, messages: any, formErrors: any): void {
    Object.keys(group.controls).forEach((key: string) => {
      let abstractControl = group.get(key);
      if (abstractControl instanceof FormGroup) {
        this.logValidationErrors(abstractControl, messages[key], formErrors[key]);
      } else {
        formErrors[key] = '';
        if (abstractControl && abstractControl.invalid && (abstractControl.touched || abstractControl.dirty)) {
          let msg = messages[key];
          for (let errorKey in abstractControl.errors) {
            if (errorKey) {
              formErrors[key] += msg[errorKey] + ' ';
            }
          }
        }
      }
    });
  }

  logKeyValuePairs(group: FormGroup): void {
    Object.keys(group.controls).forEach((key: string) => {
      let abstractControl = group.get(key);
      if (abstractControl instanceof FormGroup) {
        this.logKeyValuePairs(abstractControl);
      } else {
        //abstractControl.disable();
        abstractControl.markAsTouched();
        console.log('key =' + key + ' value =' + abstractControl.value);
      }
    });
  }

  regMaestra(): void {
    console.log(this.maestraGrp);
    if (this.maestraGrp.valid) {
      console.log('VALIDO');
      console.log(this.maestraGrp.value);
    } else {
      this.logKeyValuePairs(this.maestraGrp);
      this.validateForm();
    }
  }

  buscar() {
    console.log('Buscar');
  }

}

export interface DataDialog {
  title: string;
  maestra: Maestra;
}
