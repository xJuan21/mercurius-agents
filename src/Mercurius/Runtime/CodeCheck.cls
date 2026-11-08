/// Deterministic checks for agents: ObjectScript syntax and SQL validity. Neither runs the code.
Class Mercurius.Runtime.CodeCheck Extends %RegisteredObject
{

/// Schemas the SQL tools may describe and validate against.
Parameter SQLSCHEMAS = "Mercurius_Model";

/// Compiles the lines as a throwaway INT routine. INT code has no macro preprocessor, so
/// compiling can't run anything. The routine is deleted afterwards.
ClassMethod Syntax(pCode As %String) As %String
{
    Set Name = "ZZMercuriusCheck"_$JOB
    Set Routine = ##class(%Routine).%New(Name_".INT")
    Do Routine.WriteLine(Name)
    Set Code = $TRANSLATE(pCode, $CHAR(13), "")
    For Index = 1:1:$LENGTH(Code, $CHAR(10)) {
        Do Routine.WriteLine(" "_$PIECE(Code, $CHAR(10), Index))
    }
    Set SC = Routine.Save()
    Set:($$$ISOK(SC)) SC = Routine.Compile("-d")
    Do ##class(%Routine).Delete(Name_".INT")
    Return:($$$ISOK(SC)) "No syntax errors."
    Set Text = $SYSTEM.Status.GetErrorText(SC)
    // Keep the error and its position, without the throwaway routine's name.
    Set Text = $PIECE(Text, "#", 3, *)
    Return "Syntax error: #"_$PIECE(Text, " [", 1)
}

/// Prepares a SELECT without running it. Returns the result columns, or the problem.
ClassMethod SQL(pQuery As %String) As %String
{
    Set Query = $ZSTRIP(pQuery, "<>W")
    Set:($EXTRACT(Query, *) = ";") Query = $EXTRACT(Query, 1, * - 1)
    Return:($ZCONVERT($EXTRACT(Query, 1, 6), "U") '= "SELECT") "Refused: only SELECT statements are allowed."
    Return:(Query [ ";") "Refused: only one statement is allowed."
    Set Statement = ##class(%SQL.Statement).%New()
    Set SC = Statement.%Prepare(Query)
    Return:($$$ISERR(SC)) "Invalid: "_$SYSTEM.Status.GetErrorText(SC)
    Set Columns = ""
    Set Metadata = Statement.%Metadata
    For Index = 1:1:Metadata.columnCount {
        Set Columns = Columns_$SELECT(Columns = "":"", 1:", ")_Metadata.columns.GetAt(Index).colName
    }
    Return "Valid SELECT. Not run. Columns: "_Columns
}

/// Lists the tables and columns of an allowed schema.
ClassMethod Describe(pSchema As %String) As %String
{
    Return:('$LISTFIND($LISTFROMSTRING(..#SQLSCHEMAS), pSchema)) "Only these schemas can be described: "_..#SQLSCHEMAS
    Set Result = {}
    Set Statement = ##class(%SQL.Statement).%ExecDirect(, "SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME, ORDINAL_POSITION", pSchema)
    While (Statement.%Next()) {
        Set Table = pSchema_"."_Statement."TABLE_NAME"
        Do:('Result.%IsDefined(Table)) Result.%Set(Table, [])
        Do Result.%Get(Table).%Push(Statement."COLUMN_NAME"_" "_Statement."DATA_TYPE")
    }
    Return Result.%ToJSON()
}

}
