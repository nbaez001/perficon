import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { MovimientoBanco } from 'src/app/model/movimiento-banco.model';
import { Observable } from 'rxjs';
import { ApiResponse } from 'src/app/model/api-response.model';
import { MovimientoBancoRequest } from 'src/app/model/dto/movimiento-banco.request';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class MovimientoBancoService {

  constructor(private http: HttpClient) { }

  public listarMovimientoBanco(request: MovimientoBancoRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}movimiento-banco/lista`, request);
  }

  public regMovimientoBanco(request: MovimientoBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}movimiento-banco/store`, request);
  }

  public delMovimientoBanco(request: MovimientoBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}movimiento-banco/delete`, request);
  }
}
