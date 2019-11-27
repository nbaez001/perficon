import { Component, OnInit, Inject } from '@angular/core';
import { ApiResponse } from 'src/app/model/api-response.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ValidationService } from 'src/app/services/validation.service';
import { Egreso } from 'src/app/model/egreso.model';
import { EgresoService } from 'src/app/services/intranet/egreso.service';
import { Maestra } from 'src/app/model/maestra.model';
import { DatePipe } from '@angular/common';

@Component({
  selector: 'app-reg-egreso',
  templateUrl: './reg-egreso.component.html',
  styleUrls: ['./reg-egreso.component.scss']
})
export class RegEgresoComponent implements OnInit {
  tiposEgreso: Maestra[] = [];
  unidadesMedida: Maestra[] = [];
  dias = ["LUNES", "MARTES", "MIERCOLES", "JUEVES", "VIERNES", "SABADO", "DOMINGO"];
  egresoEdit: Egreso;

  egresoGrp: FormGroup;
  messages = {
    'tipoEgreso': {
      'required': 'Field is required'
    },
    'nombre': {
      'required': 'Field is required'
    },
    'unidadMedida': {
      'required': 'Field is required'
    },
    'cantidad': {
      'required': 'Field is required'
    },
    'precio': {
      'required': 'Field is required'
    },
    'total': {
      'required': 'Field is required'
    },
    'fecha': {
      'required': 'Field is required'
    },
    'descripcion': {
    },
    'ubicacion': {
    }
  };

  formErrors = {
    'tipoEgreso': '',
    'nombre': '',
    'unidadMedida': '',
    'cantidad': '',
    'precio': '',
    'total': '',
    'fecha': '',
    'descripcion': '',
    'ubicacion': ''
  };

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegEgresoComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(EgresoService) private egresoService: EgresoService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.egresoGrp = this.fb.group({
      tipoEgreso: ['', [Validators.required]],
      nombre: ['', [Validators.required]],
      unidadMedida: ['', [Validators.required]],
      cantidad: ['', [Validators.required]],
      precio: ['', [Validators.required]],
      total: ['', [Validators.required]],
      fecha: ['', [Validators.required]],
      descripcion: ['', []],
      ubicacion: ['', []]
    });

