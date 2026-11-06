/// Backend acceptance checks that need no LLM. Run with Do ##class(Mercurius.Test.Acceptance).Run()
Class Mercurius.Test.Acceptance Extends %RegisteredObject
{

ClassMethod Run() As %Boolean
{
    Set Service = "Mercurius.Runtime.KnowledgeService"
    Set Passed = 1

    Set Policy = ##class(Mercurius.Runtime.ToolPolicy).%New()
    Set Policy.AgentName = "Sentinel"
    Set Allowed = Policy.%CanExecute("iris:test", {"name":"SearchKnowledge"}, {})
    Set Denied = Policy.%CanExecute("iris:test", {"name":"SaveKnowledge"}, {})
    Set Passed = ..Check("Test 3: tool not granted is denied", $$$ISOK(Allowed) && $$$ISERR(Denied)) && Passed

    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Scribe", "acceptance-memory-marker")
    Set Other = $CLASSMETHOD(Service, "GetMemories", "Sentinel").%ToJSON()
    Set Own = $CLASSMETHOD(Service, "GetMemories", "Scribe").%ToJSON()
    Set Passed = ..Check("Test 4: memory stays with its agent", (Own [ "acceptance-memory-marker") && '(Other [ "acceptance-memory-marker")) && Passed

    Set Search = $CLASSMETHOD(Service, "Search", "Sentinel", "tailscale funnel webhook").%ToJSON()
    Set Passed = ..Check("Test 4b: search stays with its agent", Search = "[]") && Passed

    Do $CLASSMETHOD(Service, "SaveNode", "Scribe", "Scribe node", "x", "Note", .ScribeId)
    Do $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Sentinel node", "x", "Note", .SentinelId)
    Set Cross = $CLASSMETHOD(Service, "Relate", "Scribe", ScribeId, SentinelId, "RELATES_TO")
    Set Passed = ..Check("Test 5: cross-agent relationship rejected", $$$ISERR(Cross)) && Passed

    Set Policy = "Mercurius.Runtime.DecisionPolicy"
    Do $CLASSMETHOD(Policy, "Evaluate", "Scribe", "{""decision"":""approve-everything""}", .Decision, .NeedsReview)
    Set Passed = ..Check("Invalid decision goes to review", NeedsReview && (Decision = "")) && Passed
    Do $CLASSMETHOD(Policy, "Evaluate", "Scribe", "not json", .Decision, .NeedsReview)
    Set Passed = ..Check("Malformed reply goes to review", NeedsReview) && Passed

    Write !, $SELECT(Passed:"ALL PASSED", 1:"FAILURES"), !
    Return Passed
}

ClassMethod Check(pName As %String, pResult As %Boolean) As %Boolean
{
    Write $SELECT(pResult:"PASS ", 1:"FAIL "), pName, !
    Return pResult
}

}
