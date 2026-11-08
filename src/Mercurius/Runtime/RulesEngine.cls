/// The fallback when the AI can't answer. Each rule is one line: phrase => decision.
/// The first phrase found in the input, ignoring case, decides.
Class Mercurius.Runtime.RulesEngine Extends %RegisteredObject
{

/// Returns the decision, or an empty string when no rule matches. pRule gets the matched rule.
ClassMethod Evaluate(pDefinition As Mercurius.Model.AgentDefinition, pInput As %String, Output pRule As %String) As %String
{
    Set pRule = ""
    Set Text = $ZCONVERT(pInput, "L")
    Set Rules = $TRANSLATE(pDefinition.FallbackRules, $CHAR(13), "")
    For Index = 1:1:$LENGTH(Rules, $CHAR(10)) {
        Set Line = $PIECE(Rules, $CHAR(10), Index)
        Continue:(Line '[ "=>")
        Set Phrase = $ZCONVERT($ZSTRIP($PIECE(Line, "=>", 1), "<>W"), "L")
        Set Decision = $ZSTRIP($PIECE(Line, "=>", 2), "<>W")
        If ((Phrase '= "") && (Text [ Phrase)) {
            Set pRule = Line
            Return Decision
        }
    }
    Return ""
}

/// Returns an error message, or an empty string when every line is valid.
ClassMethod Validate(pRules As %String, pAllowed As %String) As %String
{
    Set Rules = $TRANSLATE(pRules, $CHAR(13), "")
    Return:($LENGTH(Rules) > 4000) "Fallback rules are limited to 4000 characters."
    For Index = 1:1:$LENGTH(Rules, $CHAR(10)) {
        Set Line = $ZSTRIP($PIECE(Rules, $CHAR(10), Index), "<>W")
        Continue:(Line = "")
        Return:(Line '[ "=>") "Each fallback rule needs the form: phrase => decision"
        Set Decision = $ZSTRIP($PIECE(Line, "=>", 2), "<>W")
        Return:('##class(Mercurius.Runtime.DecisionPolicy).InList(Decision, pAllowed)) "Fallback rule uses a decision that isn't allowed: "_Decision
    }
    Return ""
}

}
