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

    Set SC = $CLASSMETHOD(Service, "SaveMemory", "Documenter", "acceptance-memory-marker")
    Set Other = $CLASSMETHOD(Service, "GetMemories", "Sentinel").%ToJSON()
    Set Own = $CLASSMETHOD(Service, "GetMemories", "Documenter").%ToJSON()
    Set Passed = ..Check("Test 4: memory stays with its agent", (Own [ "acceptance-memory-marker") && '(Other [ "acceptance-memory-marker")) && Passed

    Set Search = $CLASSMETHOD(Service, "Search", "Sentinel", "tailscale funnel webhook").%ToJSON()
    Set Passed = ..Check("Test 4b: search stays with its agent", Search = "[]") && Passed

    Do $CLASSMETHOD(Service, "SaveNode", "Documenter", "Documenter node", "x", "Note", .DocumenterId)
    Do $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Sentinel node", "x", "Note", .SentinelId)
    Set Cross = $CLASSMETHOD(Service, "Relate", "Documenter", DocumenterId, SentinelId, "RELATES_TO")
    Set Passed = ..Check("Test 5: cross-agent relationship rejected", $$$ISERR(Cross)) && Passed

    Set Policy = "Mercurius.Runtime.DecisionPolicy"
    Do $CLASSMETHOD(Policy, "Evaluate", "Documenter", "{""decision"":""approve-everything""}", .Decision, .NeedsReview)
    Set Passed = ..Check("Invalid decision goes to review", NeedsReview && (Decision = "")) && Passed
    Do $CLASSMETHOD(Policy, "Evaluate", "Documenter", "not json", .Decision, .NeedsReview)
    Set Passed = ..Check("Malformed reply goes to review", NeedsReview) && Passed

    Set Bad = ##class(Mercurius.Runtime.AgentService).Validate({"name":"bad name!","role":"x","instructions":"y","allowedDecisions":"a"}, 1)
    Set Passed = ..Check("Invalid agent name rejected", Bad '= "") && Passed
    Set Bad = ##class(Mercurius.Runtime.AgentService).Validate({"name":"Atlas","role":"x","instructions":"y","allowedDecisions":"a,b","reviewDecisions":"c"}, 1)
    Set Passed = ..Check("Review value must be an allowed decision", Bad '= "") && Passed
    Set Bad = ##class(Mercurius.Runtime.AgentService).Validate({"name":"Atlas","role":"x","instructions":"y","allowedDecisions":"a","tools":["RunShell"]}, 1)
    Set Passed = ..Check("Unknown tool rejected", Bad '= "") && Passed

    Set Definition = ##class(Mercurius.Model.AgentDefinition).%New()
    Set Definition.FallbackRules = "instead of => conflict"_$CHAR(10)_"also => related"
    Set Decision = ##class(Mercurius.Runtime.RulesEngine).Evaluate(Definition, "We use Cloudflare INSTEAD OF Funnel", .Rule)
    Set None = ##class(Mercurius.Runtime.RulesEngine).Evaluate(Definition, "Lunch on Friday", .Rule)
    Set Passed = ..Check("Fallback rules decide when they match, and only then", (Decision = "conflict") && (None = "")) && Passed
    Set Problem = ##class(Mercurius.Runtime.RulesEngine).Validate("anything => approve", "related,conflict,none")
    Set Passed = ..Check("Fallback rule with an unknown decision is rejected", Problem '= "") && Passed

    Do $CLASSMETHOD(Service, "SaveNode", "Sentinel", "Sentinel private", "x", "Note", .OtherId)
    Set Foreign = ##class(Mercurius.Runtime.ActionService).ProposeKnowledgeUpdate("Documenter", "", OtherId, "new", "test")
    Set Passed = ..Check("An agent can't propose changes to another agent's note", $$$ISERR(Foreign)) && Passed
    Do ##class(Mercurius.Runtime.ActionService).Propose("Sentinel", "", "Notify", {"message":"test"}, "test", .ProposalId)
    Set First = ##class(Mercurius.Runtime.ActionService).Decide(ProposalId, "Rejected", "tester")
    Set Second = ##class(Mercurius.Runtime.ActionService).Decide(ProposalId, "Rejected", "tester")
    Set Passed = ..Check("A decided proposal can't be decided again", (First = "") && (Second '= "")) && Passed

    Set Redacted = ##class(Mercurius.Runtime.AgentExecutor).Redact("Incorrect API key provided: sk-proj-abc123DEF456")
    Set Passed = ..Check("API keys are removed from stored errors", '(Redacted [ "abc123DEF456") && (Redacted [ "[REDACTED]")) && Passed

    Write !, $SELECT(Passed:"ALL PASSED", 1:"FAILURES"), !
    Return Passed
}

ClassMethod Check(pName As %String, pResult As %Boolean) As %Boolean
{
    Write $SELECT(pResult:"PASS ", 1:"FAIL "), pName, !
    Return pResult
}

}
