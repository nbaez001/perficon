import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { ApiResponse } from 'src/app/model/api-response.model';

@Component({
  selector: 'app-reg-maestra',
  templateUrl: './reg-maestra.component.html',
  styleUrls: ['./reg-maestra.component.scss']
})
export class RegMaestraComponent implements OnInit {
  maestraGrp: FormGroup;
  messages = {
    'nombre': {
      'required': 'Field is required'
    },
    'codigo': {
      'required': 'Field is required'
    },
    'valor': {
      'required': 'Field is required'
    }
  };
  formErrors = {
    'nombre': '',
    'codigo': '',
    'valor': ''
  };

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegMaestraComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(MaestraService) private maestraService: MaestraService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.maestraGrp = this.fb.group({
      nombre: ['', [Validators.required]],
      codigo: ['', [Validators.required]],
      valor: ['', []]
    });

    this.maestraGrp.valueChanges.subscribe((val: any) => {
      console.log(JSON.stringify(val));
      this.logValidationErrors(this.maestraGrp, this.messages, this.formErrors);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
  }

  validateForm(): void {
    this.logValidationErrors(this.maestraGrp, this.messages, this.formErrors);
  }

  logValidationErrors(group: FormGroup, messages: any, formErrors: any): void {
    Object.keys(group.controls).forEach((key: string) => {
      let abstractControl = group.get(key);
      if (abstractControl instanceof FormGroup) {
        this.logValidationErrors(abstractControl, messages[key], formErrors[key]);
      } else {
        formErrors[key] = '';
        if (abstractControl && abstractControl.invalid && (abstractControl.touched || abstractControl.dirty)) {
          let msg = messages[key];
          for (let errorKey in abstractControl.errors) {
            if (errorKey) {
              formErrors[key] += msg[errorKey] + ' ';
            }
          }
        }
      }
    });
  }

  logKeyValuePairs(group: FormGroup): void {
    Object.keys(group.controls).forEach((key: string) => {
      let abstractControl = group.get(key);
      if (abstractControl instanceof FormGroup) {
        this.logKeyValuePairs(abstractControl);
      } else {
        //abstractControl.disable();
        abstractControl.markAsTouched();
        console.log('key =' + key + ' value =' + abstractControl.value);
      }
    });
  }

  regMaestra(): void {
    console.log(this.maestraGrp);
    if (this.maestraGrp.valid) {
      console.log('VALIDO');
      console.log(this.maestraGrp.value);

      let mae = new Maestra();
      mae.id = 0;
      mae.idMaestraPadre = 0;
      mae.orden = 0;
      mae.nombre = this.maestraGrp.get('nombre').value;
      mae.codigo = this.maestraGrp.get('codigo').value;
      mae.valor = this.maestraGrp.get('valor').value;
      mae.idUsuarioCrea = this.user.getIdUsuario;
      mae.fecUsuarioCrea = new Date();

      console.log(mae);
      this.spinnerService.show();
      this.maestraService.regMaestra(mae).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al registrar');
            this.dialogRef.close(mae);
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
      this.logKeyValuePairs(this.maestraGrp);
      this.validateForm();
    }
  }

  buscar() {
    console.log('Buscar');
  }

}

export interface DataDialog {
  title: string;
  maestra: Maestra;
}
