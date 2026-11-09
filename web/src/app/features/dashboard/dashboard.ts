import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { forkJoin } from 'rxjs';
import { ApiService } from '../../core/api/api.service';
import { Agent, Execution, Proposal, Summary } from '../../core/api/api.models';
import { ACTION_LABELS } from '../../core/state/format';
import { Icon } from '../../shared/icon/icon';

@Component({
  selector: 'app-dashboard',
  imports: [RouterLink, Icon],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Dashboard {
  private readonly api = inject(ApiService);
  private readonly destroy = inject(DestroyRef);
  protected readonly loading = signal(false);
  protected readonly error = signal('');
  protected readonly loaded = signal(false);
  protected readonly agents = signal<Agent[]>([]);
  protected readonly proposals = signal<Proposal[]>([]);
  protected readonly executions = signal<Execution[]>([]);
  protected readonly summary = signal<Summary | null>(null);
  protected readonly updated = signal('');
  protected readonly labels = ACTION_LABELS;
  constructor() {
    this.load();
  }
  protected load(): void {
    if (this.loading()) return;
    this.loading.set(true);
    this.error.set('');
    forkJoin({
      agents: this.api.agents(),
      proposals: this.api.proposals(),
      executions: this.api.executions(),
      summary: this.api.summary(),
    })
      .pipe(takeUntilDestroyed(this.destroy))
      .subscribe({
        next: (data) => {
          this.agents.set(data.agents);
          this.proposals.set(data.proposals.filter((p) => p.Status === 'Proposed').slice(0, 3));
          this.executions.set(data.executions.slice(0, 5));
          this.summary.set(data.summary);
          this.updated.set(
            new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          );
          this.loaded.set(true);
          this.loading.set(false);
        },
        error: () => {
          this.error.set('Workspace data could not be refreshed. Try again.');
          this.loading.set(false);
        },
      });
  }
}
