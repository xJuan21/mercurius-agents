import { ChangeDetectionStrategy, Component, DestroyRef, computed, inject, OnInit, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { interval, startWith, switchMap } from 'rxjs';
import { Execution, Summary } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';
import { DecisionCard } from '../../shared/decision-card/decision-card';

@Component({
  selector: 'app-history',
  imports: [FormsModule, DecisionCard],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './history.html',
  styleUrl: './history.scss',
})
export class History implements OnInit {
  private readonly api = inject(ApiService);
  private readonly destroyRef = inject(DestroyRef);

  protected readonly store = inject(AgentStore);
  protected readonly filter = signal('');
  protected readonly executions = signal<Execution[]>([]);
  protected readonly summary = signal<Summary | null>(null);
  protected readonly dollars = (value: string | number) => `$${(Number(value) || 0).toFixed(4)}`;
  protected readonly visible = computed(() => {
    const agent = this.filter();
    return agent ? this.executions().filter((run) => run.AgentName === agent) : this.executions();
  });

  ngOnInit(): void {
    // Polls so runs from the file services appear without a refresh.
    interval(5000)
      .pipe(
        startWith(0),
        switchMap(() => this.api.executions()),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((executions) => this.executions.set(executions));
    interval(5000)
      .pipe(
        startWith(0),
        switchMap(() => this.api.summary()),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((summary) => this.summary.set(summary));
  }
}
