-- No idea who originally wrote this script, but they sure did a good job
-- :-). Only one bug that I have found so far, and it might even be an
-- HTTPD default and not a bug. HTTP_COOKIES needed to be changed to 
-- HTTP_COOKIE. Thanks to whoever wrote this script! --sega01

--[[------------------------------------------------------------------------
global table holding the cgi functions
--]]------------------------------------------------------------------------
local _cgi = {}

--[[------------------------------------------------------------------------
local functions/variables used in cgi member functions
--]]------------------------------------------------------------------------

local html_codes = {
    [string.char(tonumber('0xE4', 16))] = '&auml;',
    [string.char(tonumber('0xC4', 16))] = '&Auml;',
    [string.char(tonumber('0xF6', 16))] = '&ouml;',
    [string.char(tonumber('0xD6', 16))] = '&Ouml;',
    [string.char(tonumber('0xFC', 16))] = '&uuml;',
    [string.char(tonumber('0xDC', 16))] = '&Uuml;',
    [string.char(tonumber('0xDF', 16))] = '&szlig;',
    [string.char(tonumber('0xA4', 16))] = '&euro;',
    [string.char(tonumber('0x3C', 16))] = '&lt;',
    [string.char(tonumber('0x3E', 16))] = '&gt;',
    [string.char(tonumber('0x26', 16))] = '&amp;',
    [string.char(tonumber('0x22', 16))] = '&quot;'
}

local html_codes_match = '['
    for code, _ in pairs(html_codes) do
        html_codes_match = html_codes_match .. code
    end
html_codes_match = html_codes_match .. ']'

-- translate html special char to mapped string in 'html_codes'
local function html_map(str)
    return html_codes[str]
end

-- convert hex format to character
local function hex_to_ch(str)
    return string.char(tonumber(str,16))
end

-- convert character to hex format
local function ch_to_hex(str)
    return string.format('%%%X', string.byte(str))
end

--[[------------------------------------------------------------------------
CGI related environment variables
--]]------------------------------------------------------------------------
local _cgi_vars = {
    'AUTH_TYPE', 'CONTENT_LENGTH', 'CONTENT_TYPE', 'GATEWAY_INTERFACE',
    'PATH_INFO', 'PATH_TRANSLATED', 'QUERY_STRING', 'REMOTE_ADDR',
    'REMOTE_HOST', 'REMOTE_IDENT', 'REMOTE_USER', 'REQUEST_METHOD',
    'SCRIPT_NAME', 'SERVER_NAME', 'SERVER_PORT', 'SERVER_PROTOCOL',
    'SERVER_SOFTWARE'
}

--[[------------------------------------------------------------------------
send error message and discard all gathered content previously
--]]------------------------------------------------------------------------
function _cgi.send_error(title, message, terminate)
    -- send an error message provided by the caller
    io.write(
            'Content-type: text/html\n\n',
            '<html><header><title>Error</title></header>',
            '<body><h1><b>', _cgi.html_encode(title or ''), '</b></h1><pre>',
            (message or ''), '</pre></body></html>'
            )

    -- terminate program if 'terminate' is 'true'
    if (terminate) then os.exit() end
end

--[[------------------------------------------------------------------------
set reply message content type
--]]------------------------------------------------------------------------
function _cgi.set_content_type(content_type)
    _cgi.content_type = content_type
end

--[[------------------------------------------------------------------------
set reply message content type
--]]------------------------------------------------------------------------
function _cgi.set_status(status, message)
    _cgi.status = status .. ' '.. message
end

--[[------------------------------------------------------------------------
append HTTP/CGI header to reply
header must not include newline character anywhere in the string
--]]------------------------------------------------------------------------
function _cgi.send_header(header)
    if (_cgi.headers_sent) then
        error('Headers were already sent')
    end

    table.insert(_cgi.headers, header)
end

function _cgi.redirect(location)
    _cgi.send_header('Location: '..location)
end

--[[------------------------------------------------------------------------
name    string
value   string
max_age string  [optional]
path    string  [optional]
domain  string  [optional]
secure  boolean
--]]------------------------------------------------------------------------
function _cgi.add_cookie(name, value, max_age, path, domain, secure)
    local header = 'Set-Cookie: '..name..'='..value
    if (max_age) then header = header..'; Max-age='..max_age end
    if (path)    then header = header..'; Path='..path end
    if (domain)  then header = header..'; Domain='..domain end
    if (secure)  then header = header..'; Secure' end

    _cgi.send_header(header)
end

--[[------------------------------------------------------------------------
send all gathered headers to standard output (called by cgi.done)
--]]------------------------------------------------------------------------
local function _cgi_send_headers()
    if (not _cgi.headers_sent) then
        -- status message
        io.write('Status: ', _cgi.status, '\n')

        -- write content type header
        io.write('Content-type: ', _cgi.content_type, '\n')

        -- write all gathered headers with a newline in the end
        -- use ipairs as order may be important
        for _, header in ipairs(_cgi.headers) do
            io.write(header, '\n')
        end

        -- write empty line indicating end of headers
        io.write('\n')

        _cgi.headers_sent = true
    end
