/// Grants one tool to one agent. A tool isn't callable merely because it exists.
Class Mercurius.Model.AgentToolPermission Extends %Persistent
{

Property AgentName As %String(MAXLEN = 100) [ Required ];

Property ToolKey As %String(MAXLEN = 100) [ Required ];

Index AgentToolIndex On (AgentName, ToolKey) [ Unique ];

}
