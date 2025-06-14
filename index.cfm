<!--- make sure you first set proper .env variables --->
<cfset backup = createObject("component", "backup").init()>
<cfif not(backup.dsnList.success)>Unable to Init, check .env file<cfabort></cfif>

<cfoutput>
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>CFBackup</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
    </head>
      <body>
        <div class="container mt-5">

            <h3>Select Tables to Backup</h3>    

            <table class="table table-striped table-bordered table-responsive w-100">
                <thead>
                    <tr>    
                        <th>Dsn</th>
                        <th>Tables</th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop from="1" to="#arraylen(backup.dsnList.data)#" index="d">
                        <cfset item = backup.dsnList.data[d]>
                        <tr>
                            <td>#item.dsn#</td>
                            <td>
                                <table class="table"  class="table table-striped table-bordered table-responsive w-100">
                                    <cfloop from="1" to="#arraylen(item.tables)#" index="t">
                                        <tr>
                                            <th><a href="##" class="backup btn btn-primary" dsn="#item.dsn#" table="#item.tables[t].table#" >#item.tables[t].table#</a> (#numberformat(item.tables[t].rows,',')# rows)</th>
                                        </tr>
                                    </cfloop>
                                </table>
                            </td>
                        </tr>
                    </cfloop>
                </tbody>
            </table>
            

            <hr>
            <cfset backups = backup.getBackups()>
            <cfif arraylen(backups) gt 0>
                <h3>Backups</h3>    
                <table class="table table-striped table-bordered table-responsive w-100">
                    <thead>
                        <tr>    
                            <th>File/Date</th>
                            <th>Size</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop from="1" to="#arraylen(backups)#" index="b">
                            <tr>
                                <td><a href="exports/#backups[b].name#" target="CSV">#backups[b].name#</a></td>
                                <td>#numberformat(backups[b].size,',')#</td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </cfif>
        </div>

        <!--- Jquery to simply enhance UX --->
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-YvpcrYf0tY3lHB60NNkmXc5s9fDVZLESaAA55NDzOxhy9GkcIdslK1eN7N6jIeHz" crossorigin="anonymous"></script>
        <script>
          $(document).ready(function() {
            $('.backup').on('click', function() {
               var dsn = $(this).attr('dsn');
               var table = $(this).attr('table');
               $.ajax({
                    url: "backup.cfm?dsn=" + dsn + "&table=" + table,
                    method: 'GET', 
                    dataType: 'json', 
                    success: function(data) {
                        if(data.success == true) {location.reload();}
                        else {alert(data.error);}
                    }
               })
            });
          });
        </script>

    </body>
</html>
</cfoutput>

