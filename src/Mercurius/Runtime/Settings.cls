/// Deployment settings read from the environment.
Class Mercurius.Runtime.Settings Extends %RegisteredObject
{

/// Links into the Management Portal show unless MERCURIUS_PORTAL_LINKS is 0.
ClassMethod PortalLinks(pValue As %String = {$SYSTEM.Util.GetEnviron("MERCURIUS_PORTAL_LINKS")}) As %Boolean
{
    Return ($ZSTRIP(pValue, "<>W") '= "0")
}

}
