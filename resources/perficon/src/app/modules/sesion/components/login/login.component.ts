import { Component, OnInit, Inject } from '@angular/core';
import { Usuario } from 'src/app/model/usuario.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Persona } from 'src/app/model/persona.model';
import { UsuarioService } from 'src/app/services/usuario.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  usuario: Usuario;
  persona: Persona;

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

  constructor(private fb: FormBuilder, private router: Router, @Inject(UsuarioService) private user: UsuarioService) { }

  ngOnInit() {
    this.loginForm = this.fb.group({
      usuario: ['', [Validators.required]],
      contrasenia: ['', [Validators.required]]
    });
  }

  autenticar() {
    this.user.setIdUsuario = 1;
    this.user.setUsuario = this.loginForm.get('usuario').value;
    this.user.setNombres = 'PEDRO';
    this.user.setApePaterno = 'PEREZ';
    this.user.setApeMaterno = 'CUELLAR';
    this.user.setEmail = 'nbaez001@gmail.com';
    this.user.setPerfil = 'INFORMATICA';
    this.user.setAbrevPerfil = 'INF.';

    //   sessionStorage.setItem('user', JSON.stringify(this.user));
    // sessionStorage.setItem('persona', JSON.stringify(this.persona));
    this.router.navigate(['/intranet/home']);
  }
}
