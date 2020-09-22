export class DetalleEgresoRequest {
    id: number;
    idTipoEgreso: number;
    nomTipoEgreso: string;
    idUnidadMedida: number;
    nomUnidadMedida: string;
    nombre: string;
    cantidad: number;
    precio: number;
    subtotal: number;
    descripcion: string;
    ubicacion: string;
    dia: string;
    fecha: Date;
    idUsuarioCrea: number;
    fecUsuarioCrea: Date;
    idUsuarioMod: number;
    fecUsuarioMod: Date;
}