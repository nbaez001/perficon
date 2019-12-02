import { Component, OnInit, Inject } from '@angular/core';
import { Usuario } from 'src/app/model/usuario.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Persona } from 'src/app/model/persona.model';
import { UsuarioService } from 'src/app/services/usuario.service';
import { ValidationService } from 'src/app/services/validation.service';

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
    @Inject(UsuarioService) private user: UsuarioService,
    @Inject(ValidationService) private validationService: ValidationService) { }

  ngOnInit() {
    this.loginForm = this.fb.group({
      usuario: ['', [Validators.required]],
      contrasenia: ['', [Validators.required]]
    });
  }

  autenticar() {
    if (this.loginForm.valid) {
      let uuser = this.loginForm.get('usuario').value;
      let upass = this.loginForm.get('contrasenia').value;

      if (uuser == 'admin' && upass == 'Diranach1') {
        this.user.setIdUsuario = 1;
        this.user.setUsuario = this.loginForm.get('usuario').value;
        this.user.setNombres = 'AMILCAR';
        this.user.setApePaterno = 'PEREZ';
        this.user.setApeMaterno = 'CUELLAR';
        this.user.setEmail = 'nbaez001@gmail.com';
        this.user.setPerfil = 'INFORMATICA';
        this.user.setAbrevPerfil = 'INF.';

        this.router.navigate(['/intranet/home']);
      } else {
        this.mostrar = true;
        setTimeout(() => {
          this.mostrar = false;
        }, 8000);
      }
    } else {
      this.validationService.getValidationErrors(this.loginForm, this.messages, this.formErrors, true);
    }
  }
}
