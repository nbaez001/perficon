import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MatTableDataSource, MatDialog, MatPaginator, MatSort } from '@angular/material';
import { Validators, FormBuilder, FormGroup } from '@angular/forms';
import { DIAS, MENSAJES } from 'src/app/common';
import { Maestra } from 'src/app/model/maestra.model';
import { Egreso } from 'src/app/model/egreso.model';
import { DatePipe, DecimalPipe } from '@angular/common';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { ValidationService } from 'src/app/services/validation.service';
import { RegEgresoComponent } from './reg-egreso/reg-egreso.component';
import { EgresoService } from 'src/app/services/intranet/egreso.service';
import { EgresoRequest } from 'src/app/model/dto/egreso.request';
import { ApiResponse } from 'src/app/model/api-response.model';

@Component({
  selector: 'app-bandeja-egresos',
  templateUrl: './bandeja-egresos.component.html',
  styleUrls: ['./bandeja-egresos.component.scss']
})
export class BandejaEgresosComponent implements OnInit {
  tiposEgreso: Maestra[];
  dias = [];

  bdjEgresoGrp: FormGroup;
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
  dataSource: MatTableDataSource<Egreso>;
  isLoading: boolean = false;

  listaEgresos: Egreso[] = [];
  columnsGrilla = [
    {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (egreso: Egreso) => `${egreso.nombre}`
    }, {
      columnDef: 'nomTipoEgreso',
      header: 'Tipo egreso',
      cell: (egreso: Egreso) => `${egreso.nomTipoEgreso}`
    }, {
      columnDef: 'nomUnidadMedida',
      header: 'Unidad medida',
      cell: (egreso: Egreso) => `${egreso.nomUnidadMedida}`
    }, {
      columnDef: 'cantidad',
      header: 'Cantidad',
      cell: (egreso: Egreso) => `${egreso.cantidad}`
    }, {
      columnDef: 'precio',
      header: 'Precio',
      cell: (egreso: Egreso) => `${egreso.precio}`
    }, {
      columnDef: 'total',
      header: 'Total',
      cell: (egreso: Egreso) => `${egreso.total}`
    }, {
      columnDef: 'dia',
      header: 'Dia',
      cell: (egreso: Egreso) => `${egreso.dia}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (egreso: Egreso) => this.datePipe.transform(egreso.fecha, 'dd/MM/yyyy')
    }
  ];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    @Inject(EgresoService) private egresoService: EgresoService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(ValidationService) private validationService: ValidationService) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bdjEgresoGrp = this.fb.group({
      tipoEgreso: ['', []],
      dia: ['', []],
      indicio: ['', []],
      fechaInicio: ['', []],
      fechaFin: ['', []],
    });

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboTiposEgreso();
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
    if (this.listaEgresos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaEgresos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  comboTiposEgreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 1;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.tiposEgreso = data;
        this.tiposEgreso.unshift(new Maestra({ id: 0, nombre: 'TODOS' }));
        this.bdjEgresoGrp.get('tipoEgreso').setValue(this.tiposEgreso[0]);
        this.comboDias();
      }, error => {
        console.log(error);
      }
    );
  }

  comboDias(): void {
    this.dias = JSON.parse(JSON.stringify(DIAS));
    this.dias.unshift({ id: 0, nombre: 'TODOS' })
    this.bdjEgresoGrp.get('dia').setValue(this.dias[0]);
    this.buscar();
  }

  buscar(): void {
    let request = new EgresoRequest();
    request.idTipoEgreso = this.bdjEgresoGrp.get('tipoEgreso').value.id;
    request.dia = (this.bdjEgresoGrp.get('dia').value.id) == 0 ? '' : this.bdjEgresoGrp.get('dia').value.nombre;
    request.indicio = this.bdjEgresoGrp.get('indicio').value;
    request.fechaInicio = this.bdjEgresoGrp.get('fechaInicio').value;
    request.fechaFin = this.bdjEgresoGrp.get('fechaFin').value;

    this.dataSource = null;
    this.isLoading = true;
    this.egresoService.listarEgreso(request).subscribe(
      (data: ApiResponse[]) => {
        console.log('RESULTADO CONSULTA EGRESO');
        console.log(data);
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let result = JSON.parse(data[0].result);

          this.listaEgresos = result;
          this.cargarDatosTabla();
          this.isLoading = false;
        } else {
          console.error('Ocurrio un error al registrar egreso');
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

  regEgreso(obj): void {
    const dialogRef = this.dialog.open(RegEgresoComponent, {
      width: '600px',
      data: { title: MENSAJES.INTRANET.BANDEJAEGRESOS.EGRESO.REGISTRAR.TITLE, objeto: obj }
    });

    dialogRef.afterClosed().subscribe(result => {
      if (result) {
        this.listaEgresos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

  editEgreso(obj): void {
    let index = this.listaEgresos.indexOf(obj);
    const dialogRef = this.dialog.open(RegEgresoComponent, {
      width: '600px',
      data: { title: MENSAJES.INTRANET.BANDEJAEGRESOS.EGRESO.EDITAR.TITLE, objeto: obj }
    });

    dialogRef.afterClosed().subscribe(result => {
      console.log(result);
      if (result) {
        this.listaEgresos.splice(index, 1);
        this.listaEgresos.unshift(result);
        this.cargarDatosTabla();
      }
    });
  }

}
