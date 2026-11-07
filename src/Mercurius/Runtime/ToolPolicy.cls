/// Backend check on every tool call, independent of the prompt and the UI.
Class Mercurius.Runtime.ToolPolicy Extends %AI.Policy.Authorization
{

Property AgentName As %String(MAXLEN = 100);

Method %CanExecute(toolref As %String, call As %DynamicObject, metadata As %DynamicObject) As %Status
{
    Return:(..IsAllowed(call.name)) $$$OK
    Return $$$ERROR($$$GeneralError, "Tool not permitted for agent "_..AgentName_": "_call.name)
}

Method %CanList(toolref As %String, metadata As %DynamicObject) As %Boolean
{
    Return ..IsAllowed(metadata.%Get("name"))
}

Method IsAllowed(pToolKey As %String) As %Boolean
{
    Return ##class(Mercurius.Model.AgentToolPermission).AgentToolIndexExists(..AgentName, pToolKey)
}

}
