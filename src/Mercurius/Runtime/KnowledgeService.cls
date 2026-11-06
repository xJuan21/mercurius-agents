/// Agent-scoped knowledge and memory. Every method takes the owner from the runtime.
Class Mercurius.Runtime.KnowledgeService Extends %RegisteredObject
{

/// Basic text search over the agent's own nodes. Returns a JSON array, best matches first.
ClassMethod Search(pAgentName As %String, pQuery As %String) As %DynamicArray
{
    Set Words = $ZCONVERT($TRANSLATE(pQuery, ".,;:!?()", "        "), "L")
    Set Statement = ##class(%SQL.Statement).%ExecDirect(, "SELECT ID, Title, Content FROM Mercurius_Model.KnowledgeNode WHERE AgentName = ?", pAgentName)
    While (Statement.%Next()) {
        Set Text = $ZCONVERT(Statement.Title_" "_Statement.Content, "L")
        Set Score = 0
        For Index = 1:1:$LENGTH(Words, " ") {
            Set Word = $PIECE(Words, " ", Index)
            Set:(($LENGTH(Word) > 3) && (Text [ Word)) Score = Score + 1
        }
        Set:(Score > 0) Hits(-Score, Statement.ID) = $LISTBUILD(Statement.Title, Statement.Content)
    }

    Set Results = []
    Set Score = ""
    For {
        Set Score = $ORDER(Hits(Score))
        Quit:((Score = "") || (Results.%Size() >= 5))
        Set NodeId = ""
        For {
            Set NodeId = $ORDER(Hits(Score, NodeId), 1, Hit)
            Quit:((NodeId = "") || (Results.%Size() >= 5))
            Do Results.%Push({"id":(+NodeId), "title":($LIST(Hit, 1)), "content":($LIST(Hit, 2))})
        }
    }
    Return Results
}

ClassMethod SaveNode(pAgentName As %String, pTitle As %String, pContent As %String, pNodeType As %String, Output pNodeId As %Integer) As %Status
{
    Set Node = ##class(Mercurius.Model.KnowledgeNode).%New()
    Set Node.AgentName = pAgentName
    Set Node.Title = pTitle
    Set Node.Content = pContent
    Set:(pNodeType '= "") Node.NodeType = pNodeType
    Set SC = Node.%Save()
    Set pNodeId = Node.%Id()
    Return SC
}

ClassMethod Relate(pAgentName As %String, pSourceId As %Integer, pTargetId As %Integer, pType As %String) As %Status
{
    Set SC = ..CheckOwner(pAgentName, pSourceId, pTargetId)
    Return:($$$ISERR(SC)) SC
    Set Edge = ##class(Mercurius.Model.KnowledgeEdge).%New()
    Set Edge.AgentName = pAgentName
    Set Edge.SourceNodeId = pSourceId
    Set Edge.TargetNodeId = pTargetId
    Set Edge.RelationshipType = pType
    Return Edge.%Save()
}

ClassMethod FlagConflict(pAgentName As %String, pSourceId As %Integer, pTargetId As %Integer, pDescription As %String) As %Status
{
    Set SC = ..CheckOwner(pAgentName, pSourceId, pTargetId)
    Return:($$$ISERR(SC)) SC
    Set Conflict = ##class(Mercurius.Model.KnowledgeConflict).%New()
    Set Conflict.AgentName = pAgentName
    Set Conflict.SourceNodeId = pSourceId
    Set Conflict.TargetNodeId = pTargetId
    Set Conflict.Description = pDescription
    Return Conflict.%Save()
}

/// Both nodes must exist and belong to the agent.
ClassMethod CheckOwner(pAgentName As %String, pSourceId As %Integer, pTargetId As %Integer) As %Status
{
    For NodeId = pSourceId, pTargetId {
        Set Node = ##class(Mercurius.Model.KnowledgeNode).%OpenId(NodeId)
        If ('$ISOBJECT(Node) || (Node.AgentName '= pAgentName)) {
            Return $$$ERROR($$$GeneralError, "Node "_NodeId_" does not belong to agent "_pAgentName)
        }
    }
    Return $$$OK
}

ClassMethod SaveMemory(pAgentName As %String, pContent As %String, pMemoryType As %String = "Note") As %Status
{
    Set Memory = ##class(Mercurius.Model.AgentMemory).%New()
    Set Memory.AgentName = pAgentName
    Set Memory.Content = pContent
    Set Memory.MemoryType = pMemoryType
    Return Memory.%Save()
}

/// Returns the agent's own memories as a JSON array, newest first.
ClassMethod GetMemories(pAgentName As %String) As %DynamicArray
{
    Set Results = []
    Set Statement = ##class(%SQL.Statement).%ExecDirect(, "SELECT TOP 20 Content FROM Mercurius_Model.AgentMemory WHERE AgentName = ? ORDER BY ID DESC", pAgentName)
    While (Statement.%Next()) {
        Do Results.%Push(Statement.Content)
    }
    Return Results
}

}
