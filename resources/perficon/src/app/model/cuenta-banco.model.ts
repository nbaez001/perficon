export class CuentaBanco {
    id: number;
    nroCuenta: string;
    cci: string;
    nombre: string;
    saldo: number;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;

    constructor(id: number, nombre: string) {
        this.id = id;
        this.nombre = nombre;
    }
}