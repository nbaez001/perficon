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

@Component({
  selector: 'app-reg-egreso',
  templateUrl: './reg-egreso.component.html',
  styleUrls: ['./reg-egreso.component.scss']
})
export class RegEgresoComponent implements OnInit {
  tiposEgreso: Maestra[] = [];
  unidadesMedida: Maestra[] = [];

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
  }

  validateForm(): void {
    this.validationService.getValidationErrors(this.egresoGrp, this.messages, this.formErrors, true);
  }

  regEgreso(): void {
    if (this.egresoGrp.valid) {
      let obj = new Egreso();
      obj.id = 0;
      obj.nombre = this.egresoGrp.get('nombre').value;
      obj.idUsuarioCrea = this.user.getIdUsuario;
      obj.fecUsuarioCrea = new Date();

      this.spinnerService.show();
      this.egresoService.regEgreso(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al registrar');
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al registrar egreso');
          }
        },
        error => {
          console.error('Error al registrar egreso');
        }
      );
    } else {
      this.validateForm();
    }
  }

}
