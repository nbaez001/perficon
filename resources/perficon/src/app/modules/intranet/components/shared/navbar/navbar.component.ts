import { Component, Inject, Input } from '@angular/core';
import { BreakpointObserver, Breakpoints, BreakpointState } from '@angular/cdk/layout';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Persona } from 'src/app/model/persona.model';
import { Router } from '@angular/router';
import { UsuarioService } from 'src/app/services/usuario.service';

@Component({
  selector: 'app-navbar',
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css']
})
export class NavbarComponent {
  @Input() showSubmenu1: boolean;
  
  persona: Persona;

  isHandset$: Observable<boolean> = this.breakpointObserver.observe(Breakpoints.Handset)
    .pipe(
      map(result => result.matches)
    );

  constructor(private breakpointObserver: BreakpointObserver, private router: Router, @Inject(UsuarioService) private user: UsuarioService) { }

  ngOnInit() {
    console.log(this.user);
    if (this.user.getIdUsuario == null) {
      this.router.navigate(['sesion/login']);
    }
    // this.persona = JSON.parse(sessionStorage.getItem('persona'));
  }

  salir() {
    this.router.navigate(['sesion/login']);
  }

  get getUser() {
    return this.user;
  }
}
