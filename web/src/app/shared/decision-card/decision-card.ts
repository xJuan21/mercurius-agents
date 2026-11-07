import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { Execution } from '../../core/api/api.models';
import { AgentStore } from '../../core/state/agent.store';
import { decisionReason, splitList, traceUrl } from '../../core/state/format';

@Component({
  selector: 'app-decision-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './decision-card.html',
  styleUrl: './decision-card.scss',
})
export class DecisionCard {
  private readonly store = inject(AgentStore);

  readonly execution = input.required<Execution>();

  protected readonly failed = computed(() => this.execution().Status === 'Failed');
  protected readonly needsReview = computed(() => this.execution().Route === 'Review');
  protected readonly reason = computed(() => decisionReason(this.execution()));
  protected readonly tools = computed(() => {
    const unique = new Set(splitList(this.execution().Tools));
    return [...unique].map((key) => this.store.toolLabel(key));
  });
  protected readonly trace = computed(() => traceUrl(this.execution().InteropSessionId));
}
