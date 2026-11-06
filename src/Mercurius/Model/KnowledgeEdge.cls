/// A relationship between two nodes owned by the same agent.
Class Mercurius.Model.KnowledgeEdge Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property SourceNodeId As %Integer [ Required ];

Property TargetNodeId As %Integer [ Required ];

Property RelationshipType As %String(MAXLEN = 20, VALUELIST = ",RELATES_TO,DEPENDS_ON,CONTRADICTS,REFERENCES,BELONGS_TO") [ Required ];

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index AgentNameIndex On AgentName;

}
