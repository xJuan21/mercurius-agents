/// Private persistent memory for one agent.
Class Mercurius.Model.AgentMemory Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property MemoryType As %String(MAXLEN = 50);

Property Content As %String(MAXLEN = "") [ Required ];

Property Source As %String(MAXLEN = 200);

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index AgentNameIndex On AgentName;

}
