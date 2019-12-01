export const webServiceEndpoint: string = 'http://perficon.test/api/';
// export const webServiceEndpoint: string = 'http://perficon.elnazarenovraem.edu.pe/api/';

export const DIAS: Object[] = [
    { id: 1, nombre: 'LUNES' },
    { id: 2, nombre: 'MARTES' },
    { id: 3, nombre: 'MIERCOLES' },
    { id: 4, nombre: 'JUEVES' },
    { id: 5, nombre: 'VIERNES' },
    { id: 6, nombre: 'SABADO' },
    { id: 7, nombre: 'DOMINGO' },
];

export const MENSAJES = {
    INTRANET: {
        CONFIGURACION: {
            MAESTRA: {
                REGISTRAR: {
                    TITLE: 'REGISTRAR MAESTRA'
                },
                REGISTRARCHILD: {
                    TITLE: 'REGISTRAR HIJOS MAESTRA'
                }
            },
            CUENTABANCO: {
                REGISTRAR: {
                    TITLE: 'REGISTRAR CUENTA BANCARIA'
                },
                MODIFICAR: {
                    TITLE: 'MODIFICAR CUENTA BANCARIA'
                }
            }
        },
        BANDEJAEGRESOS: {
            EGRESO: {
                REGISTRAR: {
                    TITLE: 'REGISTRAR EGRESO'
                },
                EDITAR: {
                    TITLE: 'MODIFICAR EGRESO'
                }
            }
        },
        BANDEJAMOVIMIENTO: {
            MOVIMIENTO: {
                REGISTRAR: {
                    TITLE: 'REGISTRAR MOVIMIENTO'
                },
                EDITAR: {
                    TITLE: 'EDITAR MOVIMIENTO'
                }
            }
        }
    }
};