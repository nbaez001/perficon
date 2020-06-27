import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { environment } from 'src/environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CuentaBancoService {

  constructor(private http: HttpClient) { }

  public listarCuentaBanco(): Observable<CuentaBanco[]> {
    return this.http.post<CuentaBanco[]>(`${environment.webServiceEndpoint}cuenta-banco/lista`, {});
  }

  public regCuentaBanco(request: CuentaBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}cuenta-banco/store`, request);
  }

  public editCuentaBanco(request: CuentaBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}cuenta-banco/update`, request);
  }
}
