import { Component, OnInit, Inject, ViewChild } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { Ingreso } from 'src/app/model/ingreso.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatTableDataSource, MatPaginator, MatSort, MatDialog, MatSnackBar } from '@angular/material';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DatePipe, DecimalPipe } from '@angular/common';
import { ValidationService } from 'src/app/services/validation.service';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { IngresoService } from 'src/app/services/intranet/ingreso.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { Egreso } from 'src/app/model/egreso.model';
import { BuscEgresoComponent } from '../busc-egreso/busc-egreso.component';
import { MENSAJES } from 'src/app/common';
import { ConfirmComponent } from '../../shared/confirm/confirm.component';

@Component({
  selector: 'app-reg-ingreso',
  templateUrl: './reg-ingreso.component.html',
  styleUrls: ['./reg-ingreso.component.scss']
})
export class RegIngresoComponent implements OnInit {
  tiposIngreso: Maestra[] = [];
  ingresoEdit: Ingreso;

  ingresoGrp: FormGroup;
  messages = {
    'tipoIngreso': {
      'required': 'Field is required'
    },
    'nombre': {
      'required': 'Field is required'
    },
    'monto': {
      'required': 'Field is required'
    },
    'fecha': {
      'required': 'Field is required'
    },
    'observacion': {
    }
  };
  formErrors = {
    'tipoIngreso': '',
    'nombre': '',
    'monto': '',
    'fecha': '',
    'observacion': '',
  };

  isLoading: boolean = false;
  inhabilitarBuscar: boolean = false;

