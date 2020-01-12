import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { FormGroup, FormBuilder } from '@angular/forms';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog } from '@angular/material';
import { Ingreso } from 'src/app/model/ingreso.model';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DatePipe, DecimalPipe } from '@angular/common';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { ValidationService } from 'src/app/services/validation.service';
import { IngresoService } from 'src/app/services/intranet/ingreso.service';
import { IngresoRequest } from 'src/app/model/dto/ingreso.request';
import { ApiResponse } from 'src/app/model/api-response.model';
import { RegIngresoComponent } from './reg-ingreso/reg-ingreso.component';
import { MENSAJES } from 'src/app/common';

@Component({
  selector: 'app-bandeja-ingresos',
  templateUrl: './bandeja-ingresos.component.html',
  styleUrls: ['./bandeja-ingresos.component.scss']
})
export class BandejaIngresosComponent implements OnInit {
  tiposIngreso: Maestra[];
  dias = [];

  bdjIngresoGrp: FormGroup;
  messages = {
    'name': {
      'required': 'Field is required',
      'minlength': 'Insert al least 2 characters',
      'maxlength': 'Max name size 20 characters'
    }
  };
  formErrors = {
    'name': ''
  };

  displayedColumns: string[];
  dataSource: MatTableDataSource<Ingreso>;
  isLoading: boolean = false;

  fechaRep: Date = null;

  listaIngresos: Ingreso[] = [];
  columnsGrilla = [
    {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (ingreso: Ingreso) => `${(ingreso.nombre) ? ingreso.nombre : ''}`
    }, {
      columnDef: 'nomTipoIngreso',
      header: 'Tipo ingreso',
      cell: (ingreso: Ingreso) => `${(ingreso.nomTipoIngreso) ? ingreso.nomTipoIngreso : ''}`
    }, {
      columnDef: 'monto',
      header: 'Monto',
      cell: (ingreso: Ingreso) => `${(ingreso.monto) ? this.decimalPipe.transform(ingreso.monto, '1.2-2') : ''}`
    }, {
      columnDef: 'observacion',
      header: 'Observacion',
      cell: (ingreso: Ingreso) => `${(ingreso.observacion) ? ingreso.observacion : ''}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (ingreso: Ingreso) => this.datePipe.transform(ingreso.fecha, 'dd/MM/yyyy')
    }
  ];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    private decimalPipe: DecimalPipe,
    @Inject(IngresoService) private ingresoService: IngresoService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(ValidationService) private validationService: ValidationService) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bdjIngresoGrp = this.fb.group({
      tipoIngreso: ['', []],
      indicio: ['', []],
      fechaInicio: ['', []],
      fechaFin: ['', []],
    });

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboTiposIngreso();
    this.buscar();
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
    if (this.listaIngresos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaIngresos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  comboTiposIngreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 30;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.tiposIngreso = data;
        this.tiposIngreso.unshift(new Maestra({ id: 0, nombre: 'TODOS' }));
        this.bdjIngresoGrp.get('tipoIngreso').setValue(this.tiposIngreso[0]);
      }, error => {
        console.log(error);
      }
    );
  }

  buscar(): void {
    let request = new IngresoRequest();
    request.idTipoIngreso = (!this.bdjIngresoGrp.get('tipoIngreso').value) ? 0 : this.bdjIngresoGrp.get('tipoIngreso').value.id;
    request.indicio = this.bdjIngresoGrp.get('indicio').value;
    request.fechaInicio = this.bdjIngresoGrp.get('fechaInicio').value;
    request.fechaFin = this.bdjIngresoGrp.get('fechaFin').value;

    console.log(request);

    this.dataSource = null;
    this.isLoading = true;
    this.ingresoService.listarIngreso(request).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let result = JSON.parse(data[0].result);

          this.listaIngresos = result ? result : [];
          this.cargarDatosTabla();
          this.isLoading = false;
        } else {
          console.error('Ocurrio un error al registrar ingreso');
          this.isLoading = false;
        }
      },
      error => {
        console.error('Error al consultar datos');
        this.isLoading = false;
      }
    );
  }

  exportarExcel() {
    console.log('Exportar');
  }

  regIngreso(obj): void {
    const dialogRef = this.dialog.open(RegIngresoComponent, {
      width: '700px',
      data: { title: MENSAJES.INTRANET.BANDEJAINGRESOS.INGRESO.REGISTRAR.TITLE, objeto: obj }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.listaIngresos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

  editIngreso(obj): void {
    let index = this.listaIngresos.indexOf(obj);
    const dialogRef = this.dialog.open(RegIngresoComponent, {
      width: '700px',
      data: { title: MENSAJES.INTRANET.BANDEJAINGRESOS.INGRESO.EDITAR.TITLE, objeto: obj }
    });

    dialogRef.afterClosed().subscribe(result => {
      console.log(result);
      if (result) {
        this.listaIngresos.splice(index, 1);
        this.listaIngresos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

}
