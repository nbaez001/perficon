import { Component, OnInit, Inject } from '@angular/core';
import { SaldoMensualService } from 'src/app/services/intranet/saldo-mensual.service';
import { SaldoMensual } from 'src/app/model/saldo-mensual.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { UsuarioService } from 'src/app/services/usuario.service';
import { Chart } from 'chart.js';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';
import { PieChartRequest } from 'src/app/model/dto/pie-chart.request';
import { ReportService } from 'src/app/services/intranet/report.service';
import { backgroundColorChart, borderColorChart, tablasMaestra } from 'src/app/common';
import { LineChartRequest } from 'src/app/model/dto/line-chart.request';
import { CommonService } from 'src/app/services/common.service';
import { BarChartRequest } from 'src/app/model/dto/bar-chart.request';
import { Router } from '@angular/router';
import { DatePipe } from '@angular/common';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss']
})
export class HomeComponent implements OnInit {
  saldoActual: SaldoMensual = new SaldoMensual();
  cargando: boolean = true;
  isLoadingLine: boolean = true;
  isLoadingBar: boolean = true;

  LineChart = [];
  BarChart = [];
  PieChart = [];

  result = [];

  meses = [{ 'id': 0, nombre: 'ENERO' }];

  tipoEgresoMayor: any;
  cargandoPieChart: boolean = true;

  constructor(
    @Inject(SaldoMensualService) private saldoMensualService: SaldoMensualService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(ReportService) private reportService: ReportService,
    @Inject(CommonService) private commonService: CommonService,
    private spinnerService: Ng4LoadingSpinnerService,
    private router: Router,
    private datePipe: DatePipe) { }

  ngOnInit() {
    this.spinnerService.show();
    this.calcularSaldoMensual();

    this.cargarPieChart();
    this.cargarLineChart();
    this.cargarBarChart();

    this.spinnerService.hide();
  }

  cargarLineChart() {
    let req = new LineChartRequest();
    req.anio = new Date().getFullYear();
    req.mes = new Date().getMonth();

    this.reportService.lineChartReport(req).subscribe(
      (data: ApiResponse[]) => {
        this.isLoadingLine = false;
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let labels: string[] = [];
          let datas: number[] = [];

          let result = JSON.parse(data[0].result);
          result = result.reverse();
          result.forEach((val, i) => {
            labels.push(this.commonService.obtenerNombreMes(val.label).nombre);
            datas.push(val.data);
          });

          this.LineChart = new Chart('lineChart', {
            type: 'line',
            data: {
              labels: labels,//['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'],
              datasets: [{
                label: 'Gasto promedio por meses',
                data: datas,//[9, 7, 3, 5, 2, 10, 15, 16, 19, 3, 1, 9],
                fill: true,
                lineTension: 0.2,
                borderColor: 'red',
                borderWidth: 1
              }]
            },
            options: {
              title: {
                text: 'Linea de egresos',
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
          console.error('Ocurrio un error al buscar egreso');
        }
      }, error => {
        console.log(error);
        this.isLoadingLine = false;
      }
    );
  }

  cargarPieChart() {
    let req = new PieChartRequest();
    req.anio = new Date().getFullYear();
    req.idTabla = 1;//MAESTRA TIPO EGRESO

    this.reportService.pieChartReport(req).subscribe(
      (data: ApiResponse[]) => {
        this.cargandoPieChart = false;
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let backColors: string[] = [];
          let borderColors: string[] = [];
          let labels: string[] = [];
          let datas: number[] = [];

          let result = JSON.parse(data[0].result);
          result.forEach(function (val, i) {
            backColors.push(backgroundColorChart[i]);
            borderColors.push(borderColorChart[i]);
            labels.push(val.label);
            datas.push(val.data);
          });
          this.filtrarTipoEgresoMayor(result);

          this.PieChart = new Chart('pieChart', {
            type: 'pie',
            data: {
              labels: labels,
              datasets: [{
                label: 'Gasto por dia',
                data: datas,
                backgroundColor: backColors,
                borderColor: borderColors,
                borderWidth: 1
              }]
            },
            options: {
              title: {
                text: 'Grafico de egresos',
                display: true
              },
              legend: {
                display: false
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
        this.cargandoPieChart = false;
      }
    );
  }

  cargarBarChart() {
    let fec = new Date();
    let req = new BarChartRequest();
    req.anio = fec.getFullYear();
    req.mes = fec.getMonth();
    req.dia = fec.getDate();
    req.cantDias = this.commonService.cantDiasMes(fec);
    req.cantDiasPrev = this.commonService.cantDiasMesPrev(fec);

    this.reportService.barChartReport(req).subscribe(
      (data: ApiResponse[]) => {
        this.isLoadingBar = false;
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          let backColors: string[] = [];
          let borderColors: string[] = [];
          let labels: string[] = [];
          let datas: number[] = [];

          this.result = JSON.parse(data[0].result);
          let calc = 0;
          this.result = this.result.reverse();
          this.result.forEach(function (val, i) {
            calc = i - (Math.floor(i / backgroundColorChart.length) * backgroundColorChart.length);
            backColors.push(backgroundColorChart[calc]);
            borderColors.push(borderColorChart[calc]);
            labels.push(val.label);
            datas.push(val.data);
          });

          this.BarChart = new Chart('barChart', {
            type: 'bar',
            data: {
              labels: labels,
              datasets: [{
                label: 'Gasto por dia',
                data: datas,
                backgroundColor: backColors,
                borderColor: borderColors,
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
              },
              onClick: (c, i) => {
                // let e = i[0];
                // var x_value = this.data.labels[e._index];
                // var y_value = this.data.datasets[0].data[e._index];
                // console.log(e._index)
                // console.log(x_value);
                // console.log(y_value);
                this.verDetalleEgresos(c, i);
              }
            }
          });
        } else {
          console.error('Ocurrio un error al registrar egreso');
        }
      }, error => {
        console.log(error);
        this.isLoadingBar = false;
      }
    );
  }

  verDetalleEgresos(evt: any, i: any): void {
    if (evt.type == 'click') {
      console.log('Mouse Click');
      console.log(evt);
      console.log(evt.detail);
      if (evt.detail > 1) {
        sessionStorage.setItem('restDias', (30 - i[0]._index).toString());
        this.router.navigate(['intranet/bandeja-egresos']);
      }
    } else {
      console.log('Touch');
    }
  }

  calcularSaldoMensual() {//CALCULA EL MONTO DEL MES
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

  filtrarTipoEgresoMayor(lista): void {
    this.tipoEgresoMayor = lista.reduce(function (prev, current) {
      return (prev.data > current.data) ? prev : current
    })
  }



}
