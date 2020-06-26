import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiResponse } from 'src/app/model/api-response.model';
import { Ingreso } from 'src/app/model/ingreso.model';
import { IngresoRequest } from 'src/app/model/dto/ingreso.request';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class IngresoService {
  constructor(private http: HttpClient) {
  }

  public listarIngreso(request: IngresoRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}ingreso/lista`, request);
  }

  public regIngreso(request: Ingreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}ingreso/store`, request);
  }

  public editIngreso(request: Ingreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}ingreso/update`, request);
  }

  public listarEgresosRetorno(request: any): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}ingreso/lista-egresos-retorno`, request);
  }
}
