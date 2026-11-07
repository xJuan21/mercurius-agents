import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { AgentStore } from '../../core/state/agent.store';
import { Icon } from '../../shared/icon/icon';

@Component({
  selector: 'app-agents',
  imports: [Icon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './agents.html',
  styleUrl: './agents.scss',
})
export class Agents {
  private readonly router = inject(Router);

  protected readonly store = inject(AgentStore);

  protected open(name: string): void {
    this.store.select(name);
    this.router.navigate(['/chat']);
  }
}
