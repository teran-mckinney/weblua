-- Default Zenserver Page. < converted to WebLua 0.3 as an example. Not even
-- sure if the code runs.

wl_load_module "tabledb"

wl_send_headers()

    file = io.open("vars.db", "r")
    if file then vars=(table.load "vars.db") vars.visits = vars.visits + 1 table.save(vars, "vars.db") file:close() else vars={visits=1} table.save(vars, "vars.db") end

write [[
<html>
<head>
<style type="text/css">	
body,td,th {
	font-family: sans-serif;
	font-size: 12px;
	color: #013370;
}
body {
	background-color: #000000;
}
a:link {
	color: #313337;
	text-decoration: none;
}
a:visited {
	color: #313337;
	text-decoration: none;
}
a:hover{
	color: #133EE7;
	text-decoration: none;
}
</style>
<title>Default Zenserver+Lighttpd Webpage</title>
</head>
<body>
	<center>
		<p><img src="default/zenserver.png">
		<p><h2><b>Welcome to the default Zenserver webpage.</b>
	<p>This website runs on <a href="http://zenserver.zenwalk.org/">Zenserver</a>, and is powered by <a href="http://www.lighttpd.net">Lighttpd</a>.
	<p>This page is scripted with the <a href="http://go-beyond.org/weblua/">WebLua</a> API, which uses <a href="http://www.lua.org">Lua</a>.
				]]
write ("<p>Total visits: ",vars.visits)
write [[
<p><img src="default/clock.lua">		
<p><img src="default/lighttpd.png">
		</h2>
	</center>
</body>
</html>
]]
