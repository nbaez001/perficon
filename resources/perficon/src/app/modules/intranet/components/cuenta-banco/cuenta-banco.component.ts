import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DatePipe } from '@angular/common';
import { CuentaBancoService } from 'src/app/services/intranet/cuenta-banco.service';
import { RegCuentaBancoComponent } from './reg-cuenta-banco/reg-cuenta-banco.component';
import { MENSAJES } from 'src/app/common';

@Component({
  selector: 'app-cuenta-banco',
  templateUrl: './cuenta-banco.component.html',
  styleUrls: ['./cuenta-banco.component.scss']
})
export class CuentaBancoComponent implements OnInit {
  listaCuentaBanco: CuentaBanco[];

  displayedColumns: string[];
  dataSource: MatTableDataSource<CuentaBanco>;
  isLoading: boolean = false;

  bandejaGrp: FormGroup;
  messages = {
    'name': {
      'required': 'Field is required',
      'minlength': 'Insert al least 2 characters',
      'maxlength': 'Max name size 20 characters'
    },
    'email': {
      'required': 'Field is required',
      'email': 'Insert a valid email',
      'customEmail': 'Email domain should be dell.com'
    }
  };
  formErrors = {
    'name': '',
    'email': ''
  };

  columnsGrilla = [
    {
      columnDef: 'id',
      header: 'N°',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.id}`
    }, {
      columnDef: 'nroCuenta',
      header: 'Numero cuenta',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.nroCuenta}`
    }, {
      columnDef: 'cci',
      header: 'CCI',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.cci}`
    }, {
      columnDef: 'nombre',
      header: 'Nombre banco',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.nombre}`
    }, {
      columnDef: 'saldo',
      header: 'Saldo',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.saldo}`
    }, {
      columnDef: 'idUsuarioCrea',
      header: 'Usuario creador',
      cell: (cuentaBanco: CuentaBanco) => `${cuentaBanco.idUsuarioCrea}`
    }, {
      columnDef: 'fecUsuarioCrea',
      header: 'Fecha creacion',
      cell: (cuentaBanco: CuentaBanco) => this.datePipe.transform(cuentaBanco.fecUsuarioCrea, 'dd/MM/yyyy')
    }, {
      columnDef: 'idUsuarioMod',
      header: 'Usuario modificacion',
      cell: (cuentaBanco: CuentaBanco) => (cuentaBanco.idUsuarioMod != null) ? `${cuentaBanco.idUsuarioMod}` : ''
    }, {
      columnDef: 'fecUsuarioMod',
      header: 'Fecha modificacion',
      cell: (cuentaBanco: CuentaBanco) => this.datePipe.transform(cuentaBanco.fecUsuarioMod, 'dd/MM/yyyy')
    }];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder,
    public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(CuentaBancoService) private cuentaBancoService: CuentaBancoService,
    private datePipe: DatePipe) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bandejaGrp = this.fb.group({
      name: ['', [Validators.required]]
    });

    this.listaCuentaBanco = [];

    this.definirTabla();
    this.inicializarVariables();
  }

  inicializarVariables(): void {
    // this.banMonitoreoFrmGrp.get('estadoMonitoreoFrmCtrl').setValue(ESTADO_MONITOREO.pendienteInformacion);
    this.listarCuentaBanco();
    this.spinnerService.hide();
  }

  definirTabla(): void {
    this.displayedColumns = [];
    this.columnsGrilla.forEach(c => {
      this.displayedColumns.push(c.columnDef);
    });
    this.displayedColumns.push('opt');
  }

  public cargarDatosTabla(): void {
    this.dataSource = null;
    if (this.listaCuentaBanco.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaCuentaBanco);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  listarCuentaBanco(): void {
    this.dataSource = null;
    this.isLoading = true;

    this.cuentaBancoService.listarCuentaBanco().subscribe(
      (data: CuentaBanco[]) => {
        this.listaCuentaBanco = data;
        this.cargarDatosTabla();
        this.isLoading = false;
      },
      error => {
        console.error('Error al consultar datos');
        this.isLoading = false;
      }
    );
  }

  buscar() {
    console.log('Buscar');
  }

  exportarExcel() {
    console.log('Exportar');
  }

  regCuentaBanco(obj: CuentaBanco) {
    const dialogRef = this.dialog.open(RegCuentaBancoComponent, {
      width: '500px',
      disableClose: false,
      data: {
        title: MENSAJES.INTRANET.CONFIGURACION.CUENTABANCO.REGISTRAR.TITLE,
        objeto: obj
      }
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.listaCuentaBanco.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

  editCuentaBanco(obj: CuentaBanco) {
    let index = this.listaCuentaBanco.indexOf(obj);
    const dialogRef = this.dialog.open(RegCuentaBancoComponent, {
      width: '500px',
      disableClose: false,
      data: {
        title: MENSAJES.INTRANET.CONFIGURACION.CUENTABANCO.MODIFICAR.TITLE,
        objeto: obj
      }
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.listaCuentaBanco.splice(index, 1);
        this.listaCuentaBanco.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

}
