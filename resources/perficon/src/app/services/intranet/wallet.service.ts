import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ApiOutResponse } from 'src/app/model/dto/api-out.response';
import { WalletResponse } from 'src/app/dto/response/wallet.response';
import { environment } from 'src/environments/environment';
import { BuscarWalletRequest } from 'src/app/dto/request/buscar-wallet.request';

@Injectable({
  providedIn: 'root'
})
export class WalletService {

  constructor(private http: HttpClient) { }

  public listarWallet(req: BuscarWalletRequest): Observable<ApiOutResponse<WalletResponse[]>> {
    return this.http.post<ApiOutResponse<WalletResponse[]>>(`${environment.webServiceEndpoint}wallet/listar-wallet`, req);
  }
}