  listaEgresos: any[] = [];
  dataSource: MatTableDataSource<any> = null;
  displayedColumns: string[];
  columnsGrilla = [
    {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (egreso: any) => `${(egreso.nombre) ? egreso.nombre : ''}`
    }, {
      columnDef: 'nomTipoEgreso',
      header: 'Tipo egreso',
      cell: (egreso: any) => `${(egreso.nomTipoEgreso) ? egreso.nomTipoEgreso : ''}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (egreso: any) => this.datePipe.transform(egreso.fecha, 'dd/MM/yyyy')
    }, {
      columnDef: 'total',
      header: 'Total',
      cell: (egreso: any) => `${(egreso.totalEgreso) ? this.decimalPipe.transform(egreso.totalEgreso, '1.2-2') : ''}`
    }, {
      columnDef: 'totalRetorno',
      header: 'Retorno',
      cell: (egreso: any) => `${(egreso.totalRetorno) ? this.decimalPipe.transform(egreso.totalRetorno, '1.2-2') : 0.00}`
    }, {
      columnDef: 'porRetornar',
      header: 'Por retornar',
      cell: (egreso: any) => `${(egreso.totalEgresoAux) ? this.decimalPipe.transform(egreso.totalEgresoAux, '1.2-2') : 0.00}`
    }
  ];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegIngresoComponent>,
    public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    private decimalPipe: DecimalPipe,
    private _snackBar: MatSnackBar,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(IngresoService) private ingresoService: IngresoService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.ingresoGrp = this.fb.group({
      tipoIngreso: ['', [Validators.required]],
      nombre: ['', [Validators.required]],
      monto: [0.00, [Validators.required]],
      fecha: ['', [Validators.required]],
      observacion: ['', []],
    });

    this.ingresoGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.ingresoGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.definirTabla();
    this.comboTiposIngreso();
    if (this.data.objeto) {
      this.ingresoEdit = JSON.parse(JSON.stringify(this.data.objeto));
      this.ingresoGrp.get('tipoIngreso').setValue((this.tiposIngreso.filter(el => el.id == this.ingresoEdit.idTipoIngreso))[0]);
      this.ingresoGrp.get('nombre').setValue(this.ingresoEdit.nombre);
      this.ingresoGrp.get('monto').setValue(this.ingresoEdit.monto);
      this.ingresoGrp.get('observacion').setValue(this.ingresoEdit.observacion);
      this.ingresoGrp.get('fecha').setValue(new Date(this.datePipe.transform(this.ingresoEdit.fecha, 'MM/dd/yyyy')));

      this.inhabilitarBuscar = true;
      this.isLoading = true;
      this.cargarEgresosRetorno(this.ingresoEdit.id);
    } else {
      this.inhabilitarBuscar = false;
      this.ingresoGrp.get('fecha').setValue(new Date(this.datePipe.transform(new Date(), 'MM/dd/yyyy')));
      this.ingresoGrp.get('tipoIngreso').setValue(this.tiposIngreso[0]);
    }
  }

  definirTabla(): void {
    this.displayedColumns = [];
    this.columnsGrilla.forEach(c => {
      this.displayedColumns.push(c.columnDef);
    });
    this.displayedColumns.unshift('id');
    this.displayedColumns.push('opt');
  }

  public cargarDatosTabla(): void {
    this.dataSource = null;
    if (this.listaEgresos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaEgresos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  cargarEgresosRetorno(idIngreso: number): void {
    this.ingresoService.listarEgresosRetorno({ id: idIngreso }).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let result = JSON.parse(data[0].result);

          this.listaEgresos = result ? result : [];
          this.adicionarRetornados();
          this.evaluarRetorno();
          this.cargarDatosTabla();
          this.isLoading = false;
        } else {
          console.error('Ocurrio un error al cargar');
          this.isLoading = false;
        }
      },
      error => {
        console.error('Error al consultar datos');
        this.isLoading = false;
      }
    );
  }

  evaluarRetorno() {
    let monto = this.ingresoGrp.get('monto').value;
    if (monto == null) {
      this.ingresoGrp.get('monto').setValue(0.0);
      monto = 0.0;
    }

    this.listaEgresos.forEach(el => {
      if (monto >= el.totalEgreso) {
        el.totalRetorno = el.totalEgreso;
        el.totalEgresoAux = el.totalEgreso - el.totalRetorno;

        monto = monto - el.total;
      } else {
        if (monto > 0) {
          el.totalRetorno = monto;
          el.totalEgresoAux = el.totalEgreso - el.totalRetorno;
          monto = 0.00;
        } else {
          el.totalRetorno = 0.0;
          el.totalEgresoAux = el.totalEgreso - el.totalRetorno;
          monto = 0.00;
        }
      }
    });
  }

  adicionarRetornados(): void {
    this.listaEgresos.forEach(el => {
      el.totalEgreso = el.totalEgreso + el.totalRetorno;
    });
  }

  comboTiposIngreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 30;//10=>TIPOS INGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.tiposIngreso = data;

        if (this.data.objeto) {
          this.ingresoGrp.get('tipoIngreso').setValue((this.tiposIngreso.filter(el => el.id == this.ingresoEdit.idTipoIngreso))[0]);
        } else {
          this.ingresoGrp.get('tipoIngreso').setValue(this.tiposIngreso[1]);
        }
      }, error => {
        console.log(error);
      }
    );
  }

  regIngreso(): void {
    if (this.ingresoGrp.valid) {
      let obj = new Ingreso();
      obj.id = 0;
      obj.idTipoIngreso = this.ingresoGrp.get('tipoIngreso').value.id;
      obj.nomTipoIngreso = this.ingresoGrp.get('tipoIngreso').value.nombre;
      obj.nombre = this.ingresoGrp.get('nombre').value;
      obj.monto = this.ingresoGrp.get('monto').value;
      obj.observacion = this.ingresoGrp.get('observacion').value;
      obj.fecha = this.ingresoGrp.get('fecha').value;
      obj.idEstado = 0;
      obj.idUsuarioCrea = this.user.getIdUsuario;
      obj.fecUsuarioCrea = new Date();

      let json: any[] = [];
      this.listaEgresos.forEach(el => {
        json.push({ id: el.id, monto: el.totalRetorno, totalEgreso: el.totalEgresoAux });
      });
      obj.json = JSON.stringify(json);

      if (json.length <= 0) {//CASO SIN DETALLE MUESTRA DIALOGO DE CONFIRMACION
        const dialogRef = this.dialog.open(ConfirmComponent, {
          width: '500px',
          data: '¿Esta seguro que desea continuar sin asociar ningun egreso?'
        });

        dialogRef.afterClosed().subscribe(result => {
          if (result == 1) {
            this.spinnerService.show();
            this.ingresoService.regIngreso(obj).subscribe(
              (data: ApiResponse[]) => {
                if (typeof data[0] != undefined && data[0].rcodigo == 0) {
                  obj.id = data[0].rid;
                  this.dialogRef.close(obj);
                  this.spinnerService.hide();
                } else {
                  console.error('Ocurrio un error al registrar ingreso');
                }
              }, error => {
                console.error('Error al registrar ingreso');
              }
            );
          }
        });
      } else {
        this.spinnerService.show();
        this.ingresoService.regIngreso(obj).subscribe(
          (data: ApiResponse[]) => {
            if (typeof data[0] != undefined && data[0].rcodigo == 0) {
              obj.id = data[0].rid;
              this.dialogRef.close(obj);
              this.spinnerService.hide();
            } else {
              console.error('Ocurrio un error al registrar ingreso');
            }
          }, error => {
            console.error('Error al registrar ingreso');
          }
        );
      }
    } else {
      this.validationService.getValidationErrors(this.ingresoGrp, this.messages, this.formErrors, true);
    }
  }

  editIngreso(): void {
    if (this.ingresoGrp.valid) {
      let obj: Ingreso = JSON.parse(JSON.stringify(this.data.objeto));
      obj.idTipoIngreso = this.ingresoGrp.get('tipoIngreso').value.id;
      obj.nomTipoIngreso = this.ingresoGrp.get('tipoIngreso').value.nombre;
      obj.nombre = this.ingresoGrp.get('nombre').value;
      obj.monto = this.ingresoGrp.get('monto').value;
      obj.observacion = this.ingresoGrp.get('observacion').value;
      obj.fecha = this.ingresoGrp.get('fecha').value;
      obj.idUsuarioMod = this.user.getIdUsuario;
      obj.fecUsuarioMod = new Date();

      let json: any[] = [];
      this.listaEgresos.forEach(el => {
        json.push({ id: el.id, monto: el.totalRetorno, totalEgreso: el.totalEgresoAux });
      });
      obj.json = JSON.stringify(json);

      if (json.length <= 0) {//CASO SIN DETALLE MUESTRA DIALOGO DE CONFIRMACION
        const dialogRef = this.dialog.open(ConfirmComponent, {
          width: '500px',
          data: '¿Esta seguro que desea continuar sin asociar ningun egreso?'
        });

        dialogRef.afterClosed().subscribe(result => {
          if (result == 1) {
            this.spinnerService.show();
            this.ingresoService.editIngreso(obj).subscribe(
              (data: ApiResponse[]) => {
                if (typeof data[0] != undefined && data[0].rcodigo == 0) {
                  console.log('Exito al modificar');
                  this.dialogRef.close(obj);
                  this.spinnerService.hide();
                } else {
                  console.error('Ocurrio un error al modificar ingreso');
                }
              }, error => {
                console.error('Error al modificar ingreso');
              }
            );
          }
        });
      } else {
        this.spinnerService.show();
        this.ingresoService.editIngreso(obj).subscribe(
          (data: ApiResponse[]) => {
            if (typeof data[0] != undefined && data[0].rcodigo == 0) {
              console.log('Exito al modificar');
              this.dialogRef.close(obj);
              this.spinnerService.hide();
            } else {
              console.error('Ocurrio un error al modificar ingreso');
            }
          }, error => {
            console.error('Error al modificar ingreso');
          }
        );
      }
    } else {
      this.validationService.getValidationErrors(this.ingresoGrp, this.messages, this.formErrors, true);
    }
  }

  buscarEgresos(): void {
    const dialogRef3 = this.dialog.open(BuscEgresoComponent, {
      width: '800px',
      data: { title: MENSAJES.INTRANET.BANDEJAINGRESOS.INGRESO.BUSCAREGRESO.TITLE, objeto: null }
    });

    dialogRef3.afterClosed().subscribe(result => {
      if (result) {
        let cont = '';
        result.forEach(el => {
          if (!(this.listaEgresos.some(e => e.id === el.id))) {
            this.listaEgresos.push(el);
          } else {
            cont += '[' + el.nombre + '] ';
          }
        });

        if (cont.length > 0) {
          this._snackBar.open('La lista ya contiene: ' + cont, null, { duration: 5000, horizontalPosition: 'right', verticalPosition: 'top', panelClass: ['warning-snackbar'] })
        }
        this.evaluarRetorno();
        this.cargarDatosTabla();//PARA CONFORMIDAD MANT
        // this.calcularCotizacion();
      }
    });
  }

  quitarEgreso(obj): void {
    let index = this.listaEgresos.indexOf(obj);

    const dialogRef = this.dialog.open(ConfirmComponent, {
      width: '500px',
      data: '¿Esta seguro que desea eliminar el movimiento?'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result == 1) {
        this.listaEgresos.splice(index, 1);
        this.evaluarRetorno();
        this.cargarDatosTabla();
      }
    });
  }

}
