/// Measures the Tester: how many deliberate bugs in the sample class its tests catch.
/// Do ##class(Mercurius.Test.Mutation).Run(3)
Class Mercurius.Test.Mutation Extends %RegisteredObject
{

Parameter TARGET = "Mercurius.Demo.OrderValidator";

/// Each mutant replaces one piece of the source: original => mutated.
ClassMethod Mutants() As %DynamicArray
{
    Return [
        ["(Item.quantity < 1)", "(Item.quantity < 0)"],
        ["(Item.price < 0)", "(Item.price < -1)"],
        ["(..Total(pOrder) > ..#LIMIT)", "(..Total(pOrder) >= ..#LIMIT)"],
        ["Return:(pOrder.id = \"\") \"Missing id.\"", "Return:(0) \"Missing id.\""],
        ["Total + (Item.quantity * Item.price)", "Total + Item.price"],
        ["pTotal >= 1000", "pTotal > 1000"],
        ["pTotal * 0.9", "pTotal * 0.8"],
        ["Parameter LIMIT = 10000;", "Parameter LIMIT = 100000;"]
    ]
}

/// Asks the Tester for tests pRuns times and prints how many mutants each set catches.
ClassMethod Run(pRuns As %Integer = 1) As %Status
{
    Set SC = ##class(%Compiler.UDL.TextServices).GetTextAsString($NAMESPACE, ..#TARGET, .Original)
    Return:($$$ISERR(SC)) SC
    For RunIndex = 1:1:pRuns {
        Set ExecutionId = "mutation-"_$ZDATETIME($HOROLOG, 8)_"-"_RunIndex
        Set SC = ##class(Mercurius.Runtime.AgentExecutor).Execute("Tester", "Write unit tests for "_..#TARGET, .Reply, ExecutionId, .Usage)
        Return:($$$ISERR(SC)) SC
        &sql(SELECT TOP 1 Payload INTO :Payload FROM Mercurius_Model.ActionProposal WHERE ExecutionId = :ExecutionId ORDER BY ID DESC)
        If (SQLCODE '= 0) {
            Write "Run ", RunIndex, ": no tests proposed. ", Reply, !
            Continue
        }
        Set Code = ##class(%DynamicObject).%FromJSON(Payload).code
        Set SC = ##class(Mercurius.Runtime.TestSandbox).Run(..#TARGET, Code, 1, .Summary)
        Return:($$$ISERR(SC)) SC
        Write "Run ", RunIndex, ": ", Summary.passed, " tests pass on the original"
        If (Summary.failed > 0) {
            Write ", ", Summary.failed, " fail: ", Summary.failures.%ToJSON(), !
            Continue
        }
        Set Caught = 0
        Set Iterator = ..Mutants().%GetIterator()
        While (Iterator.%GetNext(.Index, .Mutant)) {
            Set Source = $REPLACE(Original, Mutant.%Get(0), Mutant.%Get(1))
            Set SC = ##class(Mercurius.Runtime.TestSandbox).Run(..#TARGET, Code, 1, .Result, Source)
            Return:($$$ISERR(SC)) SC
            If ((Result.failed > 0) || (Result.problem '= "")) {
                Set Caught = Caught + 1
            } Else {
                Write !, "  missed: ", Mutant.%Get(1)
            }
        }
        Write !, "  caught ", Caught, " of ", ..Mutants().%Size(), " mutants", !
    }
    Return $$$OK
}

}
