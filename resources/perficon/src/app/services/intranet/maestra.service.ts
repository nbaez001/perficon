import { Injectable } from '@angular/core';
import { HttpHeaders, HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { webServiceEndpoint } from 'src/app/common';
import { Maestra } from 'src/app/model/maestra.model';

@Injectable({
    providedIn: 'root'
})
export class MaestraService {
    constructor(private http: HttpClient) {
    }

    public listarMaestra(request: Maestra): Observable<Maestra[]> {
        return this.http.post<Maestra[]>(`${webServiceEndpoint}maestra/lista`, request);
    }

}
