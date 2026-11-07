/// Serves the built Angular files. A static web application has no default document,
/// so this class answers /mercurius/ with index.html. The files hold no data.
Class Mercurius.API.Web Extends %CSP.REST
{

Parameter UseSession As Integer = 0;

Parameter Root = "/usr/irissys/csp/mercurius/";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/" Method="GET" Call="ServeIndex"/>
  <Route Url="/:file" Method="GET" Call="ServeFile"/>
</Routes>
}

ClassMethod ServeIndex() As %Status
{
    Return ..ServeFile("index.html")
}

/// The build output is one flat folder, so anything that isn't a plain file name is refused.
ClassMethod ServeFile(pFile As %String) As %Status
{
    If ('$MATCH(pFile, "[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+") || '##class(%File).Exists(..#Root_pFile)) {
        Set %response.Status = ..#HTTP404NOTFOUND
        Return $$$OK
    }
    Set Extension = $ZCONVERT($PIECE(pFile, ".", *), "L")
    Set %response.ContentType = $CASE(Extension,
        "html":"text/html", "js":"text/javascript", "css":"text/css", "ico":"image/x-icon",
        "svg":"image/svg+xml", "json":"application/json", "txt":"text/plain", :"application/octet-stream")
    Set %response.CharSet = "utf-8"
    Set %response.NoCharSetConvert = 1
    Do:(Extension = "html") %response.SetHeader("Cache-Control", "no-cache")

    Set Stream = ##class(%Stream.FileBinary).%New()
    Set SC = Stream.LinkToFile(..#Root_pFile)
    Return:($$$ISERR(SC)) SC
    Return Stream.OutputToDevice()
}

}
