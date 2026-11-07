import { Routes } from '@angular/router';
import { authGuard } from './core/auth/auth.guard';

export const routes: Routes = [
  { path: 'login', loadComponent: () => import('./features/login/login').then((m) => m.Login) },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('./layout/shell/shell').then((m) => m.Shell),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'chat' },
      { path: 'chat', title: 'Chat', loadComponent: () => import('./features/chat/chat').then((m) => m.Chat) },
      { path: 'agents', title: 'Agents', loadComponent: () => import('./features/agents/agents').then((m) => m.Agents) },
      { path: 'review', title: 'Review', loadComponent: () => import('./features/review/review').then((m) => m.Review) },
      { path: 'memory', title: 'Memory', loadComponent: () => import('./features/memory/memory').then((m) => m.Memory) },
      { path: 'history', title: 'History', loadComponent: () => import('./features/history/history').then((m) => m.History) },
      { path: 'knowledge', title: 'Knowledge', loadComponent: () => import('./features/knowledge/knowledge').then((m) => m.Knowledge) },
    ],
  },
  { path: '**', redirectTo: '' },
];
