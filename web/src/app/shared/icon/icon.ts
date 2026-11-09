import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-icon',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg viewBox="0 0 24 24" aria-hidden="true">
      @switch (name()) {
        @case ('dashboard') {
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
          <rect x="14" y="14" width="7" height="7" rx="1" />
        }
        @case ('chat') {
          <path d="M5 4h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H9l-6 3V6a2 2 0 0 1 2-2Z" />
          <path d="M8 9h8M8 13h5" />
        }
        @case ('memory') {
          <path d="M5 3h14v18H5zM9 7h6M9 11h6M9 15h3M3 7h2M3 12h2M3 17h2" />
        }
        @case ('history') {
          <path d="M3 11a9 9 0 1 1 2 7M3 4v7h7M12 7v6l4 2" />
        }
        @case ('graph') {
          <circle cx="6" cy="6" r="3" />
          <circle cx="18" cy="9" r="3" />
          <circle cx="9" cy="19" r="3" />
          <path d="m9 7 6 1M7 9l1 7m3 1 5-6" />
        }
        @case ('arrow') {
          <path d="M12 19V5m-6 6 6-6 6 6" />
        }
        @case ('spark') {
          <path d="m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5ZM20 2v4M18 4h4" />
        }
        @case ('shield') {
          <path d="m12 3 8 3v6c0 4-8 9-8 9s-8-5-8-9V6ZM8 12l3 3 5-6" />
        }
        @case ('inbox') {
          <path d="M4 13h4l2 3h4l2-3h4M4 13l2-8h12l2 8v6H4Z" />
        }
        @case ('review') {
          <path d="M12 3 2 20h20L12 3ZM12 10v4M12 17h.01" />
        }
        @default {
          <rect x="5" y="6" width="14" height="14" rx="4" />
          <path d="M12 3v3M9 12h.01M15 12h.01M9 16h6M2 11v4M22 11v4" />
        }
      }
    </svg>
  `,
  styles: `
    :host {
      display: inline-flex;
    }
    svg {
      width: 20px;
      height: 20px;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.7;
      stroke-linecap: round;
      stroke-linejoin: round;
    }
  `,
})
export class Icon {
  readonly name = input.required<string>();
}
