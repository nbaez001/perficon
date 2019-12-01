import { Component, OnInit, Inject } from '@angular/core';
import { SaldoMensualService } from 'src/app/services/intranet/saldo-mensual.service';
import { SaldoMensual } from 'src/app/model/saldo-mensual.model';
import { ApiResponse } from 'src/app/model/api-response.model';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {

  constructor(
    @Inject(SaldoMensualService) private saldoMensualService: SaldoMensualService) { }

  ngOnInit() {
  }

  calcularSaldoMensual() {
    let sm = new SaldoMensual();
    

    this.saldoMensualService.calcularSaldoMensual(sm).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          console.log('' + data[0].rmensaje);
          console.log(data[0]);
        } else {
          console.error('Ocurrio un error al modificar egreso');
        }
      }, error => {
        console.error('Error al modificar egreso');
      }
    );
  }

}
