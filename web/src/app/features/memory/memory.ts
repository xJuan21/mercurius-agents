import { ChangeDetectionStrategy, Component, effect, inject, signal } from '@angular/core';
import { Memory as MemoryRow } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';

@Component({
  selector: 'app-memory',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './memory.html',
})
export class Memory {
  private readonly api = inject(ApiService);

  protected readonly store = inject(AgentStore);
  protected readonly memories = signal<MemoryRow[]>([]);

  constructor() {
    effect(() => {
      const agent = this.store.selected();
      if (agent) {
        this.api.memory(agent.Name).subscribe((memories) => this.memories.set(memories));
      }
    });
  }
}
