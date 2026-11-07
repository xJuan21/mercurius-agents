import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { map, Observable } from 'rxjs';
import {
  Agent,
  AgentInput,
  Conflict,
  ConflictStatus,
  Execution,
  Knowledge,
  Memory,
  Summary,
  Tool,
} from './api.models';

export const API_URL = 'api';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly http = inject(HttpClient);

  agents(): Observable<Agent[]> {
    return this.http.get<Agent[]>(`${API_URL}/agents`);
  }

  createAgent(input: AgentInput): Observable<unknown> {
    return this.http.post(`${API_URL}/agents`, input);
  }

  updateAgent(name: string, input: AgentInput): Observable<unknown> {
    return this.http.put(`${API_URL}/agents/${encodeURIComponent(name)}`, input);
  }

  /** Runs the message through the production, so it can take several seconds. */
  sendMessage(agent: string, text: string): Observable<unknown> {
    return this.http.post(`${API_URL}/agents/${encodeURIComponent(agent)}/messages`, { text });
  }

  tools(): Observable<Tool[]> {
    return this.http.get<Tool[]>(`${API_URL}/tools`);
  }

  summary(): Observable<Summary> {
    return this.http.get<Summary[]>(`${API_URL}/summary`).pipe(map((rows) => rows[0]));
  }

  executions(agent?: string): Observable<Execution[]> {
    return this.http.get<Execution[]>(`${API_URL}/executions`, { params: this.agentParam(agent) });
  }

  conflicts(): Observable<Conflict[]> {
    return this.http.get<Conflict[]>(`${API_URL}/conflicts`);
  }

  reviewConflict(id: string, status: ConflictStatus): Observable<unknown> {
    return this.http.put(`${API_URL}/conflicts/${id}`, { status });
  }

  knowledge(agent: string): Observable<Knowledge> {
    return this.http.get<Knowledge>(`${API_URL}/knowledge`, { params: this.agentParam(agent) });
  }

  memory(agent: string): Observable<Memory[]> {
    return this.http.get<Memory[]>(`${API_URL}/memory`, { params: this.agentParam(agent) });
  }

  private agentParam(agent?: string): HttpParams {
    return agent ? new HttpParams().set('agent', agent) : new HttpParams();
  }
}
