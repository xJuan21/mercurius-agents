import { Execution } from '../api/api.models';

export const splitList = (value: string | null | undefined): string[] =>
  (value ?? '').split(',').map((item) => item.trim()).filter(Boolean);

/** Reads the agent's JSON reply. Returns null when the reply isn't JSON. */
function parseReply(execution: Execution): Record<string, string> | null {
  const reply = execution.OutputSummary ?? '';
  const start = reply.indexOf('{');
  const end = reply.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return null;
  }
  try {
    return JSON.parse(reply.slice(start, end + 1));
  } catch {
    return null;
  }
}

/** Code, SQL or text the agent produced, if any. */
export const decisionOutput = (execution: Execution): string => parseReply(execution)?.['output'] ?? '';

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

/** Formats an estimated cost, which is a lower bound because tool loops make more calls. */
export function formatCost(value: string | number | null | undefined): string {
  const amount = Number(value);
  if (value === '' || value === null || value === undefined || Number.isNaN(amount)) {
    return '';
  }
  return amount < 0.01 ? `at least $${amount.toFixed(4)}` : `at least $${amount.toFixed(2)}`;
}

export const ACTION_LABELS: Record<string, string> = {
  Notify: 'Notification',
  UpdateKnowledge: 'Knowledge update',
};

export const PORTAL_URL = '/csp/sys/UtilHome.csp';
