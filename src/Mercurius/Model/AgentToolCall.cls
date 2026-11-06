/// Audit record of one tool call or denial.
Class Mercurius.Model.AgentToolCall Extends %Persistent
{

Property ExecutionId As %String(MAXLEN = 50);

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property ToolKey As %String(MAXLEN = 100);

Property Arguments As %String(MAXLEN = 2000);

Property Outcome As %String(MAXLEN = 20, VALUELIST = ",Completed,Failed,Denied");

Property CreatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)} ];

Index ExecutionIdIndex On ExecutionId;

}
