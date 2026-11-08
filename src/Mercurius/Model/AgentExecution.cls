/// One agent run, linked to its Interoperability session.
Class Mercurius.Model.AgentExecution Extends %Persistent
{

Property ExecutionId As %String(MAXLEN = 50) [ Required ];

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property SourceType As %String(MAXLEN = 50);

Property Status As %String(MAXLEN = 20, VALUELIST = ",Running,Completed,Failed");

Property Decision As %String(MAXLEN = 100);

Property Route As %String(MAXLEN = 20, VALUELIST = ",Accepted,Review");

/// AI for a model decision, Rules when the fallback decided.
Property Engine As %String(MAXLEN = 10, VALUELIST = ",AI,Rules");

Property ModelName As %String(MAXLEN = 100);

/// Tokens reported by AI Hub for the final model call of the run.
Property PromptTokens As %Integer;

Property CompletionTokens As %Integer;

/// Estimated from list prices; a lower bound, because tool loops make more calls.
Property CostUSD As %Numeric(SCALE = 6);

Property StartedAt As %TimeStamp;

Property CompletedAt As %TimeStamp;

Property InputSummary As %String(MAXLEN = 500);

Property OutputSummary As %String(MAXLEN = "");

Property ErrorDetails As %String(MAXLEN = 2000);

Property InteropSessionId As %Integer;

Index ExecutionIdIndex On ExecutionId [ Unique ];

Index AgentNameIndex On AgentName;

}
