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

}