end


--[[------------------------------------------------------------------------
append information to main content of cgi reply
--]]------------------------------------------------------------------------
function _cgi.send(...)
    if (not _cgi.options.use_buffer) then
        if (not _cgi.headers_sent) then
            _cgi_send_headers()
        end
        io.write(table.concat(arg))
        return
    end

    -- using a table to 'buffer' the contents instead of concatenating all
    -- strings wich might degrade performance
    table.insert(_cgi.content, table.concat(arg))

    -- everytime we reach 1000 elements in the table, concatenate the
    -- contents so we don't use too much memory by using this method to
    -- concatenate strings
    if (table.getn(_cgi.content) > 1000) then
        -- create new list so existing strings may be garbage collected next
        -- time a collection cycle takes place
        _cgi.content = { table.concat(_cgi.content) }
    end
end

--[[------------------------------------------------------------------------
send the gathered contents to standard output
--]]------------------------------------------------------------------------
function _cgi_send_content()
    --table.foreachi(E.content, function(k,v) io.write(v) end)
    io.write(table.concat(_cgi.content))
end

--[[------------------------------------------------------------------------
Decodes an encoded URL
--]]------------------------------------------------------------------------
function _cgi.url_decode(text)
    -- convert '+' to spaces, and convert hex codes to characters
    return string.gsub(string.gsub(text, '+', ' '), '%%(%x%x)', hex_to_ch)
end

--[[------------------------------------------------------------------------
Encodes an URL
--]]------------------------------------------------------------------------
function _cgi.url_encode(text)
    -- convert spaces to '+' and any non-alphanumeric characters, underscore,
    -- '-' and '+' to hex format
    return string.gsub(string.gsub(text, ' ', '+'), '[^%w_%.%-+]', ch_to_hex)
end

--[[------------------------------------------------------------------------
replace special characters understood by html with encoded strings
--]]------------------------------------------------------------------------
function _cgi.html_encode(text)
    return (string.gsub(text, html_codes_match, html_map))
end

--[[------------------------------------------------------------------------
decode multipart_post formatted string into a table
--]]------------------------------------------------------------------------
local function _cgi_process_multipart_post(content, t)
    -- pointer inside content indicating next location to be parsed/read
    local cpos = 1
    local name = ''
    local file = false
    local delim, line, value
    local first, last, token, ltoken, ptoken, _, state, size

    -- get a line without the newline character(s) in the end
    local function getline()
        first, last = string.find(content, '\n', cpos, 1)
        if (not first) then
            return string.sub(content, cpos), string.len(content) + 1
        else
            if (first > 1 and string.sub(content, first - 1, first - 1) == '\r') then
                first = first - 1
            end
            return string.sub(content, cpos, first - 1), last + 1
        end
    end

    -- needed initializations
    name = ''
    file = false

    delim, cpos = getline()

    if (string.len(delim) == 0) then
        return
    end

    while (cpos <= string.len(content)) do
        line, cpos = getline()

        if (string.len(line) == 0) then
            -- get bounded content
            first, last = string.find(content, '\n'..delim, cpos, true)
            if (not first) then
                value = string.sub(content, cpos)
                cpos = string.len(content) + 1
            else
                if (first > 1 and string.sub(content, first-1, first-1) == '\r') then
                    first = first - 1
                end
                value = string.sub(content, cpos, first - 1)
                cpos = last + 1

                -- skip boundary
                line, cpos = getline()
            end

            if (string.len(name) > 0) then
                t[name] = value
                if (file) then
                    t[name..':size'] = string.len(value)
                end
            end
            name = ''
            file = false
        else
            -- parse line tokens
            ptoken = 1

            -- state machine:
            -- 0 - match token          -> x
            -- 1 - save name            -> 0
            -- 2 - save filename        -> 0
            -- 3 - save content-type    -> 0
            -- 9 - skip token           -> 0
            state = 0

            while (ptoken <= string.len(line)) do
                -- skip spaces and ';'
                _, ptoken = string.find(line, '[^%s;]', ptoken)

                -- no more processing to do -> break cycle
                if (not ptoken) then
                    break
                end

                -- if token starts with '"' then scan the line untill a
                -- matching '"' is found
                if (string.sub(line, ptoken, ptoken) == '"') then
                    first = string.find(line, '"', ptoken + 1, true)
                    if (first) then
                        token = string.sub(line, ptoken + 1, first - 1)
                        ptoken = first + 1
                    else
                        token = string.sub(line, ptoken + 1)
                        ptoken = string.len(line) + 1
                    end
                else
                    first = string.find(line, '[%s;"]', ptoken)
                    if (first) then
                        token = string.sub(line, ptoken, first - 1)
                        ptoken = first + 1
                    else
                        token = string.sub(line, ptoken)
                        ptoken = string.len(line) + 1
                    end
                end

                ltoken = string.lower(token)

                if (state == 0) then
                    if (ltoken == 'content-disposition:') then
                        state = -1 -- skip next token
                    elseif (ltoken == 'name=') then
                        state = 1 -- next token sets name
                    elseif (ltoken == 'filename=') then
                        state = 2
                    elseif (ltoken == 'content-type:') then
                        state = 3
                    end
                else
                    if (state == 1) then
                        name = token -- save name
                    elseif (state == 2 and name) then
                        t[name..':filename'] = token        -- filename
                        file = true
                    elseif (state == 3 and name) then
                        t[name..':content-type'] = token    -- content-type
                    end
                    state = 0
                end -- if state
            end -- while ptoken <= len(line)
        end -- if line or contents
    end -- while cpos <= len(content)
