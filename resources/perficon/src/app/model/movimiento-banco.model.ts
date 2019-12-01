export class MovimientoBanco {
    id: number;
    idCuentaBanco: number;
    nomCuentaBanco: string;
    idTipoMovimiento: number;
    nomTipoMovimiento: string;
    valTipoMovimiento: number;
    detalle: string;
    monto: number;
    fecha: Date;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;
}