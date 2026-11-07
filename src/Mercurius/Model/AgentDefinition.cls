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

Property Enabled As %Boolean [ InitialExpression = 1 ];

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index NameIndex On Name [ Unique ];

}
