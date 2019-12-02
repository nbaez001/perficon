import { Component, OnInit, Inject } from '@angular/core';
import { SaldoMensualService } from 'src/app/services/intranet/saldo-mensual.service';
import { SaldoMensual } from 'src/app/model/saldo-mensual.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { UsuarioService } from 'src/app/services/usuario.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  saldoActual: SaldoMensual = new SaldoMensual();
  cargando: boolean = true;

  constructor(
    @Inject(SaldoMensualService) private saldoMensualService: SaldoMensualService,
    @Inject(UsuarioService) private user: UsuarioService) { }

  ngOnInit() {
    this.calcularSaldoMensual();
  }

  calcularSaldoMensual() {
    let fecha = new Date();

    let sm = new SaldoMensual();
    sm.dia = 1;
    sm.anio = fecha.getFullYear();
    sm.mes = fecha.getMonth();
    sm.fecha = fecha;
    sm.idUsuarioCrea = this.user.getIdUsuario;
    sm.fecUsuarioCrea = new Date();
    console.log(sm);

    this.saldoMensualService.calcularSaldoMensual(sm).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          console.log('' + data[0].rmensaje);
          console.log(data[0]);
        } else {
          console.log(data[0]);
        }
        this.obtenerSaldoActual();
      }, error => {
        console.error('Error al modificar egreso');
      }
    );
  }

  obtenerSaldoActual() {
    let fecha = new Date();

    let sm = new SaldoMensual();
    sm.dia = 1;
    sm.anio = fecha.getFullYear();
    sm.mes = fecha.getMonth();
    sm.fecha = fecha;
    console.log(sm);

    this.saldoMensualService.obtenerSaldoActual(sm).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          this.saldoActual = JSON.parse(data[0].result)[0];
          this.cargando = false;
          console.log('Saldo actual');
          console.log(this.saldoActual);
        } else {
          console.log(data[0]);
        }
      }, error => {
        console.error('Error al modificar egreso');
      }
    );
  }

}
