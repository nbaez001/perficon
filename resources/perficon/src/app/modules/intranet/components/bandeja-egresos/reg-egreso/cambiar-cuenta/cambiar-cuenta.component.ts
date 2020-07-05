import { Component, OnInit, Inject } from '@angular/core';
import { MatDialogRef, MAT_DIALOG_DATA } from '@angular/material';
import { DataDialog } from 'src/app/model/data-dialog.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';

@Component({
  selector: 'app-cambiar-cuenta',
  templateUrl: './cambiar-cuenta.component.html',
  styleUrls: ['./cambiar-cuenta.component.scss']
})
export class CambiarCuentaComponent implements OnInit {

  formularioGrp: FormGroup;

  constructor(private dialogRef: MatDialogRef<CambiarCuentaComponent>,
    @Inject(MAT_DIALOG_DATA) public data: DataDialog,
    private fb: FormBuilder) { }

  ngOnInit() {
    this.formularioGrp = this.fb.group({
      cuenta: [this.data.objeto[0], [Validators.required]]
    });
  }

  guardar(): void {
    let obj = this.formularioGrp.get('cuenta').value;
    let index = this.data.objeto.indexOf(obj);
    this.data.objeto.splice(index, 1);
    this.data.objeto.unshift(obj);

    this.dialogRef.close(this.data.objeto);
  }
}
