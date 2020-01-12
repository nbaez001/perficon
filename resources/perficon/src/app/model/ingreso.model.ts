export class Ingreso {
    id: number;
    idTipoIngreso: number;
    nomTipoIngreso: string;
    idMovimientoBanco: number;

    nombre: string;
    monto: number;
    observacion: string;
    fecha: Date;
    idEstado: number;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;

    json: any;
}