import { Component, OnInit, Inject, ViewChild } from '@angular/core';
import { ApiResponse } from 'src/app/model/api-response.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA, MatDialog, MatTableDataSource, MatPaginator, MatSort } from '@angular/material';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ValidationService } from 'src/app/services/validation.service';
import { Egreso } from 'src/app/model/egreso.model';
import { EgresoService } from 'src/app/services/intranet/egreso.service';
import { Maestra } from 'src/app/model/maestra.model';
import { DatePipe, DecimalPipe } from '@angular/common';
import { tablasMaestra } from 'src/app/common';
import { BuscarWalletRequest } from 'src/app/dto/request/buscar-wallet.request';
import { ApiOutResponse } from 'src/app/model/dto/api-out.response';
import { WalletResponse } from 'src/app/dto/response/wallet.response';
import { BuscarCuentaBancoRequest } from 'src/app/dto/request/buscar-cuenta-banco.request';
import { CuentaBancoService } from 'src/app/services/intranet/cuenta-banco.service';
import { WalletService } from 'src/app/services/intranet/wallet.service';
import { CuentaBancoResponse } from 'src/app/dto/response/cuenta-banco.response';
import { CambiarCuentaComponent } from './cambiar-cuenta/cambiar-cuenta.component';
import { MENSAJES } from 'src/app/common';
import { DetalleEgresoResponse } from 'src/app/dto/response/detalle-egreso.response';
import { RegDetEgresoComponent } from './reg-det-egreso/reg-det-egreso.component';

@Component({
  selector: 'app-reg-egreso',
  templateUrl: './reg-egreso.component.html',
  styleUrls: ['./reg-egreso.component.scss']
})
export class RegEgresoComponent implements OnInit {
  categoriasEgreso: Maestra[] = [];

  listaWallet: WalletResponse[] = [];
  listaCuentaBanco: CuentaBancoResponse[] = [];
  flgCuenta: number = -1;

  egresoEdit: Egreso;

  formularioGrp: FormGroup;
  messages = {
    'categoriaEgreso': {
      'required': 'Campo requerido'
    }
  };
  formErrors = {
    'categoriaEgreso': '',
  };

  displayedColumns: string[];
  dataSource: MatTableDataSource<DetalleEgresoResponse> = new MatTableDataSource([]);
  isLoading: boolean = false;
  listaDetalleEgresos: DetalleEgresoResponse[] = [];
  columnsGrilla = [
    {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.nombre) ? detEgreso.nombre : ''}`
    }, {
      columnDef: 'nomTipoEgreso',
      header: 'Tipo egreso',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.nomTipoEgreso) ? detEgreso.nomTipoEgreso : ''}`
    }, {
      columnDef: 'nomUnidadMedida',
      header: 'Unidad medida',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.nomUnidadMedida) ? detEgreso.nomUnidadMedida : ''}`
    }, {
      columnDef: 'cantidad',
      header: 'Cantidad',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.cantidad) ? this.decimalPipe.transform(detEgreso.cantidad, '1.1-1') : ''}`
    }, {
      columnDef: 'precio',
      header: 'Precio',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.precio) ? this.decimalPipe.transform(detEgreso.precio, '1.2-2') : ''}`
    }, {
      columnDef: 'total',
      header: 'Total',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.total) ? this.decimalPipe.transform(detEgreso.total, '1.2-2') : ''}`
    }, {
      columnDef: 'dia',
      header: 'Dia',
      cell: (detEgreso: DetalleEgresoResponse) => `${(detEgreso.dia) ? detEgreso.dia : ''}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (detEgreso: DetalleEgresoResponse) => this.datePipe.transform(detEgreso.fecha, 'dd/MM/yyyy')
    }
  ];
  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder,
    public dialog: MatDialog,
    public dialogRef: MatDialogRef<RegEgresoComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    private decimalPipe: DecimalPipe,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(EgresoService) private egresoService: EgresoService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(WalletService) private walletService: WalletService,
    @Inject(CuentaBancoService) private cuentaBancoService: CuentaBancoService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.formularioGrp = this.fb.group({
      cuenta: ['', [Validators.required]],
      categoriaEgreso: ['', [Validators.required]],
    });

    this.formularioGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, false);
    });

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboCategoriaEgreso();
    this.radioWallet();
    if (this.data.objeto) {
      this.egresoEdit = JSON.parse(JSON.stringify(this.data.objeto));
      // this.egresoGrp.get('categoriaEgreso').setValue((this.categoriasEgreso.filter(el => el.id == this.egresoEdit.idCategoriaEgreso))[0]);
    } else {
      // this.egresoGrp.get('fecha').setValue(new Date(this.datePipe.transform(new Date(), 'MM/dd/yyyy')));
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
    if (this.listaDetalleEgresos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaDetalleEgresos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  comboCategoriaEgreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = tablasMaestra.CATEGORIA_EGRESO.id;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.categoriasEgreso = data;

        if (this.data.objeto) {
          this.formularioGrp.get('categoriaEgreso').setValue((this.categoriasEgreso.filter(el => el.id == this.egresoEdit.idCategoriaEgreso))[0]);
        } else {
          this.formularioGrp.get('categoriaEgreso').setValue(this.categoriasEgreso[0]);
        }
      }, error => {
        console.log(error);
      }
    );
  }

  radioWallet(): void {
    let req = new BuscarWalletRequest();
    this.walletService.listarWallet(req).subscribe(
      (data: ApiOutResponse<WalletResponse[]>) => {
        if (data.rCodigo == 0) {
          this.listaWallet = data.result;
          this.flgCuenta = 0;
          this.formularioGrp.get('cuenta').setValue(this.listaWallet[0]);
        }
        this.radioCuentaBanco();
      }, error => {
        console.log(error);
        this.radioCuentaBanco();
      }
    );
  }

  radioCuentaBanco(): void {
    let req = new BuscarCuentaBancoRequest();
    this.cuentaBancoService.listarCuentaBanco(req).subscribe(
      (data: ApiOutResponse<CuentaBancoResponse[]>) => {
        if (data.rCodigo == 0) {
          this.listaCuentaBanco = data.result;
          if (this.flgCuenta == -1) {
            this.flgCuenta = 1;
            this.formularioGrp.get('cuenta').setValue(this.listaCuentaBanco[0]);
          }
        }
      }, error => {
        console.log(error);
      }
    );
  }

  cambiarCuenta(cod: number): void {
    this.flgCuenta = cod;
  }

  toggleCuenta(lista: any[]): void {
    console.log('TOGGLE WALLET');
    const dialogRef = this.dialog.open(CambiarCuentaComponent, {
      width: '300px',
      data: { title: MENSAJES.INTRANET.BANDEJAEGRESOS.EGRESO.REGISTRAR.CAMBIAR_CUENTA.TITLE, objeto: lista }
    });
    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        lista = result;
      }
    });
  }

  regDetEgreso(): void {
    let dialofRef = this.dialog.open(RegDetEgresoComponent, {
      width: '600px',
      data: { title: MENSAJES.INTRANET.BANDEJAEGRESOS.EGRESO.DETALLE_EGRESO.TITLE, objeto: null }
    });

    dialofRef.afterClosed().subscribe(result => {
      if (result) {
        this.listaDetalleEgresos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }


}
