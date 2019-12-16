export class Maestra {
    id: number;
    idMaestraPadre: number;
    orden: number;
    nombre: string;
    codigo: string;
    valor: string;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;

    constructor();
    constructor(obj: any);
    constructor(obj?: any) {
        this.id = obj && obj.id || 0;
        this.nombre = obj && obj.nombre || 0;
    }
}