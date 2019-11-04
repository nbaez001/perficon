import { Component, OnInit, ViewChild } from '@angular/core';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MatTableDataSource, MatDialog, MatPaginator, MatSort } from '@angular/material';
import { Validators, FormBuilder, FormGroup } from '@angular/forms';
import { Vehiculo } from 'src/app/model/vehiculo.model';
import { UNIDADES, TAMBOS, TIPOSVEHICULO } from 'src/app/common';

@Component({
  selector: 'app-bandeja-egresos',
  templateUrl: './bandeja-egresos.component.html',
  styleUrls: ['./bandeja-egresos.component.scss']
})
export class BandejaEgresosComponent implements OnInit {
  unidades = UNIDADES;
  tambos = TAMBOS;
  tiposvehiculo = TIPOSVEHICULO;
  listaVehiculos: Vehiculo[] = [
    { id: 1, unidad: 'AYACUCHO NORTE', tambo: 'SEDE', tipo: 'CAMIONETA', marca: 'NISSAN', placa: 'EGT-079', ultMantenimiento: 'DIC 2018', estadoVehiculo: 'NO OPERATIVO', iniVigenciaRevTecnica: '19/05/2018', finVigenciaRevTecnica: '19/06/2019', iniVigenciaSOAT: '26/02/2018', finVigenciaSOAT: '26/02/2019', tipoCombustible: 'DIESEL B5', fecInfraccionVehicular: '' },
    { id: 2, unidad: 'AYACUCHO NORTE', tambo: 'ANCARPATA', tipo: 'MOTOCICLETA', marca: 'ZONGSHEN', placa: 'EA-9256', ultMantenimiento: 'DIC 2018', estadoVehiculo: 'CON LIMITACIONES', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '14/03/2018', finVigenciaSOAT: '14/03/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '' },
    { id: 3, unidad: 'AYACUCHO NORTE', tambo: 'BARRIO VISTA ALEGRE', tipo: 'MOTOCICLETA', marca: 'ZONGSHEN', placa: 'EA-9263', ultMantenimiento: 'DIC 2018', estadoVehiculo: 'OPERATIVO', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '14/03/2018', finVigenciaSOAT: '14/03/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '' },
    { id: 4, unidad: 'AYACUCHO NORTE', tambo: 'CCERAOCRO', tipo: 'MOTOCICLETA', marca: 'HONDA', placa: 'EW-0715', ultMantenimiento: '', estadoVehiculo: 'OPERATIVO', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '13/08/2018', finVigenciaSOAT: '13/08/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '2017' },
    { id: 5, unidad: 'AYACUCHO NORTE', tambo: 'CHACHASPATA', tipo: 'MOTOCICLETA', marca: 'HONDA', placa: 'EB-7316', ultMantenimiento: 'NOVIEMBRE 2018', estadoVehiculo: 'OPERATIVO', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '08/08/2018', finVigenciaSOAT: '08/08/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '' },
    { id: 6, unidad: 'AYACUCHO NORTE', tambo: 'CHURUNMARCA', tipo: 'MOTOCICLETA', marca: 'HONDA', placa: 'EW-0724', ultMantenimiento: '', estadoVehiculo: 'OPERATIVO', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '13/08/2018', finVigenciaSOAT: '13/08/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '' },
    { id: 7, unidad: 'AYACUCHO NORTE', tambo: 'COCHAPAMPA', tipo: 'MOTOCICLETA', marca: 'ZONGSHEN', placa: 'EA-9316', ultMantenimiento: 'NOVIEMBRE 2018', estadoVehiculo: 'CON LIMITACIONES', iniVigenciaRevTecnica: '', finVigenciaRevTecnica: '', iniVigenciaSOAT: '29/11/2018', finVigenciaSOAT: '29/11/2019', tipoCombustible: 'GASOHOL 90', fecInfraccionVehicular: '' }
  ];
  displayedColumns: string[];
  dataSource: MatTableDataSource<Vehiculo>;

  bdjVehiculoGrp: FormGroup;
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
      cell: (vehiculo: Vehiculo) => `${vehiculo.id}`
    }, {
      columnDef: 'unidad',
      header: 'UNIDAD',
      cell: (vehiculo: Vehiculo) => `${vehiculo.unidad}`
    }, {
      columnDef: 'tambo',
      header: 'TAMBO',
      cell: (vehiculo: Vehiculo) => `${vehiculo.tambo}`
    }, {
      columnDef: 'tipo',
      header: 'TIPO',
      cell: (vehiculo: Vehiculo) => `${vehiculo.tipo}`
    }, {
      columnDef: 'marca',
      header: 'MARCA',
      cell: (vehiculo: Vehiculo) => `${vehiculo.marca}`
    }, {
      columnDef: 'placa',
      header: 'PLACA',
      cell: (vehiculo: Vehiculo) => `${vehiculo.placa}`
    }, {
      columnDef: 'ultMantenimiento',
      header: 'ULTIMO MANTENIMIENTO',
      cell: (vehiculo: Vehiculo) => `${vehiculo.ultMantenimiento}`
    }, {
      columnDef: 'estadoVehiculo',
      header: 'ESTADO VEHICULO',
      cell: (vehiculo: Vehiculo) => `${vehiculo.estadoVehiculo}`
    }, {
      columnDef: 'iniVigenciaRevTecnica',
      header: 'INICIO VIG. REVISION TECNICA',
      cell: (vehiculo: Vehiculo) => `${vehiculo.iniVigenciaRevTecnica}`
    }, {
      columnDef: 'finVigenciaRevTecnica',
      header: 'FIN VIG. REVISION TECNICA',
      cell: (vehiculo: Vehiculo) => `${vehiculo.finVigenciaRevTecnica}`
    }, {
      columnDef: 'iniVigenciaSOAT',
      header: 'INICIO VIG. SOAT',
      cell: (vehiculo: Vehiculo) => `${vehiculo.iniVigenciaSOAT}`
    }, {
      columnDef: 'finVigenciaSOAT',
      header: 'FIN VIG. SOAT',
      cell: (vehiculo: Vehiculo) => `${vehiculo.finVigenciaSOAT}`
    }, {
      columnDef: 'tipoCombustible',
      header: 'TIPO COMBUSTIBLE',
      cell: (vehiculo: Vehiculo) => `${vehiculo.tipoCombustible}`
    }, {
      columnDef: 'fecInfraccionVehicular',
      header: 'FEC. INFRACCION',
      cell: (vehiculo: Vehiculo) => `${vehiculo.fecInfraccionVehicular}`
    }];

  @ViewChild(MatPaginator) paginator: MatPaginator;
  @ViewChild(MatSort) sort: MatSort;

  constructor(private fb: FormBuilder, public dialog: MatDialog, private spinnerService: Ng4LoadingSpinnerService) { }

  ngOnInit() {
    this.spinnerService.show();

    this.bdjVehiculoGrp = this.fb.group({
      name: ['', [Validators.required]]
    });

    this.definirTabla();
    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.dataSource = null;
    // this.banMonitoreoFrmGrp.get('estadoMonitoreoFrmCtrl').setValue(ESTADO_MONITOREO.pendienteInformacion);
    this.cargarDatosTabla();
  }

  definirTabla(): void {
    this.displayedColumns = [];
    this.columnsGrilla.forEach(c => {
      this.displayedColumns.push(c.columnDef);
    });
    this.displayedColumns.push('opt');
  }

  public cargarDatosTabla(): void {
    if (this.listaVehiculos.length > 0) {
      this.dataSource = new MatTableDataSource(this.listaVehiculos);
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

  // regVehiculo(obj): void {
  //   console.log(obj);
  //   const dialogRef = this.dialog.open(RegistrarVehiculoComponent, {
  //     width: '500px',
  //     data: { name: 'NERIO', animal: 'LEON' }
  //   });

  //   dialogRef.afterClosed().subscribe(result => {
  //     console.log(result);
  //   });
  // }

}
