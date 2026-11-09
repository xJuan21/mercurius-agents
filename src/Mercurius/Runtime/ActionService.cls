/// Proposes, approves and rejects agent actions. Every check runs again at approval time.
Class Mercurius.Runtime.ActionService Extends %RegisteredObject
{

/// Proposals expire after this many seconds.
Parameter LIFETIME = 86400;

ClassMethod Propose(pAgentName As %String, pExecutionId As %String, pActionType As %String, pPayload As %DynamicObject, pSummary As %String, Output pProposalId As %Integer) As %Status
{
    Set Proposal = ##class(Mercurius.Model.ActionProposal).%New()
    Set Proposal.AgentName = pAgentName
    Set Proposal.ExecutionId = pExecutionId
    Set Proposal.ActionType = pActionType
    Set Proposal.Payload = pPayload.%ToJSON()
    Set Proposal.Summary = pSummary
    Set Proposal.ExpiresAt = $SYSTEM.SQL.Functions.DATEADD("ss", ..#LIFETIME, $HOROLOG)
    Set SC = Proposal.%Save()
    Set pProposalId = Proposal.%Id()
    Return SC
}

/// The note must belong to the agent. Its current content is saved, so approval can detect a change.
ClassMethod ProposeKnowledgeUpdate(pAgentName As %String, pExecutionId As %String, pNodeId As %Integer, pNewContent As %String, pReason As %String) As %Status
{
    Set SC = ##class(Mercurius.Runtime.KnowledgeService).CheckOwner(pAgentName, pNodeId, pNodeId)
    Return:($$$ISERR(SC)) SC
    Set Node = ##class(Mercurius.Model.KnowledgeNode).%OpenId(pNodeId)
    Set Payload = {"nodeId":(+pNodeId), "title":(Node.Title), "before":(Node.Content), "after":($EXTRACT(pNewContent, 1, 4000)), "reason":($EXTRACT(pReason, 1, 500))}
    Return ..Propose(pAgentName, pExecutionId, "UpdateKnowledge", Payload, "Update """_Node.Title_""": "_$EXTRACT(pReason, 1, 150), .ProposalId)
}

/// The code must pass the static checks and compile in a throwaway namespace. Nothing runs until approval.
ClassMethod ProposeTests(pAgentName As %String, pExecutionId As %String, pClassName As %String, pTestCode As %String, pReason As %String) As %Status
{
    Set SC = ##class(Mercurius.Runtime.TestSandbox).Run(pClassName, pTestCode, 0, .Summary)
    Return:($$$ISERR(SC)) SC
    Return:(Summary.problem '= "") $$$ERROR($$$GeneralError, Summary.problem)
    Set Payload = {"className":(pClassName), "code":(pTestCode), "reason":($EXTRACT(pReason, 1, 500))}
    Return ..Propose(pAgentName, pExecutionId, "RunTests", Payload, "Run tests for "_pClassName_": "_$EXTRACT(pReason, 1, 150), .ProposalId)
}

/// Returns a problem message, or an empty string when the decision was applied.
ClassMethod Decide(pId As %String, pStatus As %String, pUser As %String) As %String
{
    Do ..ExpireOld()
    Set Proposal = ##class(Mercurius.Model.ActionProposal).%OpenId(pId, 4)
    Return:('$ISOBJECT(Proposal)) "Proposal not found."
    Return:(Proposal.Status '= "Proposed") "This proposal is already "_$ZCONVERT(Proposal.Status, "L")_"."
    Set Proposal.DecidedBy = pUser
    Set Proposal.DecidedAt = $ZDATETIME($HOROLOG, 3)

    If (pStatus = "Rejected") {
        Set Proposal.Status = "Rejected"
        Do Proposal.%Save()
        Return ""
    }

    Set Tool = $CASE(Proposal.ActionType, "Notify":"ProposeNotification", "RunTests":"ProposeTests", :"ProposeKnowledgeUpdate")
    If ('##class(Mercurius.Model.AgentToolPermission).AgentToolIndexExists(Proposal.AgentName, Tool)) {
        Return "The agent no longer has permission for this action."
    }

    Set Request = ##class(Mercurius.Interop.Msg.ActionRequest).%New()
    Set Request.ProposalId = Proposal.%Id()
    Set Request.ActionType = Proposal.ActionType
    Set Request.AgentName = Proposal.AgentName
    Set Request.Payload = Proposal.Payload
    Set Request.ApprovedBy = pUser
    Set SC = ##class(Ens.Director).CreateBusinessService("ActionIngress", .Service)
    Return:($$$ISERR(SC)) "The production isn't running."
    Set SC = Service.ProcessInput(Request, .Response)

    Set Proposal.Status = $SELECT($$$ISOK(SC) && Response.Done:"Executed", 1:"Failed")
    Set Proposal.Result = $SELECT($$$ISERR(SC):$SYSTEM.Status.GetErrorText(SC), 1:Response.Result)
    Do Proposal.%Save()
    Return:(Proposal.Status = "Failed") "The action failed: "_Proposal.Result
    Return ""
}

ClassMethod ExpireOld()
{
    Set Now = $ZDATETIME($HOROLOG, 3)
    &sql(UPDATE Mercurius_Model.ActionProposal SET Status = 'Expired' WHERE Status = 'Proposed' AND ExpiresAt < :Now)
}

}
