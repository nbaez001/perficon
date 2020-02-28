import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class CommonService {
  meses = [{ id: 0, nombre: 'ENERO' }, { id: 1, nombre: 'FEBRERO' }, { id: 2, nombre: 'MARZO' }, { id: 3, nombre: 'ABRIL' }, { id: 4, nombre: 'MAYO' }, { id: 5, nombre: 'JUNIO' }, { id: 6, nombre: 'JULIO' }, { id: 7, nombre: 'AGOSTO' }, { id: 8, nombre: 'SETIEMBRE' }, { id: 9, nombre: 'OCTUBRE' }, { id: 10, nombre: 'NOVIEMBRE' }, { id: 11, nombre: 'DICIEMBRE' }];

  constructor() { }

  obtenerNombreMes(id: number): any {
    return this.meses.filter(el => el.id == id)[0];
  }

  cantDiasMes(fecha: Date) {
    return new Date(fecha.getFullYear(), fecha.getMonth() + 1, 0).getDate();
  }

  cantDiasMesPrev(fecha: Date) {
    let mes = 0;
    let anio = 0;
    if ((fecha.getMonth() + 1) == 1) {//SI ES MES ENERO
      mes = 12;
      anio = fecha.getFullYear() - 1;
    } else {
      mes = fecha.getMonth() + 1 - 1;
      anio = fecha.getFullYear();
    }
    return new Date(anio, mes, 0).getDate();
  }

  calcularDiferenciaDias(fecInicio: Date, fecFin: Date): number {
    console.log(fecFin);
    console.log(fecInicio);
    return Math.round((fecFin.getTime() - fecInicio.getTime()) / (1000 * 60 * 60 * 24));
  }
}
