export class CuentaBancoResponse {
    id: number;
    nroCuenta: string;
    cci: string;
    nombre: string;
    monto: number;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;
}