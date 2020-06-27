import { Injectable } from '@angular/core';
import { Egreso } from 'src/app/model/egreso.model';
import { Observable } from 'rxjs';
import { ApiResponse } from 'src/app/model/api-response.model';
import { HttpClient } from '@angular/common/http';
import { EgresoRequest } from 'src/app/model/dto/egreso.request';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class EgresoService {
  constructor(private http: HttpClient) {
  }

  public listarEgreso(request: EgresoRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}egreso/lista`, request);
  }

  public regEgreso(request: Egreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}egreso/store`, request);
  }

  public editEgreso(request: Egreso): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}egreso/update`, request);
  }
}
