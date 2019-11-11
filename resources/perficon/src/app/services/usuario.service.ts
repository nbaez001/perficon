import { Injectable } from '@angular/core';

@Injectable({
    providedIn: 'root'
})
export class UsuarioService {
    private idUsuario: number;
    private usuario: string;
    private nombres: string;
    private apePaterno: string;
    private apeMaterno: string;
    private email: string;
    private perfil: string;
    private abrevPerfil: string;

    constructor() { }

    set setIdUsuario(idUsuario: number) { this.idUsuario = idUsuario; }
    set setUsuario(usuario: string) { this.usuario = usuario; }
    set setNombres(nombres: string) { this.nombres = nombres; }
    set setApePaterno(apePaterno: string) { this.apePaterno = apePaterno; }
    set setApeMaterno(apeMaterno: string) { this.apeMaterno = apeMaterno; }
    set setEmail(email: string) { this.email = email; }
    set setPerfil(perfil: string) { this.perfil = perfil; }
    set setAbrevPerfil(abrevPerfil: string) { this.abrevPerfil = abrevPerfil; }

    get getIdUsuario() { return this.idUsuario; }
    get getUsuario() { return this.usuario; }
    get getNombres() { return this.nombres; }
    get getApePaterno() { return this.apePaterno; }
    get getApeMaterno() { return this.apeMaterno; }
    get getEmail() { return this.email; }
    get getPerfil() { return this.perfil; }
    get getAbrevPerfil() { return this.abrevPerfil; }

    public limpiarRegistro(): void {
        this.idUsuario = null;
        this.usuario = null;
        this.nombres = null;
        this.apePaterno = null;
        this.apeMaterno = null;
        this.email = null;
        this.perfil = null;
        this.abrevPerfil = null;
        return null;
    }

}
