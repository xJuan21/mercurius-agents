import { HttpClient } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Observable, finalize, map, of, shareReplay, tap, catchError } from 'rxjs';
import { API_URL } from '../api/api.service';

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  sub?: string;
}

const REFRESH_KEY = 'mercurius.refresh';
const USER_KEY = 'mercurius.user';

/**
 * Uses the JWT endpoints IRIS adds to the web application. The access token stays in
 * memory. The refresh token lives in sessionStorage, so it ends with the browser tab.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly token = signal<string | null>(null);
  private refreshing: Observable<string> | null = null;

  readonly username = signal(sessionStorage.getItem(USER_KEY) ?? '');
  readonly accessToken = this.token.asReadonly();
  readonly isSignedIn = computed(() => this.token() !== null);

  get canRestore(): boolean {
    return sessionStorage.getItem(REFRESH_KEY) !== null;
  }

  login(user: string, password: string): Observable<void> {
    return this.http.post<TokenResponse>(`${API_URL}/login`, { user, password }).pipe(
      tap((response) => {
        this.username.set(response.sub ?? user);
        sessionStorage.setItem(USER_KEY, this.username());
        this.store(response);
      }),
      map(() => undefined),
    );
  }

  /** Concurrent callers share one request, because each refresh token works only once. */
  refresh(): Observable<string> {
    if (this.refreshing) {
      return this.refreshing;
    }
    const refreshToken = sessionStorage.getItem(REFRESH_KEY) ?? '';
    this.refreshing = this.http
      .post<TokenResponse>(`${API_URL}/refresh`, {
        refresh_token: refreshToken,
        grant_type: 'refresh_token',
      })
      .pipe(
        tap((response) => this.store(response)),
        map((response) => response.access_token),
        finalize(() => (this.refreshing = null)),
        shareReplay(1),
      );
    return this.refreshing;
  }

  logout(): Observable<void> {
    return this.http.post(`${API_URL}/logout`, {}).pipe(
      catchError(() => of(null)),
      map(() => undefined),
      finalize(() => this.clear()),
    );
  }

  clear(): void {
    this.token.set(null);
    this.username.set('');
    sessionStorage.removeItem(REFRESH_KEY);
    sessionStorage.removeItem(USER_KEY);
  }

  private store(response: TokenResponse): void {
    this.token.set(response.access_token);
    sessionStorage.setItem(REFRESH_KEY, response.refresh_token);
  }
}