end

--[[------------------------------------------------------------------------
decode contents of string in the form:
    name1=value1...
using terminator as a separator
    ex: terminator = '&'
        name1=value1&name2=value2&...&nameN=valueN
values will be 'url decoded' and stored in the given table 't'
--]]------------------------------------------------------------------------
local function _cgi_decode_pair(str, t, terminator)
    local k, v, first, pos
    local last = 0
    local len = string.len(str)

    while (last and last < len) do
        pos = last + 1

        first, last = string.find(str, '=', pos, true)
        if (not first) then
            k = string.sub(str, pos)
            v = ''
        else
            k = string.sub(str, pos, first - 1)

            pos = last + 1

            first, last = string.find(str, terminator, pos, true)
            if (not first) then
                v = string.sub(str, pos)
            else
                v = string.sub(str, pos, first - 1)
            end
        end
        t[k] = _cgi.url_decode(v)
    end
end

--[[------------------------------------------------------------------------
initialize cgi information

options is a list of options to override default options
--]]------------------------------------------------------------------------
function _cgi.init(options)
    options = options or {}

    _cgi.options = {
        use_temp    = true, -- use temporary files for multipart/* messages :TODO
        use_buffer  = true, -- buffer content information
        max_content = 4096, -- maximum size of content read from stdin
    }

    _cgi.env = {}           -- environment variables (CGI related)
    _cgi.vars = {}          -- variables received (QUERY_STRING/FORM DATA)
    _cgi.cookies = {}       -- existing cookies

    _cgi.headers = {}       -- headers to be sent in cgi reply
    _cgi.content = {}       -- content to be sent in cgi reply
    _cgi.status = '200 OK'  -- default status
    _cgi.content_type = 'text/html'    -- default reply content type

    _cgi.headers_sent = false   -- signal if headers were already sent
    for k, v in pairs(options) do
        if (_cgi.options[k]) then
            _cgi.options[k] = v
        end
    end
    -- retrieve CGI related environment variables information
    for _, v in pairs(_cgi_vars) do
        _cgi.env[v] = os.getenv(v)
    end

    -- check used method or assume GET
    _cgi.env.REQUEST_METHOD = _cgi.env.REQUEST_METHOD or 'GET'

    -- POST information is read from standard input
    if _cgi.env.REQUEST_METHOD == 'POST' then
        -- standard input information has a limit given in CONTENT_LENGTH
        _cgi.env.CONTENT_LENGTH = _cgi.env.CONTENT_LENGTH or '0'
        _cgi.env.CONTENT_TYPE = _cgi.env.CONTENT_TYPE or ''

        local ctype = _cgi.env.CONTENT_TYPE
        local clen = tonumber(_cgi.env.CONTENT_LENGTH)

        if (clen > _cgi.options.max_content) then
            _cgi.error = 'CONTENT_LENGTH exceeds limit set ('.._cgi.options.max_content..')'
            return false
        end

        if ctype == 'application/x-www-form-urlencoded' then
            -- decode url encoded information
            _cgi_decode_pair(io.read(clen), _cgi.vars, '&')
        elseif string.sub(ctype, 1, 19) == 'multipart/form-data' then
            -- decode multipart format information
            _cgi_process_multipart_post(io.read(clen), _cgi.vars)
        end
    else
        -- decode url encoded information given in QUERY_STRING
        _cgi_decode_pair(_cgi.env.QUERY_STRING or '', _cgi.vars, '&')
    end

    -- decode cookies and save them in cgi.cookies
    _cgi_decode_pair(os.getenv('HTTP_COOKIE') or '', _cgi.cookies, ';')

    return true
end

--[[------------------------------------------------------------------------
reply to cgi request, seding all related information generated by the script
--]]------------------------------------------------------------------------
function _cgi.done(terminate)
    _cgi_send_headers()
    if (_cgi.options.use_buffer) then
        _cgi_send_content()
    end

    -- terminate program if 'terminate' is 'true'
    if (terminate) then os.exit() end
end

--[[------------------------------------------------------------------------
global cgi table visible to the user holding the cgi access functions/values
--]]------------------------------------------------------------------------
cgi = _cgi
