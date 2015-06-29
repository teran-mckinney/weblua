--print "Content-Type: text/html\r\n"
--print "Status: 200\r\n\r\n"
wl_send_headers(nil,"text/plain")
print (os.getenv("USER"))
  for k,v in pairs(lfcgi.environ()) do lfcgi.stdout:write(v,"\n") end
os.execute"env"
wl_decode_get()
print (wl.docroot)
if wl.get.lolz then print (wl.get.lolz) end
for k,v in pairs(wl.get) do print(k.." is set to "..wl.get[k]) end
print "epic lulz"
for i = 1,100 do
print("number "..i)
end
