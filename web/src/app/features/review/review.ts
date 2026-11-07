import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { Conflict, ConflictStatus } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';

@Component({
  selector: 'app-review',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './review.html',
  styleUrl: './review.scss',
})
export class Review implements OnInit {
  private readonly api = inject(ApiService);
  private readonly store = inject(AgentStore);

  protected readonly conflicts = signal<Conflict[]>([]);
  protected readonly showAll = signal(false);
  protected readonly visible = computed(() =>
    this.showAll() ? this.conflicts() : this.conflicts().filter((conflict) => conflict.Status === 'Open'),
  );
  protected readonly actions: { status: ConflictStatus; label: string }[] = [
    { status: 'Resolved', label: 'Resolve' },
    { status: 'Reviewed', label: 'Mark reviewed' },
    { status: 'Dismissed', label: 'Dismiss' },
  ];

  ngOnInit(): void {
    this.load();
  }

  protected review(conflict: Conflict, status: ConflictStatus): void {
    this.api.reviewConflict(conflict.Id, status).subscribe(() => {
      this.load();
      this.store.refreshCounts();
    });
  }

  private load(): void {
    this.api.conflicts().subscribe((conflicts) => this.conflicts.set(conflicts));
  }
}
