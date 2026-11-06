/// Deterministic checks on an agent's reply. The LLM proposes; this decides the route.
Class Mercurius.Runtime.DecisionPolicy Extends %RegisteredObject
{

/// Returns the validated decision and whether it needs review. Anything invalid goes to review.
ClassMethod Evaluate(pAgentName As %String, pReply As %String, Output pDecision As %String, Output pNeedsReview As %Boolean) As %Status
{
    Set pDecision = ""
    Set pNeedsReview = 1
    Set SC = $$$OK
    Try {
        Set Definition = ##class(Mercurius.Model.AgentDefinition).NameIndexOpen(pAgentName, , .SC)
        $$$ThrowOnError(SC)
        Set Value = ..ReadField(pReply, Definition.DecisionField)
        Quit:(Value = "")
        Quit:('..InList(Value, Definition.AllowedDecisions))
        Set pDecision = Value
        Set pNeedsReview = ..InList(Value, Definition.ReviewDecisions)
    } Catch Ex {
        Set SC = Ex.AsStatus()
    }
    Return SC
}

/// Reads a field from the JSON object in the reply, tolerating text around it.
ClassMethod ReadField(pReply As %String, pField As %String) As %String
{
    Set Value = ""
    Try {
        Set Start = $FIND(pReply, "{")
        Quit:(Start = 0)
        Set Pieces = $LENGTH(pReply, "}")
        Quit:(Pieces < 2)
        Set Body = $PIECE(pReply, "}", 1, Pieces - 1)_"}"
        Set Parsed = ##class(%DynamicObject).%FromJSON($EXTRACT(Body, Start - 1, *))
        Set Value = Parsed.%Get(pField)
    } Catch {
        Set Value = ""
    }
    Return Value
}

ClassMethod InList(pValue As %String, pList As %String) As %Boolean
{
    Return ($LISTFIND($LISTFROMSTRING(pList, ","), pValue) > 0)
}

}
