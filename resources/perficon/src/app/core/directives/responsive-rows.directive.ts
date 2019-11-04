import { Directive, Input, OnInit } from '@angular/core';
import { MatGridTile } from '@angular/material';
import { MediaObserver, MediaChange } from '@angular/flex-layout';

export interface IResponsiveRowsMap {
    xs?: number;
    sm?: number;
    md?: number;
    lg?: number;
    xl?: number;
}

@Directive({
    selector: '[responsiveRows]'
})
export class ResponsiveRowsDirective implements OnInit {
    private countBySize: IResponsiveRowsMap = { xs: 2, sm: 2, md: 4, lg: 6, xl: 8 };

    public get colspan(): IResponsiveRowsMap {
        return this.countBySize;
    }

    @Input('responsiveRows')
    public set colspan(map: IResponsiveRowsMap) {
        if (map && ('object' === (typeof map))) {
            this.countBySize = map;
        }
    }

    public constructor(private grid: MatGridTile, private serviceMedia: MediaObserver) {
        this.initializeRowsCount();
    }

    public ngOnInit(): void {
        this.initializeRowsCount();
        this.serviceMedia.media$
            .subscribe((changes: MediaChange) => {
                this.grid.colspan = this.countBySize[changes.mqAlias]
            });
    }

    private initializeRowsCount(): void {
        Object.keys(this.countBySize).some(
            (mqAlias: string): boolean => {
                const isActive = this.serviceMedia.isActive(mqAlias);
                if (isActive) {
                    this.grid.colspan = this.countBySize[mqAlias];
                }
                return isActive;
            });
    }
}