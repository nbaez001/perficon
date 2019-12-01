import { Component, OnInit, Inject } from '@angular/core';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { CuentaBancoService } from 'src/app/services/intranet/cuenta-banco.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { ValidationService } from 'src/app/services/validation.service';

@Component({
  selector: 'app-reg-cuenta-banco',
  templateUrl: './reg-cuenta-banco.component.html',
  styleUrls: ['./reg-cuenta-banco.component.scss']
})
export class RegCuentaBancoComponent implements OnInit {
  formularioGrp: FormGroup;
  messages = {
    'nroCuenta': {
      'required': 'Field is required'
    },
    'cci': {
      'required': 'Field is required'
    },
    'nombre': {
      'required': 'Field is required'
    },
    'saldo': {
      'required': 'Field is required'
    }
  };
  formErrors = {
    'nroCuenta': '',
    'cci': '',
    'nombre': '',
    'saldo': ''
  };

  cuentaBancoEdit: CuentaBanco;

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegCuentaBancoComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(CuentaBancoService) private cuentaBancoService: CuentaBancoService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.formularioGrp = this.fb.group({
      nroCuenta: ['', [Validators.required]],
      cci: ['', [Validators.required]],
      nombre: ['', [Validators.required]],
      saldo: ['', [Validators.required]],
    });

    this.formularioGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    if (this.data.objeto) {
      this.cuentaBancoEdit = JSON.parse(JSON.stringify(this.data.objeto));
      this.formularioGrp.get('nroCuenta').setValue(this.cuentaBancoEdit.nroCuenta);
      this.formularioGrp.get('cci').setValue(this.cuentaBancoEdit.cci);
      this.formularioGrp.get('nombre').setValue(this.cuentaBancoEdit.nombre);
      this.formularioGrp.get('saldo').setValue(this.cuentaBancoEdit.saldo);
    } else {

    }
  }

  regCuentaBanco(): void {
    if (this.formularioGrp.valid) {
      let obj = new CuentaBanco();
      obj.id = 0;
      obj.nroCuenta = this.formularioGrp.get('nroCuenta').value;
      obj.cci = this.formularioGrp.get('cci').value;
      obj.nombre = this.formularioGrp.get('nombre').value;
      obj.saldo = this.formularioGrp.get('saldo').value;
      obj.idUsuarioCrea = this.user.getIdUsuario;
      obj.fecUsuarioCrea = new Date();

      this.spinnerService.show();
      this.cuentaBancoService.regCuentaBanco(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            obj.id = data[0].rid;
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al registrar maestra');
          }
        },
        error => {
          console.error('Error al registrar maestra');
        }
      );
    } else {
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, true);
    }
  }

  editCuentaBanco(): void {
    if (this.formularioGrp.valid) {
      let obj: CuentaBanco = JSON.parse(JSON.stringify(this.data.objeto));
      obj.nroCuenta = this.formularioGrp.get('nroCuenta').value;
      obj.cci = this.formularioGrp.get('cci').value;
      obj.nombre = this.formularioGrp.get('nombre').value;
      obj.saldo = this.formularioGrp.get('saldo').value;
      obj.idUsuarioMod = this.user.getIdUsuario;
      obj.fecUsuarioMod = new Date();

      this.spinnerService.show();
      this.cuentaBancoService.editCuentaBanco(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
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
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, true);
    }
  }

}
