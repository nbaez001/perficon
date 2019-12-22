import { Component, OnInit, Inject } from '@angular/core';
import { Usuario } from 'src/app/model/usuario.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Persona } from 'src/app/model/persona.model';
import { UsuarioService } from 'src/app/services/usuario.service';
import { ValidationService } from 'src/app/services/validation.service';
import { Cookie } from 'ng2-cookies/ng2-cookies';
import { Ng4LoadingSpinnerService } from 'ng4-loading-spinner';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  usuario: Usuario;
  persona: Persona;
  mostrar: boolean = false;

  loginForm: FormGroup;
  messages = {
    'usuario': {
      'required': 'El campo es obligatorio'
    },
    'contrasenia': {
      'required': 'El campo es obligatorio'
    }
  };

  formErrors = {
    'usuario': '',
    'contrasenia': ''
  };

  constructor(private fb: FormBuilder, private router: Router,
    private spinnerService: Ng4LoadingSpinnerService,
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(ValidationService) private validationService: ValidationService) { }

  ngOnInit() {
    this.spinnerService.show();
    this.loginForm = this.fb.group({
      usuario: ['', [Validators.required]],
      contrasenia: ['', [Validators.required]],
      recordar: ['', []]
    });

    this.validateAutenticacion();
  }

  validateAutenticacion(): void {
    let recordar = Cookie.get('recordar');
    if (recordar == 'true') {
      this.loginForm.get('recordar').setValue(true);
      let uUsuario = Cookie.get('idUsuario');
      let uPassword = Cookie.get('passUsuario');
      this.validarCredenciales(uUsuario, uPassword);
    } else {
      this.spinnerService.hide();
    }
  }

  autenticar() {
    if (this.loginForm.valid) {
      let uuser = this.loginForm.get('usuario').value;
      let upass = this.loginForm.get('contrasenia').value;
      this.validarCredenciales(uuser, upass);
    } else {
      this.validationService.getValidationErrors(this.loginForm, this.messages, this.formErrors, true);
    }
  }

  validarCredenciales(uuser: string, upass: string): void {
    if (uuser == 'admin' && upass == 'Diranach1') {
      this.user.setIdUsuario = 1;
      this.user.setUsuario = this.loginForm.get('usuario').value;
      this.user.setNombres = 'AMILCAR';
      this.user.setApePaterno = 'PEREZ';
      this.user.setApeMaterno = 'CUELLAR';
      this.user.setEmail = 'nbaez001@gmail.com';
      this.user.setPerfil = 'INFORMATICA';
      this.user.setAbrevPerfil = 'INF.';

      if (this.loginForm.get('recordar').value) {
        // var expireDate = new Date().getTime() + (1000 * 5);
        Cookie.set("idUsuario", uuser, 365);
        Cookie.set("passUsuario", upass, 365);
        Cookie.set("recordar", "true", 365);
      }
      this.spinnerService.hide();
      this.router.navigate(['/intranet/home']);
    } else {
      this.spinnerService.hide();
      this.mostrar = true;
      setTimeout(() => {
        this.mostrar = false;
      }, 8000);
    }
  }
}
