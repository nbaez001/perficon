import { Injectable } from '@angular/core';
import { HttpHeaders, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Maestra } from 'src/app/model/maestra.model';
import { ApiResponse } from 'src/app/model/api-response.model';
import { environment } from 'src/environments/environment';

@Injectable({
    providedIn: 'root'
})
export class MaestraService {
    constructor(private http: HttpClient) {
    }

    public listarMaestra(request: Maestra): Observable<Maestra[]> {
        return this.http.post<Maestra[]>(`${environment.webServiceEndpoint}maestra/lista`, request);
    }

    public regMaestra(request: Maestra): Observable<ApiResponse[]> {
        return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}maestra/store`, request);
    }

    public editMaestra(request: Maestra): Observable<ApiResponse[]> {
        return this.http.post<ApiResponse[]>(`${environment.webServiceEndpoint}maestra/update`, request);
    }

}
