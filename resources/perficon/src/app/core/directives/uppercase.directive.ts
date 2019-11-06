import { Directive, HostListener, ElementRef, Input } from '@angular/core';
import { NgControl } from '@angular/forms';

@Directive({
  selector: '[Uppercased]'
})

export class UppercaseDirective {
  @Input() Uppercased;

  constructor(private ref: ElementRef, private control: NgControl) { }

  @HostListener('input', ['$event']) onEvent($event) {
    const str: string = this.control.value;
    this.control.control.setValue(str.toUpperCase());
  }
}