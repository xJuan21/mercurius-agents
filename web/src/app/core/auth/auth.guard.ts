import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { catchError, map, of } from 'rxjs';
import { AuthService } from './auth.service';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.isSignedIn()) {
    return true;
  }
  if (!auth.canRestore) {
    return router.createUrlTree(['/login']);
  }
  return auth.refresh().pipe(
    map(() => true),
    catchError(() => {
      auth.clear();
      return of(router.createUrlTree(['/login']));
    }),
  );
};
