import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { PieChartRequest } from 'src/app/model/dto/pie-chart.request';
import { Observable } from 'rxjs';
import { webServiceEndpoint } from 'src/app/common';
import { ApiResponse } from 'src/app/model/api-response.model';
import { LineChartRequest } from 'src/app/model/dto/line-chart.request';
import { BarChartRequest } from 'src/app/model/dto/bar-chart.request';

@Injectable({
  providedIn: 'root'
})
export class ReportService {

  constructor(private http: HttpClient) { }

  public pieChartReport(request: PieChartRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}dashboard/pie-chart`, request);
  }

  public lineChartReport(request: LineChartRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}dashboard/line-chart`, request);
  }

  public barChartReport(request: BarChartRequest): Observable<ApiResponse[]> {
    return this.http.post<ApiResponse[]>(`${webServiceEndpoint}dashboard/bar-chart`, request);
  }
}
