import { computed, inject, Injectable, signal } from '@angular/core';
import { ApiService } from '../api/api.service';
import { Agent, Tool } from '../api/api.models';

/** The agents and the selection shared by every page. */
@Injectable({ providedIn: 'root' })
export class AgentStore {
  private readonly api = inject(ApiService);
  private readonly selectedName = signal('');

  readonly agents = signal<Agent[]>([]);
  readonly tools = signal<Tool[]>([]);
  readonly openConflicts = signal(0);
  readonly selected = computed(
    () => this.agents().find((agent) => agent.Name === this.selectedName()) ?? this.agents()[0] ?? null,
  );

  /** null closes the form, 'new' builds an agent, and an Agent edits it. */
  readonly form = signal<Agent | 'new' | null>(null);

  load(): void {
    this.api.agents().subscribe((agents) => this.agents.set(agents));
    this.api.tools().subscribe((tools) => this.tools.set(tools));
    this.refreshCounts();
  }

  refreshCounts(): void {
    this.api.summary().subscribe((summary) => this.openConflicts.set(Number(summary.OpenConflicts) || 0));
  }

  select(name: string): void {
    this.selectedName.set(name);
  }

  toolLabel(key: string): string {
    return this.tools().find((tool) => tool.key === key)?.label ?? key;
  }
}
