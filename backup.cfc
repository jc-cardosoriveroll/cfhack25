<cfcomponent>
    <!---- INIT --->
    <cffunction name="init" returntype="struct" description="initialize with Credentials from .env">
        <cffile action="read" file="#expandpath('.env')#" variable="local.env">
        <cfset local.env = deserializeJSON(local.env)>
        <cfset this["env"] = local.env>
        <cfset this["dsnList"] = getAdminDatasources()>
        <cfreturn this>
    </cffunction>

    <!--- MAIN --->
    <cffunction name="getAdminDatasources" access="private" returntype="struct" description="gets All DSNs using CFADMIN API">
        <cfset local.result = []>
        <cftry>
            <!--- Login --->
            <cfset local.admin = createObject("component","cfide.adminapi.administrator")>
            <cfset local.admin.login(this.env.cfAdminPassword, this.env.cfAdminUser)>
            <!--- Get Datasources --->
            <cfset local.dsn = createObject("component","cfide.adminapi.datasource")>
            <cfset local.dsnList = local.dsn.getDatasources()>
            <cfloop collection="#local.dsnList#" item="local.d">
                <!--- Get tables  --->
                <cfdbinfo datasource="#local.d#" name="local.tables" type="tables">
                <cfset local.aTables = []>
                <cfloop query="local.tables">
                    <!--- Filter by Table Type --->
                    <cfif table_type eq 'table'>
                        <!--- Get Columns/schema & Row/count --->
                        <cfquery name="local.total" datasource="#local.d#">select count(*) as rowCount from #table_name#</cfquery>
                        <cfdbinfo datasource="#local.d#" table="#table_name#" name="local.cols" type="columns">
                        <cfset local.myCols = qryToArray(local.cols)>
                        <cfset local.myTable = {"table" : table_name, "cols" : local.myCols, "rows" : local.total.rowCount, "pk" : getPrimaryKey(local.myCols), "fields" : getFields(local.myCols,getPrimaryKey(local.myCols))}>
                        <cfset arrayappend(local.aTables,local.myTable)>
                    </cfif>
                </cfloop>
                <cfset local.tables = {"dsn" : local.d, "tables" : local.aTables}> 
                <cfset arrayappend(local.result,local.tables)>
            </cfloop>
            <!--- Logout --->
            <cfset local.admin.logout()>
            <cfset local.result = {"success" : true, "data" : local.result}>
            <!--- Manage Errors --->
            <cfcatch><cfset local.result = {"success" : false, "data" : cfcatch.message}></cfcatch>
        </cftry>
        <!--- return result --->
        <cfreturn local.result>
    </cffunction>

    <cffunction name="exportTable" access="public" returntype="struct" hint="Export a table from a datasource">
        <cfargument name="dsn" type="string" required="true">
        <cfargument name="table" type="string" required="true">

        <!--- Get DSN/TABLE settings --->
        <cfloop from="1" to="#arraylen(this.dsnList.data)#" index="d">
            <cfset local.item = this.dsnList.data[d]>
            <cfif local.item.dsn eq arguments.dsn>
                <cfloop from="1" to="#arraylen(item.tables)#" index="t">
                    <cfset local.source = local.item.tables[t]>
                </cfloop>
            </cfif>
        </cfloop>

        <!--- Do Export Process --->
        <cfif isdefined("local.source")>
            <cftry>
                <!--- Get all data, ordered by PK --->
                <cfquery name="local.qry" datasource="#arguments.dsn#">
                    select #local.source.pk#,#local.source.fields# 
                    from #arguments.table#
                    order by #local.source.pk#
                </cfquery>
                <cfset local.allFields = "#local.source.pk#,#local.source.fields#">
                <cfset local.myfile = getDirectoryFromPath(getCurrentTemplatePath()) & "exports/" & arguments.table & "_" & datetimeformat(now(),'yyyymmddHHnn') & ".csv">

                <!--- Create if Exports does not exist --->
                <cfif not(directoryExists("exports"))>
                    <cfdirectory action="create" directory="#expandPath('exports')#">
                </cfif>

                <!--- Execute ---> 
                <cfset local.mySettings = normalSettings(local.allFields)>
                <cfset CSVWRITE(local.qry, "query", local.myfile, local.mySettings)>
                <cfreturn {"success" : true, "file" : myfile}>

                <!--- Manage Errors --->
                <cfcatch>
                    <cfreturn {"success" : false, "file" : myfile, "error" : cfcatch.message}>
                </cfcatch>
            </cftry>
        </cfif>

        <cfreturn {"success" : false, "error" : "invalid DSN/Table"}>
    </cffunction>

    <!---- HELPERS ------>
    <cffunction name="insertDummyData" hint="temporal function to populate known test table">
        <cfargument name="count" default="100000" type="numeric">

        <cfset local.lastID = 0>
        <cfquery datasource="testJC" name="local.last" maxrows="1">
        select idUsr from _users order by idUsr desc
        </cfquery>
        <cfif local.last.recordcount eq 1>
            <cfset local.lastId = local.last.idUsr>
        </cfif>

        <cfloop from="1" to="#arguments.count#" index="x">
            <cfquery datasource="testJC" name="local.i">
                insert into _users 
                (
                     idUsr 
                    ,dtReg 
                    ,firstName 
                    ,lastName 
                    ,isActive 
                    ,email
                    ,phone
                )
                values 
                (
                     <cfqueryparam value="#local.lastId+x#">
                    ,#createodbcdatetime(now())#
                    ,<cfqueryparam value="firstName#x#">
                    ,<cfqueryparam value="lastName#x#">
                    ,<cfif x mod 10>0<cfelse>1</cfif>
                    ,<cfqueryparam value="email#x#@hackathon.com">
                    ,<cfqueryparam value="(#randrange(111,999)#) #randrange(1000,9999)#-#randrange(100,999)#">
                )
            </cfquery>
        </cfloop>
        <cfreturn true>
    </cffunction>

    <cffunction name="qryToArray" access="private" returntype="array" hint="takes a qry and returns formatted array">
        <cfargument name="qry">
        <cfargument name="useNull" default="false">

        <cfset local.result = []>
        <cfset local.meta = getMetaData(arguments.qry)> <!--- returns column "name" case sensitive --->

        <cfloop query="arguments.qry">
            <cfset local.tempS = {}>
            <cfloop from="1" to="#arraylen(local.meta)#" index="local.m">
                <cfset local.fieldName = local.meta[local.m].name>
                <cfset local.fieldType = local.meta[local.m].typeName>
                <cfset local.fieldValue = evaluate("arguments.qry." & local.fieldName)>
                <cfif arguments.useNull and len(local.fieldValue) eq 0>
                    <cfset local.tempS["#local.fieldName#"] = javaCast("null", 0)>
                <cfelse>
                    <cftry>
                        <cfswitch expression="#lcase(local.fieldType)#">
                            <cfcase value="int,smallint,tinyint">
                                <cfset local.tempS["#local.fieldName#"] = int(local.fieldValue)>
                            </cfcase>
                            <cfcase value="date">
                                <cfset local.tempS["#local.fieldName#"] = dateformat(local.fieldValue,'yyyy-mm-dd')>
                            </cfcase>
                            <cfcase value="datetime">
                                <cfset local.tempS["#local.fieldName#"] = datetimeformat(local.fieldValue,'yyyy-mm-dd HH:nn')>
                            </cfcase>
                            <cfcase value="time">
                                <cfset local.tempS["#local.fieldName#"] = datetimeformat(local.fieldValue,'HH:nn')>
                            </cfcase>
                            <cfcase value="bit">
                                <cfset local.tempS["#local.fieldName#"] = local.fieldValue ? true : false>
                            </cfcase>
                            <cfdefaultcase>
                                <!--- varchar,char,nvarchar,text --->
                                <cfif isJson(local.fieldValue)>
                                    <cfset local.tempS["#local.fieldName#"] = deserializeJSON(local.fieldValue)>
                                <cfelse>
                                    <cfset local.tempS["#local.fieldName#"] = trim(local.fieldValue)>
                                </cfif>
                            </cfdefaultcase>
                        </cfswitch>
                        <cfcatch>
                            <cfif arguments.useNull>
                                <cfset local.tempS["#local.fieldName#"] = javaCast("null", 0)>
                            <cfelse>
                                <cfset local.tempS["#local.fieldName#"] = "">
                            </cfif>
                        </cfcatch>
                    </cftry>
                </cfif>
            </cfloop>
            <cfset arrayappend(local.result,local.tempS)>
        </cfloop>

        <cfreturn local.result>
    </cffunction>

    <cffunction name="getPrimaryKey" access="private" returntype="string" hint="returns PK or best field">
        <cfargument name="cols">

        <cftry>
            <cfset local.pk = "">
            <!--- cfdbinfotype="fk" has proven unreliable, using fallback (cols) --->
            <!--- Loop all fields to find "Defined" primary Key --->
            <cfloop from="1" to="#arraylen(arguments.cols)#" index="local.c">
                <cfif arguments.cols[local.c].is_PrimaryKey>
                    <cfset local.pk = arguments.cols[local.c].column_name>
                    <cfbreak>
                </cfif>
            </cfloop>

            <cfif len(local.pk) eq 0>
                <!---If no PK then use the first Datetime field --->
                <cfloop from="1" to="#arraylen(arguments.cols)#" index="local.c">
                    <cfif listfindnocase('datetime,datetime2',arguments.cols[local.c].data_type)>
                        <cfset local.pk = arguments.cols[local.c].column_name>
                        <cfbreak>
                    </cfif>
                </cfloop>
            </cfif>

            <cfif len(local.pk) eq 0>
                <!--- Just use the first Field --->
                <cftry>
                    <cfset local.pk = arguments.cols[1].column_name>
                    <cfcatch></cfcatch>
                </cftry>
            </cfif>

            <cfreturn local.pk>
            <cfcatch>
                <cfreturn cfcatch.message>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getFields" access="private" returntype="string" hint="returns all fields minus PK">
        <cfargument name="cols">
        <cfargument name="pk">

        <cfset local.fields = []>

        <!--- Loop all fields to find "Defined" primary Key --->
        <cfloop from="1" to="#arraylen(arguments.cols)#" index="local.c">
            <cfif arguments.cols[local.c].column_name neq arguments.pk>
                <cfset arrayappend(local.fields,arguments.cols[local.c].column_name)>
            </cfif>
        </cfloop>

        <cfreturn listsort(arraytoList(local.fields),"text","asc")>
    </cffunction>

    <cffunction name="normalSettings" access="private" returntype="struct" hint="normalizes env csvWrite Settings">
        <cfargument name="allFields">

        <cfset local.settings = this.env.csvWrite>

        <!--- add Header --->
        <cfset local.settings["header"] = listtoarray(arguments.allFields)>

        <!--- do Specific delimiter Replacements --->
        <cfif isdefined("local.settings.delimiter")>
            <cfif local.settings.delimiter eq 'tab'>
                <cfset local.settings.delimiter = chr(9)>
            <cfelseif local.settings.delimiter eq 'row'>
                <cfset local.settings.delimiter = chr(10)>
            </cfif>
        </cfif>

        <!--- do Specific recordSeparator Replacements --->
        <cfif isdefined("local.settings.recordSeparator")>
            <cfif local.settings.recordSeparator eq 'tab'>
                <cfset local.settings.recordSeparator = chr(9)>
            <cfelseif local.settings.recordSeparator eq 'row'>
                <cfset local.settings.recordSeparator = chr(10)>
            </cfif>
        </cfif>

        <cfreturn local.settings>
    </cffunction>

    <cffunction name="getBackups" access="public" returntype="array" hint="returns all backups">
        <cfdirectory action="list" directory="#expandpath('exports')#" name="local.dir" filter="*.csv">
        <cfset local.dir = qryToArray(local.dir)> 
        <cfreturn local.dir>
    </cffunction>

</cfcomponent>
