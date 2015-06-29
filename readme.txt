---WebLua---
Version: 0.2

WebLua is an API for Lua designed specifically for web programming. It supports GD, CGI, and saving tables to files (table databases can easilly be used instead of SQL) among other things - while being much faster and lighter than an ordinary PHP+Mysql setup.  This API was written for Lua 5.1, but would probably work with some older versions as well.

I will add more to this readme eventually, but for now you can find 
more information about the API at http://go-beyond.org/weblua/ .

Thanks for looking into this API, and let me know if you need any help
with it.

Cheers,
sega01 (Teran McKinney) - sega01 AT gmail dot com

Note: To use this API you must copy the contents of (not the
folder itself) api/ into any folder which contains scripts that would
use the api, or into /usr/lib/lua/VERSION/. In order to use the GD
side of WebLua, you must have GD installed. The examples (currently only
one) use GD, so they will not work without it. The current example also
requires the folder it is in to be writable, so if you run you webserver
as web:web you either need to chmod 777 the folder (potentially less secure, 
bad practice) or just chmod 777 vars.db, or preferably chmod the files as 
web:web (good practice, more secure). The example files are currently 
root:root.
