import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Maestra } from 'src/app/model/maestra.model';
import { Egreso } from 'src/app/model/egreso.model';
import { SelectionModel } from '@angular/cdk/collections';
import { MatTableDataSource, MatPaginator, MatSort, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { EgresoService } from 'src/app/services/intranet/egreso.service';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ValidationService } from 'src/app/services/validation.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DatePipe, DecimalPipe } from '@angular/common';
import { DIAS } from 'src/app/common';
import { EgresoRequest } from 'src/app/model/dto/egreso.request';
import { ApiResponse } from 'src/app/model/api-response.model';

@Component({
  selector: 'app-busc-egreso',
  templateUrl: './busc-egreso.component.html',
  styleUrls: ['./busc-egreso.component.scss']
})
export class BuscEgresoComponent implements OnInit {
  formularioGrp: FormGroup;
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

  tiposEgreso: Maestra[];
  dias = [];
  isLoading: boolean = false;

  selection = new SelectionModel<Egreso>(true, []);
  displayedColumns: string[];
  dataSource: MatTableDataSource<Egreso> = new MatTableDataSource([]);;
  listaEgresos: Egreso[] = [];
  columnsGrilla = [
    {
      columnDef: 'nombre',
      header: 'Nombre',
      cell: (egreso: Egreso) => `${(egreso.nombre) ? egreso.nombre : ''}`
    }, {
      columnDef: 'nomTipoEgreso',
      header: 'Tipo egreso',
      cell: (egreso: Egreso) => `${(egreso.nomTipoEgreso) ? egreso.nomTipoEgreso : ''}`
    }, {
      columnDef: 'nomUnidadMedida',
      header: 'Unidad medida',
      cell: (egreso: Egreso) => `${(egreso.nomUnidadMedida) ? egreso.nomUnidadMedida : ''}`
    }, {
      columnDef: 'cantidad',
      header: 'Cantidad',
      cell: (egreso: Egreso) => `${(egreso.cantidad) ? this.decimalPipe.transform(egreso.cantidad, '1.1-1') : ''}`
    }, {
      columnDef: 'precio',
      header: 'Precio',
      cell: (egreso: Egreso) => `${(egreso.precio) ? this.decimalPipe.transform(egreso.precio, '1.2-2') : ''}`
    }, {
      columnDef: 'total',
      header: 'Total',
      cell: (egreso: Egreso) => `${(egreso.total) ? this.decimalPipe.transform(egreso.total, '1.2-2') : ''}`
    }, {
      columnDef: 'totalEgreso',
      header: 'Pend. retorno',
      cell: (egreso: Egreso) => `${(egreso.totalEgreso) ? this.decimalPipe.transform(egreso.totalEgreso, '1.2-2') : ''}`
    }, {
      columnDef: 'dia',
      header: 'Dia',
      cell: (egreso: Egreso) => `${(egreso.dia) ? egreso.dia : ''}`
    }, {
      columnDef: 'fecha',
      header: 'Fecha',
      cell: (egreso: Egreso) => this.datePipe.transform(egreso.fecha, 'dd/MM/yyyy')
    }
  ];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<BuscEgresoComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(EgresoService) private egresoService: EgresoService,
    @Inject(MaestraService) private maestraService: MaestraService,
    private datePipe: DatePipe,
    private decimalPipe: DecimalPipe,
  ) { }

  ngOnInit() {
    this.spinnerService.show();

    this.formularioGrp = this.fb.group({
      tipoEgreso: ['', []],
      indicio: ['', []],
      fechaInicio: ['', []],
      fechaFin: ['', []],
    });

    this.inicializarVariables();
  }
  get getUser(): UsuarioService { return this.user; }

  isAllSelected() {
    const numSelected = this.selection.selected.length;
    const numRows = this.dataSource.data.length;
    return numSelected === numRows;
  }

  /** Selects all rows if they are not all selected; otherwise clear selection. */
  masterToggle() {
    if (this.isAllSelected()) {
      this.selection.clear()
    } else {
      this.dataSource.data.forEach(row => {
        if (row.totalEgreso > 0.0) {
          this.selection.select(row)
        }
      });
    }
  }

  /** The label for the checkbox on the passed row */
  checkboxLabel(row?: Egreso): string {
    if (!row) {
      return `${this.isAllSelected() ? 'select' : 'deselect'} all`;
    }
    return `${this.selection.isSelected(row) ? 'deselect' : 'select'} row ${row.id + 1}`;
  }

  definirTabla(): void {
    this.displayedColumns = [];
    this.columnsGrilla.forEach(c => {
      this.displayedColumns.push(c.columnDef);
    });
    this.displayedColumns.unshift('select');
  }

  public cargarDatosTabla(): void {
    this.dataSource = null;
    if (this.listaEgresos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaEgresos);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
  }

  public inicializarVariables(): void {
    this.definirTabla();
    this.comboTiposEgreso();
    this.spinnerService.hide();
  }

  comboTiposEgreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 1;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.tiposEgreso = data;
        this.formularioGrp.get('tipoEgreso').setValue(this.tiposEgreso[13]);
      }, error => {
        console.log(error);
      }
    );
  }

  buscar(): void {
    let request = new EgresoRequest();
    request.idTipoEgreso = (!this.formularioGrp.get('tipoEgreso').value) ? 0 : this.formularioGrp.get('tipoEgreso').value.id;
    request.dia = '';
    request.indicio = this.formularioGrp.get('indicio').value;
    request.fechaInicio = this.formularioGrp.get('fechaInicio').value;
    request.fechaFin = this.formularioGrp.get('fechaFin').value;

    console.log(request);

    this.dataSource = null;
    this.isLoading = true;
    this.egresoService.listarEgreso(request).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let result = JSON.parse(data[0].result);

          this.listaEgresos = result ? result : [];
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

  agregar(): void {
    this.dialogRef.close(this.selection.selected);
  }

  limpiar(): void {
    
  }
}
