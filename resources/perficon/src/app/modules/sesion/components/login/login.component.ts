import { Component, OnInit } from '@angular/core';
import { Usuario } from 'src/app/model/usuario.model';
import { FormGroup, FormBuilder, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Persona } from 'src/app/model/persona.model';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent implements OnInit {
  user: Usuario;
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

  constructor(private fb: FormBuilder, private router: Router) { }

  ngOnInit() {
    this.loginForm = this.fb.group({
      usuario: ['', [Validators.required]],
      contrasenia: ['', [Validators.required]]
    });
  }

  autenticar() {
    this.user = {
      id: 0,
      usuario: this.loginForm.get('usuario').value,
      contrasenia: this.loginForm.get('contrasenia').value
    };
    this.persona = {
      id: 0,
      nombres: this.loginForm.get('usuario').value,
      apellidoPaterno: 'PEREZ',
      apellidoMaterno: 'CUELLAR',
      email: 'nbaez001@gmail.com',
      perfil: 'INFORMATICA',
      abreviadoPerfil: 'INF.'
    };

    sessionStorage.setItem('user', JSON.stringify(this.user));
    sessionStorage.setItem('persona', JSON.stringify(this.persona));
    this.router.navigate(['/intranet/home']);
  }
}
