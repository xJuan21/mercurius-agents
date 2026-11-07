import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth/auth.service';

@Component({
  selector: 'app-login',
  imports: [ReactiveFormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './login.html',
  styleUrl: './login.scss',
})
export class Login {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  protected readonly form = inject(FormBuilder).nonNullable.group({
    user: ['', Validators.required],
    password: ['', Validators.required],
  });
  protected readonly busy = signal(false);
  protected readonly error = signal('');

  protected signIn(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { user, password } = this.form.getRawValue();
    this.busy.set(true);
    this.error.set('');
    this.auth.login(user, password).subscribe({
      next: () => this.router.navigate(['/chat']),
      error: (failure: HttpErrorResponse) => {
        this.busy.set(false);
        this.form.controls.password.reset();
        this.error.set(
          failure.status === 401 ? 'That username or password is incorrect.' : 'Sign-in is unavailable. Check that IRIS is running.',
        );
      },
    });
  }
}
