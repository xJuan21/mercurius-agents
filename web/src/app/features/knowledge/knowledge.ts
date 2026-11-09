import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  computed,
  effect,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { Knowledge as KnowledgeData, KnowledgeNode } from '../../core/api/api.models';
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
  protected readonly loading = signal(false);
  protected readonly error = signal('');
  protected readonly query = signal('');
  protected readonly type = signal('');
  protected readonly mode = signal<'cards' | 'graph'>('cards');
  protected readonly selectedId = signal('');
  protected readonly focused = signal(false);
  protected readonly zoom = signal(1);
  protected readonly pan = signal({ x: 0, y: 0 });
  private readonly revision = signal(0);
  private readonly reader = viewChild<ElementRef<HTMLDialogElement>>('reader');
  private drag: { x: number; y: number; px: number; py: number } | null = null;
  private opener: HTMLElement | null = null;
  protected readonly types = computed(() =>
    [...new Set(this.data().nodes.map((n) => n.NodeType))].sort(),
  );
  protected readonly selected = computed(
    () => this.data().nodes.find((n) => String(n.Id) === this.selectedId()) ?? null,
  );
  protected readonly filtered = computed(() => {
    const q = this.query().trim().toLowerCase();
    return this.data().nodes.filter(
      (n) =>
        (!this.type() || n.NodeType === this.type()) &&
        (!q || (n.Title + ' ' + n.Content).toLowerCase().includes(q)),
    );
  });
  protected readonly neighbors = computed(() => {
    const ids = new Set([this.selectedId()]);
    for (const e of this.data().edges) {
      if (String(e.SourceNodeId) === this.selectedId()) ids.add(String(e.TargetNodeId));
      if (String(e.TargetNodeId) === this.selectedId()) ids.add(String(e.SourceNodeId));
    }
    return ids;
  });
  protected readonly graph = computed(() => {
    const nodes = this.filtered().filter(
      (n) => !this.focused() || this.neighbors().has(String(n.Id)),
    );
    const count = nodes.length;
    return nodes.map((n, i) => {
      const ring = Math.floor(i / 24),
        inRing = Math.min(24, count - ring * 24);
      const angle = ((i % 24) * Math.PI * 2) / inRing - Math.PI / 2;
      const radius = count === 1 ? 0 : Math.min(360, 110 + ring * 38 + (count < 12 ? 30 : 0));
      return { ...n, x: 500 + Math.cos(angle) * radius, y: 400 + Math.sin(angle) * radius * 0.85 };
    });
  });
  protected readonly graphEdges = computed(() => {
    const lookup = new Map(this.graph().map((n) => [String(n.Id), n]));
    return this.data().edges.flatMap((e, i) => {
      const source = lookup.get(String(e.SourceNodeId)),
        target = lookup.get(String(e.TargetNodeId));
      return source && target ? [{ ...e, key: i, source, target }] : [];
    });
  });
  protected readonly related = computed(() =>
    this.data().edges.flatMap((e) => {
      const id = this.selectedId();
      const other =
        String(e.SourceNodeId) === id
          ? String(e.TargetNodeId)
          : String(e.TargetNodeId) === id
            ? String(e.SourceNodeId)
            : null;
      if (!other) return [];
      const node = this.data().nodes.find((n) => String(n.Id) === other);
      return [
        { node, id: other, type: e.RelationshipType, outgoing: String(e.SourceNodeId) === id },
      ];
    }),
  );
  protected readonly transform = computed(
    () =>
      `translate(${this.pan().x} ${this.pan().y}) translate(500 400) scale(${this.zoom()}) translate(-500 -400)`,
  );
  constructor() {
    effect((onCleanup) => {
      const name = this.store.selected()?.Name;
      this.revision();
      this.close();
      this.selectedId.set('');
      this.focused.set(false);
      this.fit();
      this.data.set({ nodes: [], edges: [] });
      this.error.set('');
      if (!name) {
        this.loading.set(false);
        return;
      }
      this.loading.set(true);
      const sub = this.api.knowledge(name).subscribe({
        next: (data) => {
          this.data.set(data);
          this.loading.set(false);
        },
        error: () => {
          this.error.set('We could not load this agent’s notes. Please try again.');
          this.loading.set(false);
        },
      });
      onCleanup(() => sub.unsubscribe());
    });
  }
  protected choose(name: string) {
    this.type.set('');
    this.store.select(name);
  }
  protected retry() {
    this.revision.update((v) => v + 1);
  }
  protected clear() {
    this.query.set('');
    this.type.set('');
    this.focused.set(false);
  }
  protected connections(id: string) {
    return this.data().edges.filter(
      (e) => String(e.SourceNodeId) === String(id) || String(e.TargetNodeId) === String(id),
    ).length;
  }
  protected label(value: string) {
    return value === 'CONTRADICTS'
      ? 'Potential conflict'
      : value.toLowerCase().replaceAll('_', ' ');
  }
  protected open(note: KnowledgeNode, event?: Event) {
    if (!this.reader()?.nativeElement.open)
      this.opener =
        (event?.currentTarget as HTMLElement) ?? (document.activeElement as HTMLElement);
    this.selectedId.set(String(note.Id));
    this.reader()?.nativeElement.showModal();
    this.reader()?.nativeElement.querySelector<HTMLElement>('.close')?.focus();
  }
  protected close() {
    this.reader()?.nativeElement.close();
  }
  protected restoreFocus() {
    if (this.opener?.isConnected) this.opener.focus();
  }
  protected focusConnections() {
    this.focused.set(true);
    this.mode.set('graph');
    this.fit();
    this.close();
  }
  protected fit() {
    this.zoom.set(1);
    this.pan.set({ x: 0, y: 0 });
  }
  protected scale(factor: number) {
    this.zoom.update((z) => Math.max(0.4, Math.min(3, z * factor)));
  }
  protected startPan(e: PointerEvent) {
    if ((e.target as Element).closest('.graph-node') || e.button !== 0) return;
    const svg = e.currentTarget as SVGSVGElement,
      p = this.pan();
    this.drag = { x: e.clientX, y: e.clientY, px: p.x, py: p.y };
    svg.setPointerCapture(e.pointerId);
  }
  protected movePan(e: PointerEvent) {
    if (!this.drag) return;
    const rect = (e.currentTarget as SVGSVGElement).getBoundingClientRect(),
      ratio = Math.max(1000 / rect.width, 800 / rect.height);
    this.pan.set({
      x: this.drag.px + (e.clientX - this.drag.x) * ratio,
      y: this.drag.py + (e.clientY - this.drag.y) * ratio,
    });
  }
  protected endPan() {
    this.drag = null;
  }
}
