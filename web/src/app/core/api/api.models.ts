/** Rows use the column names returned by the IRIS API. */
export interface Agent {
  Name: string;
  Role: string;
  Description: string;
  SystemPrompt: string;
  Tone: string;
  ProviderName: string;
  ModelName: string;
  DecisionField: string;
  AllowedDecisions: string;
  ReviewDecisions: string;
  InputType: string;
  Symbol: string;
  FallbackRules: string;
  Enabled: string | number;
  Tools: string;
}

export interface AgentInput {
  name?: string;
  role: string;
  description: string;
  instructions: string;
  tone: string;
  allowedDecisions: string;
  reviewDecisions: string;
  tools: string[];
  fallbackRules: string;
  provider: string;
  model: string;
  enabled: boolean;
}

export interface ModelOption {
  id: string;
  name: string;
  priced: boolean | number;
}

export interface ProviderModels {
  provider: string;
  models: ModelOption[];
}

export interface Tool {
  key: string;
  label: string;
  description: string;
}

export interface Execution {
  ExecutionId: string;
  AgentName: string;
  SourceType: string;
  Status: string;
  Decision: string;
  Route: string;
  StartedAt: string;
  CompletedAt: string;
  InputSummary: string;
  OutputSummary: string;
  ErrorDetails: string;
  InteropSessionId: string;
  Engine: string;
  ModelName: string;
  PromptTokens: string | number;
  CompletionTokens: string | number;
  CostUSD: string | number;
  Tools: string;
  Actions: string;
}

export interface Summary {
  Runs: string | number;
  Review: string | number;
  Failed: string | number;
  OpenConflicts: string | number;
  ToolCalls: string | number;
  PendingActions: string | number;
  RuleRuns: string | number;
  Tokens: string | number;
  CostUSD: string | number;
}

export type ProposalStatus = 'Proposed' | 'Rejected' | 'Executed' | 'Failed' | 'Expired';

export interface Proposal {
  Id: string;
  AgentName: string;
  ExecutionId: string;
  ActionType: 'Notify' | 'UpdateKnowledge' | 'RunTests';
  Summary: string;
  Payload: string;
  Status: ProposalStatus;
  CreatedAt: string;
  ExpiresAt: string;
  DecidedBy: string;
  DecidedAt: string;
  Result: string;
}

export interface Notification {
  AgentName: string;
  Message: string;
  Channel: string;
  ApprovedBy: string;
  CreatedAt: string;
}

export type ConflictStatus = 'Open' | 'Reviewed' | 'Dismissed' | 'Resolved';

export interface Conflict {
  Id: string;
  AgentName: string;
  Status: ConflictStatus;
  Description: string;
  CreatedAt: string;
  ReviewedBy: string;
  ReviewedAt: string;
  SourceTitle: string;
  SourceContent: string;
  TargetTitle: string;
  TargetContent: string;
}

export interface KnowledgeNode {
  Id: string;
  AgentName: string;
  Title: string;
  NodeType: string;
  Content: string;
  CreatedAt: string;
}

export interface KnowledgeEdge {
  AgentName: string;
  SourceNodeId: string;
  TargetNodeId: string;
  RelationshipType: string;
}

export interface Knowledge {
  nodes: KnowledgeNode[];
  edges: KnowledgeEdge[];
}

export interface Memory {
  AgentName: string;
  MemoryType: string;
  Content: string;
  CreatedAt: string;
}
