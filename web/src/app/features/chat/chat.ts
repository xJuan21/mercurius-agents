import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, computed, effect, inject, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Execution } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';
import { DecisionCard } from '../../shared/decision-card/decision-card';
import { Icon } from '../../shared/icon/icon';

const SUGGESTIONS: Record<string, string[]> = {
  Documenter: [
    'Decision: the WhatsApp webhook now uses Cloudflare Tunnel instead of Tailscale Funnel.',
    'IRIS backup update: a weekly offsite copy now runs, in addition to the nightly backup.',
    'Team lunch on Friday: sandwiches and fruit.',
  ],
  Sentinel: ['iris-dev disk is 97 percent full and journal writes are failing.', 'Nightly backup finished in 12 minutes.'],
  Forge: ['Please review this line: set x=$get(^Config("key")) w x', 'Set Total = Total + 1'],
  Query: ['How many runs went to review?', "Show each agent's total estimated cost.", 'Which agents can propose notifications?'],
};

@Component({
  selector: 'app-chat',
  imports: [FormsModule, DecisionCard, Icon],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './chat.html',
  styleUrl: './chat.scss',
})
export class Chat {
  private readonly api = inject(ApiService);
  private readonly conversation = viewChild<ElementRef<HTMLElement>>('conversation');

  protected readonly store = inject(AgentStore);
  protected readonly thread = signal<Execution[]>([]);
  protected readonly draft = signal('');
  protected readonly pending = signal('');
  protected readonly error = signal('');
  protected readonly suggestions = computed(() => SUGGESTIONS[this.store.selected()?.Name ?? ''] ?? []);

  constructor() {
    effect(() => {
      const agent = this.store.selected();
      if (agent) {
        this.loadThread(agent.Name);
      }
    });
  }

  protected onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.send();
    }
  }

  protected send(): void {
    const agent = this.store.selected();
    const text = this.draft().trim();
    if (!agent || !text || this.pending()) {
      return;
    }
    this.pending.set(text);
    this.draft.set('');
    this.error.set('');
    this.scrollDown();
    this.api.sendMessage(agent.Name, text).subscribe({
      next: () => {
        this.pending.set('');
        this.loadThread(agent.Name);
        this.store.refreshCounts();
      },
      error: (failure: HttpErrorResponse) => {
        this.pending.set('');
        this.draft.set(text);
        this.error.set(failure.error?.error ?? 'The message could not be sent.');
      },
    });
  }

  private loadThread(agent: string): void {
    this.api.executions(agent).subscribe((executions) => {
      this.thread.set([...executions].reverse());
      this.scrollDown();
    });
  }

  private scrollDown(): void {
    setTimeout(() => {
      const element = this.conversation()?.nativeElement;
      if (element) {
        element.scrollTop = element.scrollHeight;
      }
    });
  }
}
