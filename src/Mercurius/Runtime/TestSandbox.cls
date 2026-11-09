/// Compiles and runs agent-written unit tests in a namespace that exists only for the run.
/// The application namespace never holds the test code.
Class Mercurius.Runtime.TestSandbox Extends %RegisteredObject
{

/// Packages the Tester may read and test.
Parameter PACKAGES = "Mercurius.Demo";

/// Text the test code may not contain, in lowercase. Approval is the main control;
/// this list stops the obvious ways out of the sandbox before anyone sees the code.
Parameter BLOCKED = "##expression,##function,#execute,xecute,$zf,$namespace,znspace,zn ,^|,^[,%sys,job ,halt,kill ^,$system,%file,%net,%stream.file,%library.file,security.,config.,sys.,objectgenerator,codemode,language = python,%sys.python,open ,use ,close ,$zu(,zsave,zremove,zload,%routine,%dictionary,%compiler,%unittest.manager";

/// Returns the source of a class the Tester may test.
ClassMethod Describe(pClassName As %String) As %String
{
    Set Problem = ..CheckTarget(pClassName)
    Return:(Problem '= "") Problem
    Set SC = ##class(%Compiler.UDL.TextServices).GetTextAsString($NAMESPACE, pClassName, .Text)
    Return:($$$ISERR(SC)) $SYSTEM.Status.GetErrorText(SC)
    Return Text
}

/// Returns a problem message, or an empty string when the class may be tested.
ClassMethod CheckTarget(pClassName As %String) As %String
{
    Set Allowed = 0
    For Index = 1:1:$LENGTH(..#PACKAGES, ",") {
        Set:($EXTRACT(pClassName, 1, $LENGTH($PIECE(..#PACKAGES, ",", Index)) + 1) = ($PIECE(..#PACKAGES, ",", Index)_".")) Allowed = 1
    }
    Return:('Allowed) "Only classes in these packages can be tested: "_..#PACKAGES
    Return:('##class(%Dictionary.CompiledClass).%ExistsId(pClassName)) "Class not found: "_pClassName
    Return ""
}

/// Returns a problem message, or an empty string when the test code passes the static checks.
ClassMethod CheckCode(pClassName As %String, pTestCode As %String) As %String
{
    Set Problem = ..CheckTarget(pClassName)
    Return:(Problem '= "") Problem
    Set Code = $ZCONVERT(pTestCode, "L")
    For Index = 1:1:$LENGTH(..#BLOCKED, ",") {
        Set Word = $PIECE(..#BLOCKED, ",", Index)
        Return:(Code [ Word) "Refused: test code may not use """_Word_"""."
    }
    Set Header = "class "_$ZCONVERT(..TestClass(pClassName), "L")_" extends %unittest.testcase"
    Return:($ZSTRIP($PIECE(Code, "{", 1), "<>W") '[ Header) "The code must be one class: Class "_..TestClass(pClassName)_" Extends %UnitTest.TestCase"
    Return ""
}

ClassMethod TestClass(pClassName As %String) As %String
{
    Return "Test."_pClassName
}

/// Checks the code, then compiles it in a throwaway namespace. With pExecute, it also runs the tests.
/// pSummary holds passed, failed, failures and a text line. Problems with the code are reported in
/// pSummary.problem; the status is an error only when the sandbox itself fails. pTarget replaces
/// the class source, which the mutation measurement uses to test changed copies.
ClassMethod Run(pClassName As %String, pTestCode As %String, pExecute As %Boolean, Output pSummary As %DynamicObject, pTarget As %String = "") As %Status
{
    Set pSummary = {"passed":0, "failed":0, "failures":[], "problem":(..CheckCode(pClassName, pTestCode))}
    Return:(pSummary.problem '= "") $$$OK
    Set Target = pTarget
    If (Target = "") {
        Set SC = ##class(%Compiler.UDL.TextServices).GetTextAsString($NAMESPACE, pClassName, .Target)
        Return:($$$ISERR(SC)) SC
    }
    Set Name = "MERCTEST"_$JOB
    Set SC = ..Create(Name)
    Set:($$$ISOK(SC)) SC = ..RunIn(Name, pClassName, Target, pTestCode, pExecute, pSummary)
    Set DropSC = ..Drop(Name)
    Return:($$$ISERR(SC)) SC
    Return DropSC
}

ClassMethod RunIn(pNamespace As %String, pClassName As %String, pTarget As %String, pTestCode As %String, pExecute As %Boolean, pSummary As %DynamicObject) As %Status [ Private ]
{
    New $NAMESPACE
    Set $NAMESPACE = pNamespace
    Set TestClass = ..TestClass(pClassName)
    Set SC = ##class(%Compiler.UDL.TextServices).SetTextFromString(pNamespace, pClassName, pTarget)
    Return:($$$ISERR(SC)) SC
    // The class text needs CRLF line ends.
    Set Code = $REPLACE($TRANSLATE(pTestCode, $CHAR(13), ""), $CHAR(10), $CHAR(13, 10))
    Set SC = ##class(%Compiler.UDL.TextServices).SetTextFromString(pNamespace, TestClass, Code)
    If ($$$ISOK(SC)) {
        Set SC = $SYSTEM.OBJ.Compile(pClassName_","_TestClass, "ck-d")
    }
    If ($$$ISERR(SC)) {
        Set pSummary.problem = "Doesn't compile: "_$EXTRACT($SYSTEM.Status.GetErrorText(SC), 1, 800)
        Return $$$OK
    }
    Return:('pExecute) $$$OK

    // The manager wants an existing root directory even when nothing is loaded from it.
    Set ^UnitTestRoot = ..Directory(pNamespace)
    Set SC = ##class(%UnitTest.Manager).DebugRunTestCase("", TestClass, "/noload/nodelete/display=none", "")
    Return:($$$ISERR(SC)) SC
    Set Index = $ORDER(^UnitTest.Result(""), -1)
    Set Case = $NAME(^UnitTest.Result(Index, "(root)", TestClass))
    Set Method = ""
    For {
        Set Method = $ORDER(@Case@(Method))
        Quit:(Method = "")
        If ($LISTGET(@Case@(Method), 1)) {
            Set pSummary.passed = pSummary.passed + 1
            Continue
        }
        Set pSummary.failed = pSummary.failed + 1
        // Keep the first failed assert of each method, such as "Discount(999)== 1000 was '999'".
        Set Detail = ""
        Set Assert = ""
        For {
            Set Assert = $ORDER(@Case@(Method, Assert))
            Quit:(Assert = "")
            If ('$LISTGET(@Case@(Method, Assert), 1)) {
                Set Detail = $LISTGET(@Case@(Method, Assert), 3)
                Quit
            }
        }
        Do pSummary.failures.%Push(Method_": "_$EXTRACT(Detail, 1, 200))
    }
    Return $$$OK
}

ClassMethod Directory(pName As %String) As %String [ Private ]
{
    Return ##class(%File).NormalizeDirectory(##class(%File).SubDirectoryName($SYSTEM.Util.ManagerDirectory(), $ZCONVERT(pName, "L")))
}

ClassMethod Create(pName As %String) As %Status [ Private ]
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    Set Directory = ..Directory(pName)
    Do ##class(%File).CreateDirectoryChain(Directory)
    Set SC = ##class(SYS.Database).CreateDatabase(Directory)
    Return:($$$ISERR(SC)) SC
    Set Properties("Directory") = Directory
    Set SC = ##class(Config.Databases).Create(pName, .Properties)
    Return:($$$ISERR(SC)) SC
    Kill Properties
    Set Properties("Globals") = pName
    Set Properties("Routines") = pName
    Return ##class(Config.Namespaces).Create(pName, .Properties)
}

/// Removes the namespace, its database and the directory. Safe to call when parts are missing.
ClassMethod Drop(pName As %String) As %Status [ Private ]
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    Set Directory = ..Directory(pName)
    Do:(##class(Config.Namespaces).Exists(pName)) ##class(Config.Namespaces).Delete(pName)
    Do:(##class(Config.Databases).Exists(pName)) ##class(Config.Databases).Delete(pName)
    Set SC = $$$OK
    Set:(##class(%File).Exists(Directory_"IRIS.DAT")) SC = ##class(SYS.Database).DeleteDatabase(Directory)
    Do ##class(%File).RemoveDirectoryTree(Directory)
    Return SC
}

}
