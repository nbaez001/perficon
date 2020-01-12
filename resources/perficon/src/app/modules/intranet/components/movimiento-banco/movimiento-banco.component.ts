import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog } from '@angular/material';
import { MovimientoBanco } from 'src/app/model/movimiento-banco.model';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DatePipe, DecimalPipe } from '@angular/common';
import { MovimientoBancoService } from 'src/app/services/intranet/movimiento-banco.service';
import { CuentaBancoService } from 'src/app/services/intranet/cuenta-banco.service';
import { ValidationService } from 'src/app/services/validation.service';
import { RegMovBancoComponent } from './reg-mov-banco/reg-mov-banco.component';
import { MENSAJES } from 'src/app/common';
import { Maestra } from 'src/app/model/maestra.model';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { ApiResponse } from 'src/app/model/api-response.model';
import { ConfirmComponent } from '../shared/confirm/confirm.component';
import { MovimientoBancoRequest } from 'src/app/model/dto/movimiento-banco.request';

@Component({
  selector: 'app-movimiento-banco',
  templateUrl: './movimiento-banco.component.html',
  styleUrls: ['./movimiento-banco.component.scss']
})
export class MovimientoBancoComponent implements OnInit {
  listaCuentasBanco: CuentaBanco[];

  bandejaGrp: FormGroup;
  messages = {
    'cuentaBanco': {
      'required': 'Field is required'
    },
    'indicio': {
    },
    'inicioFecha': {
    },
    'finFecha': {
    }
  };
  formErrors = {
    'cuentaBanco': '',
    'indicio': '',
    'inicioFecha': '',
    'finFecha': ''
  };

  displayedColumns: string[];
  dataSource: MatTableDataSource<MovimientoBanco>;
  isLoading: boolean = false;

  listaMovimientoBancos: MovimientoBanco[] = [];
  columnsGrilla = [
    {
      columnDef: 'nomCuentaBanco',
      header: 'Cuenta bancaria',
      cell: (mov: MovimientoBanco) => `${mov.nomCuentaBanco}`
    }, {
      columnDef: 'nomTipoMovimiento',
      header: 'Tipo movimiento',
      cell: (mov: MovimientoBanco) => `${mov.nomTipoMovimiento}`
    }, {
      columnDef: 'monto',
      header: 'Monto',
      cell: (mov: MovimientoBanco) => `S/. ${this.decimalPipe.transform(mov.monto, '1.2-2')}`,
      style: 'right-column'
    }, {
      columnDef: 'detalle',
      header: 'Detalle',
      cell: (mov: MovimientoBanco) => `${mov.detalle}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (mov: MovimientoBanco) => this.datePipe.transform(mov.fecha, 'dd/MM/yyyy')
    }
  ];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    private decimalPipe: DecimalPipe,
    @Inject(MovimientoBancoService) private movService: MovimientoBancoService,
    @Inject(CuentaBancoService) private cuentaBancoService: CuentaBancoService,
    @Inject(ValidationService) private validationService: ValidationService) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bandejaGrp = this.fb.group({
      cuentaBanco: ['', [Validators.required]],
      indicio: ['', []],
      fechaInicio: ['', []],
      fechaFin: ['', []]
    });

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboCuentaBancaria();
    this.spinnerService.hide();
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
    if (this.listaMovimientoBancos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaMovimientoBancos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  comboCuentaBancaria(): void {
    this.cuentaBancoService.listarCuentaBanco().subscribe(
      (data: CuentaBanco[]) => {
        this.listaCuentasBanco = data;
        let cb = new CuentaBanco();
        cb.id = 0;
        cb.nombre = 'TODOS';
        this.listaCuentasBanco.unshift(cb);

        this.filtrarCuentaEspecifica();
        this.buscar();
      }, error => {
        console.log(error);
      }
    );
  }

  buscar() {
    let request = new MovimientoBancoRequest();
    request.idCuentaBanco = (!this.bandejaGrp.get('cuentaBanco').value) ? 0 : this.bandejaGrp.get('cuentaBanco').value.id;
    request.indicio = this.bandejaGrp.get('indicio').value;
    request.fechaInicio = this.bandejaGrp.get('fechaInicio').value;
    request.fechaFin = this.bandejaGrp.get('fechaFin').value;

    console.log(request);

    this.dataSource = null;
    this.isLoading = true;

    this.movService.listarMovimientoBanco(request).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let result = JSON.parse(data[0].result);

          this.listaMovimientoBancos = result;
          this.cargarDatosTabla();
          this.isLoading = false;
        } else {
          console.log(data);
          this.isLoading = false;
        }
      },
      error => {
        console.error('Error al consultar datos');
        this.isLoading = false;
      }
    );
  }

  filtrarCuentaEspecifica() {
    if (sessionStorage.getItem('cuentaBanco') != null) {
      let idCuenta = parseInt(sessionStorage.getItem('cuentaBanco'));
      this.bandejaGrp.get('cuentaBanco').setValue(this.listaCuentasBanco.filter(el => el.id == idCuenta)[0]);
      sessionStorage.removeItem('cuentaBanco');
    } else {
      this.bandejaGrp.get('cuentaBanco').setValue(this.listaCuentasBanco[0]);
    }
  }

  exportarExcel() {
    console.log('Exportar');
  }

  regMovimientoBanco(obj): void {
    const dialogRef = this.dialog.open(RegMovBancoComponent, {
      width: '600px',
      data: { title: MENSAJES.INTRANET.BANDEJAMOVIMIENTO.MOVIMIENTO.REGISTRAR.TITLE, objeto: obj }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.listaMovimientoBancos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

  delMovimientoBanco(obj): void {
    let index = this.listaMovimientoBancos.indexOf(obj);

    const dialogRef = this.dialog.open(ConfirmComponent, {
      width: '500px',
      data: '¿Esta seguro que desea eliminar el movimiento?'
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result == 1) {
        this.spinnerService.show();
        this.movService.delMovimientoBanco(obj).subscribe(
          (data: ApiResponse[]) => {
            if (typeof data[0] != undefined && data[0].rcodigo == 0) {
              console.log('Exito al eiminar');
              this.listaMovimientoBancos.splice(index, 1);
              this.spinnerService.hide();
              this.cargarDatosTabla();
            } else {
              console.error('Ocurrio un error al modificar movimiento');
              this.spinnerService.hide();
            }
          }, error => {
            console.error('Error al modificar movimiento');
            this.spinnerService.hide();
          }
        );
      }
    });
  }

}
