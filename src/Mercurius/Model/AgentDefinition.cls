/// A configurable agent. Agents are records, not generated classes.
Class Mercurius.Model.AgentDefinition Extends %Persistent
{

Property Name As %String(MAXLEN = 100) [ Required ];

Property Role As %String(MAXLEN = 200);

Property Description As %String(MAXLEN = 1000);

Property SystemPrompt As %String(MAXLEN = "") [ Required ];

Property Tone As %String(MAXLEN = 200);

Property ProviderName As %String(MAXLEN = 50) [ InitialExpression = "openai", Required ];

Property ModelName As %String(MAXLEN = 100) [ InitialExpression = "gpt-4.1-mini", Required ];

/// JSON field in the agent's reply that holds its decision.
Property DecisionField As %String(MAXLEN = 50) [ InitialExpression = "decision", Required ];

/// Comma-separated values the decision may take.
Property AllowedDecisions As %String(MAXLEN = 500) [ Required ];

/// Comma-separated decisions that a person must review.
Property ReviewDecisions As %String(MAXLEN = 500);

/// Document inputs are saved as knowledge before the agent runs.
Property InputType As %String(MAXLEN = 20, VALUELIST = ",Document,Event") [ InitialExpression = "Event" ];

/// Icon key used by the web UI.
Property Symbol As %String(MAXLEN = 20) [ InitialExpression = "agents" ];

/// Used when the AI can't answer: one rule per line, written as phrase => decision.
Property FallbackRules As %String(MAXLEN = 4000);

Property Enabled As %Boolean [ InitialExpression = 1 ];

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index NameIndex On Name [ Unique ];

}
