/// Tools for one agent. AgentName is set by the runtime, never by the LLM.
Class Mercurius.Tools.Knowledge Extends %AI.ToolSet
{

XData Definition [ MimeType = application/xml ]
{
<ToolSet Name="Knowledge">
  <Tool Name="SearchKnowledge" Method="SearchKnowledge"/>
  <Tool Name="SaveKnowledge" Method="SaveKnowledge"/>
  <Tool Name="CreateRelationship" Method="CreateRelationship"/>
  <Tool Name="FlagConflict" Method="FlagConflict"/>
  <Tool Name="GetAgentMemory" Method="GetAgentMemory"/>
  <Tool Name="SaveAgentMemory" Method="SaveAgentMemory"/>
  <Tool Name="ProposeNotification" Method="ProposeNotification"/>
  <Tool Name="CheckSyntax" Method="CheckSyntax"/>
  <Tool Name="DescribeSchema" Method="DescribeSchema"/>
  <Tool Name="CheckSQL" Method="CheckSQL"/>
  <Tool Name="ProposeKnowledgeUpdate" Method="ProposeKnowledgeUpdate"/>
  <Tool Name="DescribeClass" Method="DescribeClass"/>
  <Tool Name="ProposeTests" Method="ProposeTests"/>
</ToolSet>
}

Property AgentName As %String(MAXLEN = 100);

Property ExecutionId As %String(MAXLEN = 50);

/// Searches your private knowledge. Returns matching nodes with their ids.
Method SearchKnowledge(pQuery As %String(DESCRIPTION = "Words to search for")) As %String
{
    Return ##class(Mercurius.Runtime.KnowledgeService).Search(..AgentName, pQuery).%ToJSON()
}

/// Saves a new item in your private knowledge and returns its id.
Method SaveKnowledge(pTitle As %String(DESCRIPTION = "Short title"), pContent As %String(DESCRIPTION = "Full text"), pNodeType As %String(DESCRIPTION = "One of Note, Document, Project, Concept, Decision, Issue")) As %String
{
    Set SC = ##class(Mercurius.Runtime.KnowledgeService).SaveNode(..AgentName, pTitle, pContent, pNodeType, .NodeId)
    Return $SELECT($$$ISOK(SC):"Saved node "_NodeId, 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Links two of your nodes.
Method CreateRelationship(pSourceId As %Integer(DESCRIPTION = "Source node id"), pTargetId As %Integer(DESCRIPTION = "Target node id"), pType As %String(DESCRIPTION = "One of RELATES_TO, DEPENDS_ON, CONTRADICTS, REFERENCES, BELONGS_TO")) As %String
{
    Set SC = ##class(Mercurius.Runtime.KnowledgeService).Relate(..AgentName, pSourceId, pTargetId, pType)
    Return $SELECT($$$ISOK(SC):"Relationship created", 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Records a potential contradiction between two of your nodes.
Method FlagConflict(pSourceId As %Integer(DESCRIPTION = "Newer node id"), pTargetId As %Integer(DESCRIPTION = "Older node id"), pDescription As %String(DESCRIPTION = "What appears to conflict")) As %String
{
    Set SC = ##class(Mercurius.Runtime.KnowledgeService).FlagConflict(..AgentName, pSourceId, pTargetId, pDescription)
    Return $SELECT($$$ISOK(SC):"Conflict recorded for review", 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Returns your private memories.
Method GetAgentMemory() As %String
{
    Return ##class(Mercurius.Runtime.KnowledgeService).GetMemories(..AgentName).%ToJSON()
}

/// Stores a private memory.
Method SaveAgentMemory(pContent As %String(DESCRIPTION = "What to remember")) As %String
{
    Set SC = ##class(Mercurius.Runtime.KnowledgeService).SaveMemory(..AgentName, pContent)
    Return $SELECT($$$ISOK(SC):"Memory saved", 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Proposes a message for a person. Nothing is sent until someone approves it.
Method ProposeNotification(pMessage As %String(DESCRIPTION = "Short message for the person, under 500 characters")) As %String
{
    Set Payload = {"message":($EXTRACT(pMessage, 1, 500))}
    Set SC = ##class(Mercurius.Runtime.ActionService).Propose(..AgentName, ..ExecutionId, "Notify", Payload, $EXTRACT(pMessage, 1, 200), .ProposalId)
    Return $SELECT($$$ISOK(SC):"Notification proposed for approval", 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Proposes new content for one of your notes. Nothing changes until someone approves it.
Method ProposeKnowledgeUpdate(pNodeId As %Integer(DESCRIPTION = "Id of the note to update"), pNewContent As %String(DESCRIPTION = "The full new content of that note"), pReason As %String(DESCRIPTION = "Why it should change")) As %String
{
    Set SC = ##class(Mercurius.Runtime.ActionService).ProposeKnowledgeUpdate(..AgentName, ..ExecutionId, pNodeId, pNewContent, pReason)
    Return $SELECT($$$ISOK(SC):"Update proposed for approval", 1:$SYSTEM.Status.GetErrorText(SC))
}

/// Compiles ObjectScript lines without running them and reports any syntax error.
Method CheckSyntax(pCode As %String(DESCRIPTION = "ObjectScript lines to check")) As %String
{
    Return ##class(Mercurius.Runtime.CodeCheck).Syntax(pCode)
}

/// Lists the tables and columns of a schema you may query.
Method DescribeSchema(pSchema As %String(DESCRIPTION = "Schema name, such as Mercurius_Model")) As %String
{
    Return ##class(Mercurius.Runtime.CodeCheck).Describe(pSchema)
}

/// Checks one SELECT statement without running it.
Method CheckSQL(pQuery As %String(DESCRIPTION = "One SELECT statement")) As %String
{
    Return ##class(Mercurius.Runtime.CodeCheck).SQL(pQuery)
}

/// Returns the source of a class you may test.
Method DescribeClass(pClassName As %String(DESCRIPTION = "Full class name, such as Mercurius.Demo.OrderValidator")) As %String
{
    Return ##class(Mercurius.Runtime.TestSandbox).Describe(pClassName)
}

/// Compiles a %UnitTest class for one class and proposes running it. Nothing runs until someone approves it.
Method ProposeTests(pClassName As %String(DESCRIPTION = "The class under test"), pTestCode As %String(DESCRIPTION = "The full test class source"), pReason As %String(DESCRIPTION = "What the tests cover")) As %String
{
    Set SC = ##class(Mercurius.Runtime.ActionService).ProposeTests(..AgentName, ..ExecutionId, pClassName, pTestCode, pReason)
    Return $SELECT($$$ISOK(SC):"Tests compiled and proposed for approval", 1:$SYSTEM.Status.GetErrorText(SC))
}

}
