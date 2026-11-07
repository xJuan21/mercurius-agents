import { ChangeDetectionStrategy, Component, computed, effect, inject, signal } from '@angular/core';
import { Knowledge as KnowledgeData } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';

@Component({
  selector: 'app-knowledge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './knowledge.html',
  styleUrl: './knowledge.scss',
})
export class Knowledge {
  private readonly api = inject(ApiService);

  protected readonly store = inject(AgentStore);
  protected readonly data = signal<KnowledgeData>({ nodes: [], edges: [] });
  protected readonly links = computed(() => {
    const { nodes, edges } = this.data();
    const title = (id: string) => nodes.find((node) => node.Id === String(id))?.Title ?? `Node ${id}`;
    return edges.map((edge) => ({
      type: edge.RelationshipType,
      source: title(edge.SourceNodeId),
      target: title(edge.TargetNodeId),
    }));
  });

  constructor() {
    effect(() => {
      const agent = this.store.selected();
      if (agent) {
        this.api.knowledge(agent.Name).subscribe((data) => this.data.set(data));
      }
    });
  }
}
