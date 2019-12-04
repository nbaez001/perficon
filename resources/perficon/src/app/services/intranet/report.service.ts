import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { PieChartRequest } from 'src/app/model/dto/pie-chart.request';
import { Observable } from 'rxjs';
import { webServiceEndpoint } from 'src/app/common';
import { ApiResponse } from 'src/app/model/api-response.model';

@Injectable({
  providedIn: 'root'
})
export class ReportService {

  constructor(private http: HttpClient) { }

  public pieChartReport(request: PieChartRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}reporte/pie-chart-report`, request);
  }
}
