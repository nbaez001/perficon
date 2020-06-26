import { Injectable } from '@angular/core';
import { SaldoMensual } from 'src/app/model/saldo-mensual.model';
import { Observable } from 'rxjs';
import { HttpClient } from '@angular/common/http';
import { ApiResponse } from 'src/app/model/api-response.model';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class SaldoMensualService {

  constructor(private http: HttpClient) { }

  public getSaldoMensual(request: SaldoMensual): Observable<SaldoMensual[]> {
    return this.http.post<SaldoMensual[]>(`${environment.webServiceEndpoint}saldo-mensual/obtener`, request);
  }

  public calcularSaldoMensual(request: SaldoMensual): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}saldo-mensual/calcular`, request);
  }

  public obtenerSaldoActual(request: SaldoMensual): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}saldo-mensual/obtener-actual`, request);
  }
}
