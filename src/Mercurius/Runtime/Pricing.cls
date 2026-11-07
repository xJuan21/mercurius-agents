/// Estimated cost from list prices per million tokens, in US dollars. Prices change, so treat
/// the result as an estimate, and unknown models as having no estimate.
Class Mercurius.Runtime.Pricing Extends %RegisteredObject
{

ClassMethod Estimate(pModel As %String, pPromptTokens As %Integer, pCompletionTokens As %Integer) As %String
{
    Set Prices("gpt-4.1-mini") = $LISTBUILD(0.40, 1.60)
    Set Prices("gpt-4.1") = $LISTBUILD(2.00, 8.00)
    Set Prices("gpt-4o-mini") = $LISTBUILD(0.15, 0.60)
    Set Prices("gpt-4o") = $LISTBUILD(2.50, 10.00)
    Return:(('$DATA(Prices(pModel), Price)) || (pPromptTokens = "")) ""
    Return $NORMALIZE(((pPromptTokens * $LIST(Price, 1)) + (pCompletionTokens * $LIST(Price, 2))) / 1000000, 6)
}

}
