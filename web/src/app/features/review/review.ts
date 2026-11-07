import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, computed, inject, OnInit, signal } from '@angular/core';
import { Conflict, ConflictStatus, Proposal } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';
import { ACTION_LABELS } from '../../core/state/format';

interface ProposalView extends Proposal {
  label: string;
  message?: string;
  title?: string;
  before?: string;
  after?: string;
  reason?: string;
}

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
  protected readonly proposals = signal<ProposalView[]>([]);
  protected readonly showAll = signal(false);
  protected readonly error = signal('');
  protected readonly busy = signal('');
  protected readonly notice = signal('');
  protected readonly visibleConflicts = computed(() =>
    this.showAll() ? this.conflicts() : this.conflicts().filter((conflict) => conflict.Status === 'Open'),
  );
  protected readonly visibleProposals = computed(() =>
    this.showAll() ? this.proposals() : this.proposals().filter((proposal) => proposal.Status === 'Proposed'),
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
    this.api.reviewConflict(conflict.Id, status).subscribe(() => this.refresh());
  }

  protected decide(proposal: ProposalView, status: 'Approved' | 'Rejected'): void {
    this.busy.set(proposal.Id);
    this.error.set('');
    this.notice.set('');
    this.api.decideProposal(proposal.Id, status).subscribe({
      next: () => {
        this.busy.set('');
        this.notice.set(status === 'Approved' ? `${proposal.label} approved and run.` : `${proposal.label} rejected.`);
        this.refresh();
      },
      error: (failure: HttpErrorResponse) => {
        this.busy.set('');
        this.error.set(failure.error?.error ?? 'The decision could not be saved.');
        this.refresh();
      },
    });
  }

  private refresh(): void {
    this.load();
    this.store.refreshCounts();
  }

  private load(): void {
    this.api.conflicts().subscribe((conflicts) => this.conflicts.set(conflicts));
    this.api.proposals().subscribe((proposals) => this.proposals.set(proposals.map((proposal) => this.view(proposal))));
  }

  private view(proposal: Proposal): ProposalView {
    let payload: Record<string, string> = {};
    try {
      payload = JSON.parse(proposal.Payload);
    } catch {
      payload = {};
    }
    return { ...proposal, ...payload, label: ACTION_LABELS[proposal.ActionType] ?? proposal.ActionType };
  }
}
