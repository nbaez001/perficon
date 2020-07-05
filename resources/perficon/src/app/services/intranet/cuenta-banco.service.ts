import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { CuentaBanco } from 'src/app/model/cuenta-banco.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { environment } from 'src/environments/environment';
import { ApiOutResponse } from 'src/app/model/dto/api-out.response';
import { CuentaBancoResponse } from 'src/app/dto/response/cuenta-banco.response';
import { BuscarCuentaBancoRequest } from 'src/app/dto/request/buscar-cuenta-banco.request';

@Injectable({
  providedIn: 'root'
})
export class CuentaBancoService {

  constructor(private http: HttpClient) { }

  public listarCuentaBanco(req: BuscarCuentaBancoRequest): Observable<ApiOutResponse<CuentaBancoResponse[]>> {
    return this.http.post<ApiOutResponse<CuentaBancoResponse[]>>(`${environment.webServiceEndpoint}cuenta-banco/lista`, req);
  }

  public regCuentaBanco(request: CuentaBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}cuenta-banco/store`, request);
  }

  public editCuentaBanco(request: CuentaBanco): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}cuenta-banco/update`, request);
  }
}
