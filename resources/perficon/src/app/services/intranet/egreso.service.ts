import { Injectable } from '@angular/core';
import { Egreso } from 'src/app/model/egreso.model';
import { Observable } from 'rxjs';
import { webServiceEndpoint } from 'src/app/common';
import { ApiResponse } from 'src/app/model/api-response.model';
import { HttpClient } from '@angular/common/http';
import { EgresoRequest } from 'src/app/model/dto/egreso.request';

@Injectable({
  providedIn: 'root'
})
export class EgresoService {
  constructor(private http: HttpClient) {
  }

  public listarEgreso(request: EgresoRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}egreso/lista`, request);
  }

  public regEgreso(request: Egreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}egreso/store`, request);
  }

  public editEgreso(request: Egreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}egreso/update`, request);
  }
}