    this.egresoGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.egresoGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboTiposEgreso();
    this.comboUnidadesMedida();
    if (this.data.objeto) {
      this.egresoEdit = JSON.parse(JSON.stringify(this.data.objeto));
      this.egresoGrp.get('tipoEgreso').setValue((this.tiposEgreso.filter(el => el.id == this.egresoEdit.idTipoEgreso))[0]);
      this.egresoGrp.get('unidadMedida').setValue((this.unidadesMedida.filter(el => el.id == this.egresoEdit.idUnidadMedida))[0]);
      this.egresoGrp.get('nombre').setValue(this.egresoEdit.nombre);
      this.egresoGrp.get('cantidad').setValue(this.egresoEdit.cantidad);
      this.egresoGrp.get('precio').setValue(this.egresoEdit.precio);
      this.egresoGrp.get('total').setValue(this.egresoEdit.total);
      this.egresoGrp.get('descripcion').setValue(this.egresoEdit.descripcion);
      this.egresoGrp.get('ubicacion').setValue(this.egresoEdit.ubicacion);
      this.egresoGrp.get('fecha').setValue(new Date(this.datePipe.transform(this.egresoEdit.fecha, 'MM/dd/yyyy')));
    } else {
      this.egresoGrp.get('fecha').setValue(new Date());
      this.egresoGrp.get('tipoEgreso').setValue(this.tiposEgreso[0]);
      this.egresoGrp.get('unidadMedida').setValue(this.unidadesMedida[0]);
    }
  }

  validateForm(): void {
    this.validationService.getValidationErrors(this.egresoGrp, this.messages, this.formErrors, true);
  }

  comboTiposEgreso(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 1;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.tiposEgreso = data;

        if (this.data.objeto) {
          this.egresoGrp.get('tipoEgreso').setValue((this.tiposEgreso.filter(el => el.id == this.egresoEdit.idTipoEgreso))[0]);
        } else {
          this.egresoGrp.get('tipoEgreso').setValue(this.tiposEgreso[2]);
        }
      }, error => {
        console.log(error);
      }
    );
  }

  comboUnidadesMedida(): void {
    let maestra = new Maestra();
    maestra.idMaestraPadre = 2;//10=>TIPOS EGRESO
    this.maestraService.listarMaestra(maestra).subscribe(
      (data: Maestra[]) => {
        this.unidadesMedida = data;

        if (this.data.objeto) {
          this.egresoGrp.get('unidadMedida').setValue((this.unidadesMedida.filter(el => el.id == this.egresoEdit.idUnidadMedida))[0]);
        } else {
          this.egresoGrp.get('unidadMedida').setValue(this.unidadesMedida[0]);
        }
      }, error => {
        console.log(error);
      }
    );
  }

  regEgreso(): void {
    if (this.egresoGrp.valid) {
      let obj = new Egreso();
      obj.id = 0;
      obj.idTipoEgreso = this.egresoGrp.get('tipoEgreso').value.id;
      obj.nomTipoEgreso = this.egresoGrp.get('tipoEgreso').value.nombre;
      obj.idUnidadMedida = this.egresoGrp.get('unidadMedida').value.id;
      obj.nomUnidadMedida = this.egresoGrp.get('unidadMedida').value.nombre;
      obj.nombre = this.egresoGrp.get('nombre').value;
      obj.cantidad = this.egresoGrp.get('cantidad').value;
      obj.precio = this.egresoGrp.get('precio').value;
      obj.total = this.egresoGrp.get('total').value;
      obj.descripcion = this.egresoGrp.get('descripcion').value;
      obj.ubicacion = this.egresoGrp.get('ubicacion').value;
      obj.fecha = this.egresoGrp.get('fecha').value;
      obj.dia = this.dias[(obj.fecha.getDay() == 0 ? 7 : obj.fecha.getDay()) - 1];
      obj.idUsuarioCrea = this.user.getIdUsuario;
      obj.fecUsuarioCrea = new Date();

      console.log(obj)

      this.spinnerService.show();
      this.egresoService.regEgreso(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al registrar');
            obj.id = data[0].rid;
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al registrar egreso');
          }
        }, error => {
          console.error('Error al registrar egreso');
        }
      );
    } else {
      this.validateForm();
    }
  }

  editEgreso(): void {
    if (this.egresoGrp.valid) {
      let obj: Egreso = JSON.parse(JSON.stringify(this.data.objeto));
      obj.idTipoEgreso = this.egresoGrp.get('tipoEgreso').value.id;
      obj.nomTipoEgreso = this.egresoGrp.get('tipoEgreso').value.nombre;
      obj.idUnidadMedida = this.egresoGrp.get('unidadMedida').value.id;
      obj.nomUnidadMedida = this.egresoGrp.get('unidadMedida').value.nombre;
      obj.nombre = this.egresoGrp.get('nombre').value;
      obj.cantidad = this.egresoGrp.get('cantidad').value;
      obj.precio = this.egresoGrp.get('precio').value;
      obj.total = this.egresoGrp.get('total').value;
      obj.descripcion = this.egresoGrp.get('descripcion').value;
      obj.ubicacion = this.egresoGrp.get('ubicacion').value;
      obj.fecha = this.egresoGrp.get('fecha').value;
      obj.dia = this.dias[(obj.fecha.getDay() == 0 ? 7 : obj.fecha.getDay()) - 1];
      obj.idUsuarioMod = this.user.getIdUsuario;
      obj.fecUsuarioMod = new Date();

      console.log(obj)

      this.spinnerService.show();
      this.egresoService.editEgreso(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al modificar');
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al modificar egreso');
          }
        }, error => {
          console.error('Error al modificar egreso');
        }
      );
    } else {
      this.validateForm();
    }
  }

  calcularTotal(): void {
    this.egresoGrp.get('total').setValue((this.egresoGrp.get('cantidad').value * this.egresoGrp.get('precio').value).toFixed(2));
  }

  calcularCantidad(): void {
    this.egresoGrp.get('cantidad').setValue((this.egresoGrp.get('total').value / this.egresoGrp.get('precio').value).toFixed(2));
  }

}
