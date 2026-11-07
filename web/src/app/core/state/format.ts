import { Execution } from '../api/api.models';

export const splitList = (value: string | null | undefined): string[] =>
  (value ?? '').split(',').map((item) => item.trim()).filter(Boolean);

/** Reads the reason from the agent's JSON reply, or shows the raw reply. */
export function decisionReason(execution: Execution): string {
  const reply = execution.OutputSummary ?? '';
  const start = reply.indexOf('{');
  const end = reply.lastIndexOf('}');
  if (start >= 0 && end > start) {
    try {
      const parsed = JSON.parse(reply.slice(start, end + 1));
      return parsed.reason ?? reply;
    } catch {
      return reply;
    }
  }
  return reply;
}

export const traceUrl = (sessionId: string): string =>
  `/csp/irisapp/EnsPortal.VisualTrace.zen?SESSIONID=${encodeURIComponent(sessionId)}`;

export const PORTAL_URL = '/csp/sys/UtilHome.csp';
