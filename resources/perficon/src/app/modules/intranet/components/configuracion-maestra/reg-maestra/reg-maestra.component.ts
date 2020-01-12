import { Component, OnInit, ViewChild, Inject } from '@angular/core';
import { Maestra } from 'src/app/model/maestra.model';
import { MatTableDataSource, MatPaginator, MatSort, MatDialog, MAT_DIALOG_DATA, MatDialogRef } from '@angular/material';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { MaestraService } from 'src/app/services/intranet/maestra.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { ApiResponse } from 'src/app/model/api-response.model';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ValidationService } from 'src/app/services/validation.service';

@Component({
  selector: 'app-reg-maestra',
  templateUrl: './reg-maestra.component.html',
  styleUrls: ['./reg-maestra.component.scss']
})
export class RegMaestraComponent implements OnInit {
  maestraGrp: FormGroup;
  maestraEdit: Maestra;
  messages = {
    'nombre': {
      'required': 'Campo obligatorio'
    },
    'codigo': {
      'required': 'Campo obligatorio'
    },
    'valor': {
      'required': 'Campo obligatorio'
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
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.maestraGrp = this.fb.group({
      nombre: ['', [Validators.required]],
      codigo: ['', [Validators.required]],
      valor: ['', []]
    });

    this.maestraGrp.valueChanges.subscribe((val: any) => {
      console.log(JSON.stringify(val));
      this.validationService.getValidationErrors(this.maestraGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    if (this.data.objeto) {
      this.maestraEdit = JSON.parse(JSON.stringify(this.data.objeto));
      this.maestraGrp.get('nombre').setValue(this.maestraEdit.nombre);
      this.maestraGrp.get('codigo').setValue(this.maestraEdit.codigo);
      this.maestraGrp.get('valor').setValue(this.maestraEdit.valor);
    }
  }

  regMaestra(): void {
    if (this.maestraGrp.valid) {
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
      this.validationService.getValidationErrors(this.maestraGrp, this.messages, this.formErrors, true);
    }
  }

  editMaestra(): void {
    if (this.maestraGrp.valid) {
      let obj: Maestra = JSON.parse(JSON.stringify(this.data.objeto));
      obj.nombre = this.maestraGrp.get('nombre').value;
      obj.codigo = this.maestraGrp.get('codigo').value;
      obj.valor = this.maestraGrp.get('valor').value;
      obj.idUsuarioMod = this.user.getIdUsuario;
      obj.fecUsuarioMod = new Date();

      this.spinnerService.show();
      this.maestraService.editMaestra(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al modificar');
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al modificar maestra');
          }
        }, error => {
          console.error('Error al modificar maestra');
        }
      );
    } else {
      this.validationService.getValidationErrors(this.maestraGrp, this.messages, this.formErrors, true);
    }
  }

}