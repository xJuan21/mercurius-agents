/// A potential contradiction found by an agent. An AI finding, not a fact.
Class Mercurius.Model.KnowledgeConflict Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property SourceNodeId As %Integer [ Required ];

Property TargetNodeId As %Integer [ Required ];

Property Description As %String(MAXLEN = 2000);

Property Status As %String(MAXLEN = 20, VALUELIST = ",Open,Reviewed,Dismissed,Resolved") [ InitialExpression = "Open" ];

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Property ReviewedBy As %String(MAXLEN = 128);

Property ReviewedAt As %TimeStamp;

Index AgentNameIndex On AgentName;

}
