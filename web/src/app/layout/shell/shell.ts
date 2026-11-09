import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../../core/auth/auth.service';
import { AgentStore } from '../../core/state/agent.store';
import { PORTAL_URL, splitList } from '../../core/state/format';
import { AgentForm } from '../../shared/agent-form/agent-form';
import { Icon } from '../../shared/icon/icon';

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Icon, AgentForm],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
})
export class Shell implements OnInit {
  private readonly router = inject(Router);

  protected readonly auth = inject(AuthService);
  protected readonly store = inject(AgentStore);
  protected readonly portalUrl = PORTAL_URL;
  protected readonly menuOpen = signal(false);
  protected readonly initials = computed(() => this.auth.username().slice(0, 2).toUpperCase());
  protected readonly selectedTools = computed(() => splitList(this.store.selected()?.Tools));
  protected readonly ruleCount = computed(
    () =>
      (this.store.selected()?.FallbackRules ?? '').split('\n').filter((line) => line.includes('=>'))
        .length,
  );
  protected readonly reviewCount = computed(
    () => this.store.openConflicts() + this.store.pendingActions(),
  );
  protected isDashboard(): boolean {
    return this.router.url.split('?')[0] === '/dashboard';
  }

  protected readonly pages = [
    { path: '/dashboard', label: 'Dashboard', icon: 'dashboard' },
    { path: '/chat', label: 'Chat', icon: 'chat' },
    { path: '/agents', label: 'Agents', icon: 'agents' },
    { path: '/review', label: 'Review', icon: 'review' },
    { path: '/inbox', label: 'Inbox', icon: 'inbox' },
    { path: '/memory', label: 'Memory', icon: 'memory' },
    { path: '/history', label: 'History', icon: 'history' },
    { path: '/knowledge', label: 'Knowledge', icon: 'graph' },
  ];

  ngOnInit(): void {
    this.store.load();
  }

  protected chooseAgent(name: string): void {
    this.store.select(name);
    this.menuOpen.set(false);
    this.router.navigate(['/chat']);
  }

  protected signOut(): void {
    this.auth.logout().subscribe(() => this.router.navigate(['/login']));
  }
}
