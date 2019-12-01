import { Component, OnInit, Inject } from '@angular/core';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { MovimientoBanco } from 'src/app/model/movimiento-banco.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { DatePipe } from '@angular/common';
import { ValidationService } from 'src/app/services/validation.service';
import { CuentaBancoService } from 'src/app/services/intranet/cuenta-banco.service';
import { MovimientoBancoService } from 'src/app/services/intranet/movimiento-banco.service';
import { UsuarioService } from 'src/app/services/usuario.service';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { Maestra } from 'src/app/model/maestra.model';
import { MaestraService } from 'src/app/services/intranet/maestra.service';

@Component({
  selector: 'app-reg-mov-banco',
  templateUrl: './reg-mov-banco.component.html',
  styleUrls: ['./reg-mov-banco.component.scss']
})
export class RegMovBancoComponent implements OnInit {
  listaCuentasbanco: CuentaBanco[] = [];
  tiposMovimiento: Maestra[];
  movimientoBancoEdit: MovimientoBanco;

  formularioGrp: FormGroup;
  messages = {
    'nomCuentaBanco': {
      'required': 'Field is required'
    },
    'detalle': {
      'required': 'Field is required'
    },
    'monto': {
      'required': 'Field is required'
    },
    'fecha': {
      'required': 'Field is required'
    },
    'tipoMovimiento': {
      'required': 'Field is required'
    }
  };
  formErrors = {
    'nomCuentaBanco': '',
    'detalle': '',
    'monto': '',
    'fecha': '',
    'tipoMovimiento': ''
  };

  constructor(private fb: FormBuilder,
    public dialogRef: MatDialogRef<RegMovBancoComponent>,
    private spinnerService: Ng4LoadingSpinnerService,
    private datePipe: DatePipe,
    @Inject(ValidationService) private validationService: ValidationService,
    @Inject(CuentaBancoService) private cuentaBancoService: CuentaBancoService,
    @Inject(MovimientoBancoService) private movimientoBancoService: MovimientoBancoService,
    @Inject(MaestraService) private mestraService: MaestraService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog) { }

  ngOnInit() {
    this.formularioGrp = this.fb.group({
      cuentaBanco: ['', [Validators.required]],
      detalle: ['', [Validators.required]],
      monto: ['', [Validators.required]],
      fecha: ['', [Validators.required]],
      tipoMovimiento: ['', [Validators.required]],
    });

    this.formularioGrp.valueChanges.subscribe((val: any) => {
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, false);
    });

    this.inicializarVariables();
  }

  public inicializarVariables(): void {
    this.comboCuentaBanco();
    this.comboTiposMovimiento();
    if (this.data.objeto) {
      this.movimientoBancoEdit = JSON.parse(JSON.stringify(this.data.objeto));
      this.formularioGrp.get('detalle').setValue(this.movimientoBancoEdit.detalle);
      this.formularioGrp.get('monto').setValue(this.movimientoBancoEdit.monto);
      this.formularioGrp.get('fecha').setValue(new Date(this.datePipe.transform(this.movimientoBancoEdit.fecha, 'MM/dd/yyyy')));
    } else {
      this.formularioGrp.get('fecha').setValue(new Date());
    }
  }

  comboCuentaBanco(): void {
    this.cuentaBancoService.listarCuentaBanco().subscribe(
      (data: CuentaBanco[]) => {
        this.listaCuentasbanco = data;

        if (this.data.objeto) {
          this.formularioGrp.get('cuentaBanco').setValue((this.listaCuentasbanco.filter(el => el.id == this.movimientoBancoEdit.idCuentaBanco))[0]);
        } else {
          this.formularioGrp.get('cuentaBanco').setValue(this.listaCuentasbanco[0]);
        }
      }, error => {
        console.log(error);
      }
    );
  }

  comboTiposMovimiento(): void {
    let m = new Maestra();
    m.idMaestraPadre = 24;
    this.mestraService.listarMaestra(m).subscribe(
      (data: Maestra[]) => {
        this.tiposMovimiento = data;
        this.formularioGrp.get('tipoMovimiento').setValue(this.tiposMovimiento[1]);
      }, error => {
        console.log(error);
      }
    );
  }

  regMovimientoBanco(): void {
    if (this.formularioGrp.valid) {
      let obj = new MovimientoBanco();
      obj.id = 0;
      obj.idCuentaBanco = this.formularioGrp.get('cuentaBanco').value.id;
      obj.nomCuentaBanco = this.formularioGrp.get('cuentaBanco').value.nombre;
      obj.idTipoMovimiento = this.formularioGrp.get('tipoMovimiento').value.id;
      obj.nomTipoMovimiento = this.formularioGrp.get('tipoMovimiento').value.nombre;
      obj.valTipoMovimiento = this.formularioGrp.get('tipoMovimiento').value.valor;
      obj.detalle = this.formularioGrp.get('detalle').value;
      obj.monto = this.formularioGrp.get('monto').value;
      obj.fecha = this.formularioGrp.get('fecha').value;
      obj.idUsuarioCrea = this.user.getIdUsuario;
      obj.fecUsuarioCrea = new Date();

      console.log(obj)

      this.spinnerService.show();
      this.movimientoBancoService.regMovimientoBanco(obj).subscribe(
        (data: ApiResponse[]) => {
          if (typeof data[0] != undefined && data[0].rcodigo == 0) {
            console.log('Exito al registrar');
            obj.id = data[0].rid;
            this.dialogRef.close(obj);
            this.spinnerService.hide();
          } else {
            console.error('Ocurrio un error al registrar movimiento');
          }
        }, error => {
          console.error('Error al registrar movimiento');
        }
      );
    } else {
      this.validationService.getValidationErrors(this.formularioGrp, this.messages, this.formErrors, true);
    }
  }

}
