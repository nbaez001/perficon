import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MovimientoBanco } from 'src/app/model/movimiento-banco.model';
import { Observable } from 'rxjs';
import { webServiceEndpoint } from 'src/app/common';
import { ApiResponse } from 'src/app/model/api-response.model';

@Injectable({
  providedIn: 'root'
})
export class MovimientoBancoService {

  constructor(private http: HttpClient) { }

  public listarMovimientoBanco(): Observable<MovimientoBanco[]> {
    return this.http.post<MovimientoBanco[]>(`${webServiceEndpoint}movimiento-banco/lista`, {});
  }

  public regMovimientoBanco(request: MovimientoBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}movimiento-banco/store`, request);
  }

  public delMovimientoBanco(request: MovimientoBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}movimiento-banco/delete`, request);
  }
}
