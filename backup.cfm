<cfset backup = createObject("component", "backup").init()>

<cfset result = {}>
<cfif isdefined("url.dsn") and isdefined("url.table")>
    <!--- Backup selected DSN/Table --->
    <cfset result = backup.exportTable(url.dsn, url.table)>
</cfif>

<cfoutput>#serializeJSON(result)#</cfoutput>
<cfabort>