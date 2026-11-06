/// A note, fact or document owned by one agent.
Class Mercurius.Model.KnowledgeNode Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property Title As %String(MAXLEN = 200) [ Required ];

Property Content As %String(MAXLEN = "");

Property NodeType As %String(MAXLEN = 20, VALUELIST = ",Note,Document,Project,Concept,Decision,Issue") [ InitialExpression = "Note" ];

Property Source As %String(MAXLEN = 200);

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index AgentNameIndex On AgentName;

}
