/// An action an agent proposed. It runs only after a person approves it.
Class Mercurius.Model.ActionProposal Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property ExecutionId As %String(MAXLEN = 50);

Property ActionType As %String(MAXLEN = 30, VALUELIST = ",Notify,UpdateKnowledge,RunTests") [ Required ];

/// JSON with what the action needs, captured when it was proposed.
Property Payload As %String(MAXLEN = "");

Property Summary As %String(MAXLEN = 500);

Property Status As %String(MAXLEN = 20, VALUELIST = ",Proposed,Rejected,Executed,Failed,Expired") [ InitialExpression = "Proposed" ];

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Property ExpiresAt As %TimeStamp;

Property DecidedBy As %String(MAXLEN = 128);

Property DecidedAt As %TimeStamp;

Property Result As %String(MAXLEN = 2000);

Index AgentNameIndex On AgentName;

Index StatusIndex On Status;

}
