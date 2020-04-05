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
import { ApiOutResponse } from 'src/app/model/dto/api-out.response';

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
  LineChart2 = [];
  LineChart3 = [];

  BarChart = [];
  BarChart2 = [];
  BarChart3 = [];

  PieChart = [];

  result = [];

  sumaCategoria = [];

  meses = [{ 'id': 0, nombre: 'ENERO' }];

  tipoEgresoMayor: any = {};
  cargandoPieChart: boolean = true;

  cuarto: any = {};
  alimentacion: any = {};

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
              },
              responsive: true,
              maintainAspectRatio: false
            }
          });

          let egresosOrdenados = result.sort((a, b) => (a.data < b.data) ? 1 : -1);
          this.getSumaMesCategoria(egresosOrdenados);
        } else {
          console.error('Ocurrio un error al registrar egreso');
        }
      }, error => {
        console.log(error);
        this.cargandoPieChart = false;
      }
    );
  }

  cargarLineChart() {
    let req = new LineChartRequest();
    req.anio = new Date().getFullYear();
    req.mes = new Date().getMonth();

    this.reportService.lineChartReport(req).subscribe(
      (data: ApiOutResponse) => {
        this.isLoadingLine = false;
        if (data.rCodigo == 0) {
          let labels: string[] = [];
          let datas: number[] = [];
          let datas2: number[] = [];

          let result = data.result;
          result = result.reverse();
          result.forEach((val, i) => {
            labels.push(this.commonService.obtenerNombreMes(val.label).nombre);
            datas.push(val.data);
            datas2.push(val.dataIng + val.dataIngMov);
          });

          this.LineChart = new Chart('lineChart', {
            type: 'line',
            data: {
              labels: labels,//['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'],
              datasets: [{
                label: 'Gasto mensual',
                data: datas,//[9, 7, 3, 5, 2, 10, 15, 16, 19, 3, 1, 9],
                fill: true,
                lineTension: 0.2,
                borderColor: 'red',
                borderWidth: 1
              }, {
                label: 'Ingreso mensual',
                data: datas2,//[9, 7, 3, 5, 2, 10, 15, 16, 19, 3, 1, 9],
                fill: true,
                lineTension: 0.2,
                borderColor: 'blue',
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
              },
              responsive: true,
              maintainAspectRatio: false
            }
          });
          this.LineChart2 = new Chart('lineChart2', {
            type: 'line',
            data: {
              labels: labels.slice(labels.length / 2, labels.length),//['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'],
              datasets: [{
                label: 'Gasto mensual',
                data: datas.slice(labels.length / 2, labels.length),
                fill: true,
                lineTension: 0.2,
                borderColor: 'red',
                borderWidth: 1
              }, {
                label: 'Ingreso mensual',
                data: datas2.slice(labels.length / 2, labels.length),
                fill: true,
                lineTension: 0.2,
                borderColor: 'blue',
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
              },
              responsive: true,
              maintainAspectRatio: false
            }
          });
          this.LineChart3 = new Chart('lineChart3', {
            type: 'line',
            data: {
              labels: labels.slice(labels.length * (2 / 3), labels.length),
              datasets: [{
                label: 'Gasto mensual',
                data: datas.slice(labels.length * (2 / 3), labels.length),
                fill: true,
                lineTension: 0.2,
                borderColor: 'red',
                borderWidth: 1
              }, {
                label: 'Ingreso mensual',
                data: datas2.slice(labels.length * (2 / 3), labels.length),
                fill: true,
                lineTension: 0.2,
                borderColor: 'blue',
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
              },
              responsive: true,
              maintainAspectRatio: false
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

          let cantBarChart = labels.length;
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
              responsive: true,
              maintainAspectRatio: false,
              onClick: (c, i) => {
                // let e = i[0];
                // var x_value = this.data.labels[e._index];
                // var y_value = this.data.datasets[0].data[e._index];
                // console.log(e._index)
                // console.log(x_value);
                // console.log(y_value);
                this.verDetalleEgresos(c, i, cantBarChart);
              }
            }
          });

          let cantBarChart2 = labels.length - parseInt((labels.length / 2).toFixed(1));
          this.BarChart2 = new Chart('barChart2', {
            type: 'bar',
            data: {
              labels: labels.slice(parseInt((labels.length / 2).toFixed(1)), labels.length),
              datasets: [{
                label: 'Gasto por dia',
                data: datas.slice(parseInt((labels.length / 2).toFixed(1)), labels.length),
                backgroundColor: backColors.slice(parseInt((labels.length / 2).toFixed(1)), labels.length),
                borderColor: borderColors.slice(parseInt((labels.length / 2).toFixed(1)), labels.length),
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
              responsive: true,
              maintainAspectRatio: false,
              onClick: (c, i) => {
                // let e = i[0];
                // var x_value = this.data.labels[e._index];
                // var y_value = this.data.datasets[0].data[e._index];
                // console.log(e._index)
                // console.log(x_value);
                // console.log(y_value);
                this.verDetalleEgresos(c, i, cantBarChart2);
              }
            }
          });

          let cantBarChart3 = labels.length - parseInt((labels.length * (3 / 4)).toFixed(1));
          this.BarChart3 = new Chart('barChart3', {
            type: 'bar',
            data: {
              labels: labels.slice(parseInt((labels.length * (3 / 4)).toFixed(1)), labels.length),
              datasets: [{
                label: 'Gasto por dia',
                data: datas.slice(parseInt((labels.length * (3 / 4)).toFixed(1)), labels.length),
                backgroundColor: backColors.slice(parseInt((labels.length * (3 / 4)).toFixed(1)), labels.length),
                borderColor: borderColors.slice(parseInt((labels.length * (3 / 4)).toFixed(1)), labels.length),
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
              responsive: true,
              maintainAspectRatio: false,
              onClick: (c, i) => {
                // let e = i[0];
                // var x_value = this.data.labels[e._index];
                // var y_value = this.data.datasets[0].data[e._index];
                // console.log(e._index)
                // console.log(x_value);
                // console.log(y_value);
                this.verDetalleEgresos(c, i, cantBarChart3);
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

  verDetalleEgresos(evt: any, i: any, cant: number): void {
    if (evt.type == 'click') {
      if (evt.detail > 1) {
        sessionStorage.setItem('restDias', (cant - (i[0]._index + 1)).toString());
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

    this.saldoMensualService.calcularSaldoMensual(sm).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          console.log('' + data[0].rmensaje);
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

    this.saldoMensualService.obtenerSaldoActual(sm).subscribe(
      (data: ApiResponse[]) => {
        if (typeof data[0] != undefined && data[0].rcodigo == 0) {
          this.saldoActual = JSON.parse(data[0].result)[0];
          this.cargando = false;
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

  getSumaMesCategoria(lista: any[]) {
    let cantDias = this.daysIntoYear(new Date());
    let sumaTotal = 0;
    let sumaOtros = 0;

    //PREPARACION DE LOS 5 MAXIMOS EGRESOS
    let filterArray: string[] = [];
    for (let i = 0; i < 4; i++) {
      filterArray.push(lista[i].label);
    }

    //SUMA LOS VALORES QUE NO ESTAN EL EL ARRAY DE MAXIMOS EGRESOS
    lista.forEach(el => {
      if (!filterArray.find(x => x == el.label)) {
        sumaOtros += el.data;
      }
      sumaTotal += el.data;
    });

    this.sumaCategoria = lista.filter(({ label }) => filterArray.includes(label));
    this.sumaCategoria.unshift({ label: 'PROMEDIO DIA', data: sumaTotal })
    this.sumaCategoria.push({ label: 'OTROS', data: sumaOtros })

    this.sumaCategoria.forEach(el => {
      el.mostrar = true;
      el.label == 'CUARTO' ? el.promedio = el.data / (30 * el.cantidad) : el.promedio = el.data / cantDias;
      el.label == 'PROMEDIO DIA' ? el.deshabilitado = true : el.deshabilitado = false;
    });
    this.realizarCalculo();
  }

  realizarCalculo(): void {
    this.sumaCategoria[0].promedio = 0.0;
    this.sumaCategoria[0].data = 0.0;
    this.sumaCategoria.forEach(el => {
      if (el.mostrar && !el.deshabilitado) {
        this.sumaCategoria[0].promedio += el.promedio;
        this.sumaCategoria[0].data += el.data;
      }
    });
  }

  daysIntoYear(date) {
    return (Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) - Date.UTC(date.getFullYear(), 0, 0)) / 24 / 60 / 60 / 1000;
  }

  // getSumaMesCategoria(lista: any[]) {
  //   let req = new PieChartRequest();
  //   req.anio = new Date().getFullYear();
  //   req.mes = new Date().getMonth() + 1;
  //   req.idTabla = 1;//MAESTRA TIPO EGRESO

  //   let cantDias = new Date().getDate();

  //   this.reportService.getSumaMesCategoria(req).subscribe(
  //     (data: ApiResponse[]) => {
  //       this.cargandoPieChart = false;
  //       if (typeof data[0] != undefined && data[0].rcodigo == 0) {

  //         let result = JSON.parse(data[0].result);
  //         let sumaTotal = 0;
  //         let sumaOtros = 0;

  //         //PREPARACION DE LOS 5 MAXIMOS EGRESOS
  //         let filterArray: string[] = [];
  //         for (let i = 0; i < 4; i++) {
  //           filterArray.push(lista[i].label);
  //         }

  //         //SUMA LOS VALORES QUE NO ESTAN EL EL ARRAY DE MAXIMOS EGRESOS
  //         result.forEach(el => {
  //           if (!filterArray.find(x => x == el.label)) {
  //             sumaOtros += el.data;
  //           }
  //           sumaTotal += el.data;
  //         });

  //         this.sumaCategoria = result.filter(({ label }) => filterArray.includes(label));
  //         this.sumaCategoria.unshift({ label: 'PROMEDIO DIA', data: sumaTotal })
  //         this.sumaCategoria.push({ label: 'OTROS', data: sumaOtros })

  //         this.sumaCategoria.forEach(el => {
  //           el.label == 'CUARTO' ? el.promedio = el.data / 30 : el.promedio = el.data / cantDias;
  //         });
  //       } else {
  //         console.log('Ocurrio un error al registrar egreso');
  //       }
  //     }, error => {
  //       console.log(error);
  //     }
  //   );
  // }

}
