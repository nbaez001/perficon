import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { RegMaestraComponent } from './reg-maestra/reg-maestra.component';
import { MENSAJES } from 'src/app/common';
import { RegMaestraChildComponent } from './reg-maestra-child/reg-maestra-child.component';

@Component({
  selector: 'app-configuracion-maestra',
  templateUrl: './configuracion-maestra.component.html',
  styleUrls: ['./configuracion-maestra.component.scss']
})
export class ConfiguracionMaestraComponent implements OnInit {
  listaMaestra: Maestra[];
  displayedColumns: string[];
  dataSource: MatTableDataSource<Maestra>;

  bdjMaestraGrp: FormGroup;
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
    },
    'confirmEmail': {
      'required': 'Field is required',
      'email': 'Insert a valid email'
    },
    'phone': {
      'required': 'Phone is required'
    },
    'skill': {
      'name': {
        'required': 'Field is required',
        'minlength': 'Insert al least 5 characters',
        'maxlength': 'max name size 20 characters'
      },
      'years': {
        'required': 'Field is required',
        'min': 'Min value is 1',
        'max': 'Max value is 100'
      },
      'proficiency': {
        'required': 'option is required'
      }
    }
  };

  formErrors = {
    'name': '',
    'email': '',
    'confirmEmail': '',
    'phone': '',
    'skill': {
      'name': '',
      'years': '',
      'proficiency': ''
    }
  };

  columnsGrilla = [
    {
      columnDef: 'id',
      header: 'N°',
      cell: (maestra: Maestra) => `${maestra.id}`
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
      cell: (maestra: Maestra) => `${maestra.fecUsuarioCrea}`
    }, {
      columnDef: 'idUsuarioMod',
      header: 'Usuario modificacion',
      cell: (maestra: Maestra) => (maestra.idUsuarioMod != null) ? `${maestra.idUsuarioMod}` : ''
    }, {
      columnDef: 'fecUsuarioMod',
      header: 'Fecha modificacion',
      cell: (maestra: Maestra) => (maestra.fecUsuarioMod != null) ? `${maestra.fecUsuarioMod}` : ''
    }];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(MaestraService) private maestraService: MaestraService) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bdjMaestraGrp = this.fb.group({
      name: ['', [Validators.required]]
    });

    this.listaMaestra = [];

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.dataSource = null;
    // this.banMonitoreoFrmGrp.get('estadoMonitoreoFrmCtrl').setValue(ESTADO_MONITOREO.pendienteInformacion);
    let maestra = new Maestra();
    maestra.idMaestraPadre = 0;
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.listaMaestra = data;
        this.cargarDatosTabla();
      },
      error => {
        console.error('Error al consultar datos');
      }
    );
  }

  definirTabla(): void {
    this.displayedColumns = [];
    this.columnsGrilla.forEach(c => {
      this.displayedColumns.push(c.columnDef);
    });
    this.displayedColumns.push('opt');
  }

  public cargarDatosTabla(): void {
    if (this.listaMaestra.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaMaestra);
      this.dataSource.paginator = this.paginator;
      this.dataSource.sort = this.sort;
    }
    this.spinnerService.hide();
  }

  buscar() {
    console.log('Buscar');
  }

  exportarExcel() {
    console.log('Exportar');
  }

  regMaestra(obj: Maestra) {
    const dialogRef = this.dialog.open(RegMaestraComponent, {
      width: '500px',
      disableClose: false,
      data: {
        title: MENSAJES.INTRANET.CONFIGURACION.MAESTRA.REGISTRAR.TITLE,
        maestra: obj
      }
    });

    dialogRef.afterClosed().subscribe((result) => {
      console.log(result);
    });
  }

  regMaestraChild(obj: Maestra) {
    const dialogRef = this.dialog.open(RegMaestraChildComponent, {
      width: '500px',
      disableClose: false,
      data: {
        title: MENSAJES.INTRANET.CONFIGURACION.MAESTRA.REGISTRARCHILD.TITLE,
        maestra: obj
      }
    });

    dialogRef.afterClosed().subscribe((result) => {
      console.log(result);
    });
  }
}
