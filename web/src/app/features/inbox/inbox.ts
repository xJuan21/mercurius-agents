import { ChangeDetectionStrategy, Component, inject, OnInit, signal } from '@angular/core';
import { Notification } from '../../core/api/api.models';
import { ApiService } from '../../core/api/api.service';

@Component({
  selector: 'app-inbox',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './inbox.html',
})
export class Inbox implements OnInit {
  private readonly api = inject(ApiService);

  protected readonly notifications = signal<Notification[]>([]);

  ngOnInit(): void {
    this.api.notifications().subscribe((notifications) => this.notifications.set(notifications));
  }
}
