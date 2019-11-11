import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { DatePipe } from '@angular/common';
import { ApiResponse } from 'src/app/model/api-response.model';
import { UsuarioService } from 'src/app/services/usuario.service';
import { ValidationService } from 'src/app/services/validation.service';

@Component({
  selector: 'app-reg-maestra-child',
  templateUrl: './reg-maestra-child.component.html',
  styleUrls: ['./reg-maestra-child.component.scss']
})
export class RegMaestraChildComponent implements OnInit {
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

  columnsGrilla = [
    {
      columnDef: 'id',
      header: 'N°',
      cell: (maestra: Maestra) => `${maestra.id}`
    }, {
      columnDef: 'orden',
      header: 'Orden',
      cell: (maestra: Maestra) => `${maestra.orden}`
    }, {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (maestra: Maestra) => `${maestra.nombre}`
    }, {
      columnDef: 'codigo',
      header: 'Codigo',
      cell: (maestra: Maestra) => `${maestra.codigo}`
    }, {
      columnDef: 'valor',
      header: 'Valor',
      cell: (maestra: Maestra) => (maestra.valor != null) ? `${maestra.valor}` : ''
    }, {
      columnDef: 'idUsuarioCrea',
      header: 'Usuario creador',
      cell: (maestra: Maestra) => `${maestra.idUsuarioCrea}`
    }, {
      columnDef: 'fecUsuarioCrea',
      header: 'Fecha creacion',
      cell: (maestra: Maestra) => this.datePipe.transform(maestra.fecUsuarioCrea, 'dd/MM/yyyy')
    }, {
      columnDef: 'idUsuarioMod',
      header: 'Usuario modificacion',
      cell: (maestra: Maestra) => (maestra.idUsuarioMod != null) ? `${maestra.idUsuarioMod}` : ''
    }, {
      columnDef: 'fecUsuarioMod',
      header: 'Fecha modificacion',
      cell: (maestra: Maestra) => this.datePipe.transform(maestra.fecUsuarioMod, 'dd/MM/yyyy')
    }];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegMaestraChildComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog,
    private datePipe: DatePipe) { }

  ngOnInit() {
    this.maestraGrp = this.fb.group({
      nombre: ['', [Validators.required]],
      codigo: ['', [Validators.required]],
      valor: ['', []]
    });

    this.maestraGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.maestraGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
  }

  validateForm(): void {
    this.validationService.getValidationErrors(this.maestraGrp, this.messages, this.formErrors, true);
  }

  regMaestra(): void {
    console.log(this.maestraGrp);
    if (this.maestraGrp.valid) {
      console.log('VALIDO');
      console.log(this.maestraGrp.value);

      let mae = new Maestra();
      mae.id = 0;
      mae.idMaestraPadre = 0;
      mae.orden = 0;
      mae.nombre = this.maestraGrp.get('nombre').value;
      mae.codigo = this.maestraGrp.get('codigo').value;
      mae.valor = this.maestraGrp.get('valor').value;
      mae.idUsuarioCrea = this.user.getIdUsuario;
      mae.fecUsuarioCrea = new Date();

      console.log(mae);
      this.spinnerService.show();
      this.maestraService.regMaestra(mae).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al registrar');
            this.dialogRef.close(mae);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al registrar maestra');
          }
        },
        error => {
          console.error('Error al registrar maestra');
        }
      );
    } else {
      this.validateForm();
    }
  }

}

export interface DataDialog {
  title: string;
  maestra: Maestra;
}