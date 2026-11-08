import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, computed, effect, inject, signal, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Agent, AgentInput, ModelOption, ProviderModels } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';
import { AgentStore } from '../../core/state/agent.store';
import { splitList } from '../../core/state/format';

const TONES = ['Clear and thoughtful', 'Friendly and conversational', 'Precise and technical', 'Direct and concise'];

@Component({
  selector: 'app-agent-form',
  imports: [ReactiveFormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './agent-form.html',
  styleUrl: './agent-form.scss',
})
export class AgentForm {
  private readonly api = inject(ApiService);
  private readonly builder = inject(FormBuilder).nonNullable;
  private readonly dialog = viewChild.required<ElementRef<HTMLDialogElement>>('dialog');

  protected readonly store = inject(AgentStore);
  protected readonly tones = TONES;
  protected readonly saving = signal(false);
  protected readonly error = signal('');
  protected readonly selectedTools = signal<string[]>([]);
  protected readonly catalog = signal<ProviderModels[]>([]);
  protected readonly provider = signal('openai');
  protected readonly loadingModels = signal(false);
  protected readonly models = computed(() => this.modelsFor(this.provider()));
  protected readonly editing = computed(() => {
    const target = this.store.form();
    return target && target !== 'new' ? target : null;
  });

  protected readonly form = this.builder.group({
    name: ['', [Validators.required, Validators.pattern(/^[A-Za-z][A-Za-z0-9-]{0,29}$/)]],
    role: ['', [Validators.required, Validators.maxLength(200)]],
    description: ['', Validators.maxLength(1000)],
    tone: [TONES[0]],
    instructions: ['', [Validators.required, Validators.maxLength(4000)]],
    allowedDecisions: ['proceed,review,ignore', Validators.required],
    reviewDecisions: ['review'],
    provider: ['openai', Validators.required],
    model: ['gpt-4.1-mini', Validators.required],
    fallbackRules: ['', Validators.maxLength(4000)],
    enabled: [true],
  });

  constructor() {
    effect(() => {
      const target = this.store.form();
      if (target === null) {
        return;
      }
      this.reset(target === 'new' ? null : target);
      this.loadModels(false);
      this.dialog().nativeElement.showModal();
    });
  }

  protected loadModels(refresh: boolean): void {
    this.loadingModels.set(true);
    this.api.models(refresh).subscribe({
      next: (catalog) => {
        this.catalog.set(catalog);
        this.loadingModels.set(false);
      },
      error: () => this.loadingModels.set(false),
    });
  }

  protected chooseProvider(provider: string): void {
    this.provider.set(provider);
    const first = this.modelsFor(provider)[0];
    this.form.controls.model.setValue(first?.id ?? '');
  }

  /** Models with a price estimate first, then by name. Keeps the agent's current model listed. */
  private modelsFor(provider: string): ModelOption[] {
    const listed = this.catalog().find((entry) => entry.provider === provider)?.models ?? [];
    const current = this.form.controls.model.value;
    const models = [...listed];
    if (current && provider === this.provider() && !models.some((model) => model.id === current)) {
      models.push({ id: current, name: current, priced: false });
    }
    return models.sort((a, b) => Number(!!b.priced) - Number(!!a.priced) || a.id.localeCompare(b.id));
  }

  protected toggleTool(key: string, checked: boolean): void {
    this.selectedTools.update((tools) => (checked ? [...tools, key] : tools.filter((tool) => tool !== key)));
  }

  protected close(): void {
    this.dialog().nativeElement.close();
    this.store.form.set(null);
  }

  protected save(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { name, ...values } = this.form.getRawValue();
    const input: AgentInput = { ...values, tools: this.selectedTools() };
    const editing = this.editing();
    const request = editing ? this.api.updateAgent(editing.Name, input) : this.api.createAgent({ ...input, name });

    this.saving.set(true);
    this.error.set('');
    request.subscribe({
      next: () => {
        this.saving.set(false);
        this.store.load();
        if (!editing) {
          this.store.select(name);
        }
        this.close();
      },
      error: (failure: HttpErrorResponse) => {
        this.saving.set(false);
        this.error.set(failure.error?.error ?? 'The agent could not be saved.');
      },
    });
  }

  private reset(agent: Agent | null): void {
    this.error.set('');
    this.form.reset();
    this.selectedTools.set(agent ? splitList(agent.Tools) : ['SearchKnowledge']);
    this.provider.set(agent?.ProviderName || 'openai');
    if (agent) {
      this.form.patchValue({
        name: agent.Name,
        role: agent.Role,
        description: agent.Description,
        tone: agent.Tone,
        instructions: agent.SystemPrompt,
        allowedDecisions: agent.AllowedDecisions,
        reviewDecisions: agent.ReviewDecisions,
        fallbackRules: agent.FallbackRules ?? '',
        provider: agent.ProviderName,
        model: agent.ModelName,
        enabled: Number(agent.Enabled) === 1,
      });
      this.form.controls.name.disable();
    } else {
      this.form.controls.name.enable();
    }
  }
}
