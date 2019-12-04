import { Component, OnInit, Inject } from '@angular/core';
import { SaldoMensualService } from 'src/app/services/intranet/saldo-mensual.service';
import { SaldoMensual } from 'src/app/model/saldo-mensual.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { UsuarioService } from 'src/app/services/usuario.service';
import { Chart } from 'chart.js';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { PieChartRequest } from 'src/app/model/dto/pie-chart.request';
import { ReportService } from 'src/app/services/intranet/report.service';
import { backgroundColorChart, borderColorChart } from 'src/app/common';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  saldoActual: SaldoMensual = new SaldoMensual();
  cargando: boolean = true;
  LineChart = [];
  BarChart = [];
  PieChart = [];

  constructor(
    @Inject(SaldoMensualService) private saldoMensualService: SaldoMensualService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(ReportService) private reportService: ReportService,
    private spinnerService: Ng4LoadingSpinnerService) { }

  ngOnInit() {
    this.spinnerService.show();
    this.calcularSaldoMensual();

    this.cargarPieChart();

    this.LineChart = new Chart('lineChart', {
      type: 'line',
      data: {
        labels: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'],
        datasets: [{
          label: 'Gasto promedio por meses',
          data: [9, 7, 3, 5, 2, 10, 15, 16, 19, 3, 1, 9],
          fill: true,
          lineTension: 0.2,
          borderColor: 'red',
          borderWidth: 1
        }]
      },
      options: {
        title: {
          text: 'Grafico de egresos',
          display: true
        },
        scales: {
          yAxes: [{
            ticks: {
              beginAtZero: true
            }
          }]
        }
      }
    });

    this.BarChart = new Chart('barChart', {
      type: 'bar',
      data: {
        labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
        datasets: [{
          label: 'Gasto por dia',
          data: [9, 7, 3, 5, 2, 10],
          backgroundColor: [
            'rgba(255,99,132,0.2)',
            'rgba(54,162,235,0.2)',
            'rgba(255,206,86,0.2)',
            'rgba(75,192,192,0.2)',
            'rgba(153,102,255,0.2)',
            'rgba(255,159,64,0.2)',
          ],
          borderColor: [
            'rgba(255,99,132,1)',
            'rgba(54,162,235,1)',
            'rgba(255,206,86,1)',
            'rgba(75,192,192,1)',
            'rgba(153,102,255,1)',
            'rgba(255,159,64,1)',
          ],
          borderWidth: 1
        }]
      },
      options: {
        title: {
          text: 'Grafico de egresos',
          display: true
        },
        scales: {
          yAxes: [{
            ticks: {
              beginAtZero: true
            }
          }]
        }
      }
    });

    this.spinnerService.hide();
  }

  cargarPieChart() {
    let req = new PieChartRequest();
    req.anio = new Date().getFullYear();

    this.reportService.pieChartReport(req).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let backColors: string[] = [];
          let borderColors: string[] = [];

          let result = JSON.parse(data[0].result)[0];
          result.labels.forEach(function (val, i) {
            backColors.push(backgroundColorChart[i]);
            borderColors.push(borderColorChart[i]);
          });

          this.PieChart = new Chart('pieChart', {
            type: 'pie',
            data: {
              labels: result.labels,
              datasets: [{
                label: 'Gasto por dia',
                data: result.data,
                backgroundColor: result.backgroundColors,
                borderColor: result.borderColors,
                borderWidth: 1
              }]
            },
            options: {
              title: {
                text: 'Grafico de egresos',
                display: true
              },
              scales: {
                yAxes: [{
                  ticks: {
                    beginAtZero: true
                  }
                }]
              }
            }
          });

        } else {
          console.error('Ocurrio un error al registrar egreso');
        }
      }, error => {
        console.log(error);
      }
    );
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
