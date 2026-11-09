/// Runs the acceptance checks under %UnitTest, so zpm "mercurius-agents test" reports them.
Class Mercurius.Test.Unit.Acceptance Extends %UnitTest.TestCase
{

Method TestAcceptance()
{
    Do $$$AssertTrue(##class(Mercurius.Test.Acceptance).Run(), "All acceptance checks pass")
    Do ##class(Mercurius.Setup).ResetKnowledge()
}

Method TestCodeChecks()
{
    Do $$$AssertEquals(##class(Mercurius.Runtime.CodeCheck).Syntax("Set Total = Total + 1"), "No syntax errors.")
    Do $$$AssertTrue(##class(Mercurius.Runtime.CodeCheck).Syntax("Set Total = ") [ "Syntax error", "A syntax error is reported")
    Do $$$AssertTrue(##class(Mercurius.Runtime.CodeCheck).SQL("DELETE FROM Mercurius_Model.AgentExecution") [ "Refused", "Only SELECT is allowed")
    Do $$$AssertTrue(##class(Mercurius.Runtime.CodeCheck).SQL("SELECT Name FROM Mercurius_Model.AgentDefinition") [ "Valid", "A valid SELECT is accepted")
    Do $$$AssertTrue(##class(Mercurius.Runtime.CodeCheck).Describe("Security") [ "Only these schemas", "Other schemas can't be described")
}


/// Compiles only: running tests here would nest one unit test run inside another.
Method TestSandbox()
{
    Set Sandbox = "Mercurius.Runtime.TestSandbox"
    Set Target = "Mercurius.Demo.OrderValidator"
    Set Header = "Class Test."_Target_" Extends %UnitTest.TestCase"_$CHAR(10)_"{"_$CHAR(10)
    Set Good = Header_"Method TestNoOrder()"_$CHAR(10)_"{"_$CHAR(10)_"    Do $$$AssertEquals(##class("_Target_").Validate(""""), ""No order."")"_$CHAR(10)_"}"_$CHAR(10)_"}"
    Do $$$AssertStatusOK($CLASSMETHOD(Sandbox, "Run", Target, Good, 0, .Summary))
    Do $$$AssertEquals(Summary.problem, "", "Valid tests compile in the sandbox")
    Do $$$AssertNotTrue(##class(%Dictionary.ClassDefinition).%ExistsId("Test."_Target), "Test code never reaches this namespace")
    Do $CLASSMETHOD(Sandbox, "Run", Target, $REPLACE(Good, "Do $$$AssertEquals", "Do $$$AssertEquals("), 0, .Summary)
    Do $$$AssertTrue(Summary.problem [ "Doesn't compile", "Compile errors are reported")
    For Unsafe = "Kill ^Mercurius", "Set $NAMESPACE = ""%SYS""", "Do $ZF(-1, ""ls"")", "Xecute ""Halt""", "Set X = ^|""USER""|Data" {
        Do $CLASSMETHOD(Sandbox, "Run", Target, $REPLACE(Good, "    Do $$$AssertEquals", "    "_Unsafe_$CHAR(10)_"    Do $$$AssertEquals"), 0, .Summary)
        Do $$$AssertTrue(Summary.problem [ "Refused", "Refused: "_Unsafe)
    }
    Do $$$AssertTrue($CLASSMETHOD(Sandbox, "Describe", "Mercurius.Runtime.Settings") [ "Only classes", "Classes outside the allowed packages can't be read")
}

}
