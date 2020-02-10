m = Map("vlmcsd")
m.title	= translate("KMS Server config")

local ver = luci.sys.exec("vlmcsd -V | awk '/built/{print $2}' | sed -n 's/,//p'")
local running=(luci.sys.call("pidof vlmcsd > /dev/null") == 0)

if running then
	Status = "<b><font color=\"green\">" .. translate("KMS Server is running.") .. "</font></b>"
else
	Status = "<b><font color=\"red\">" .. translate("KMS Server is stopped.") .. "</font></b>"
end

m.description = translate("Current Version") .. ": " .. ver .. "<br /> " .. Status

s = m:section(TypedSection, "vlmcsd", "")
s.addremove = false
s.anonymous = true

fEnable = s:option(Flag, "enabled", translate("Enable"))
fEnable.rmempty = false

fAutoact = s:option(Flag, "autoactivate", translate("Auto activate"))
fAutoact.rmempty = false

config = s:option(Value, "config", translate("configfile"), translate("This file is /etc/vlmcsd.ini."), "")
config.template = "cbi/tvalue"
config.rows = 20
config.wrap = "off"

function config.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/vlmcsd.ini")
end

function config.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/etc/vlmcsd.ini", value)
end

function fAutoact.write(self, section, value)
	local hostname = luci.model.uci.cursor():get_first("system", "system", "hostname")
	if value == "1" then
		luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
		luci.sys.call("echo srv-host=_vlmcs._tcp.lan,".. hostname ..".lan,1688,0,100 >> /etc/dnsmasq.conf")
	else
		luci.sys.call("sed -i '/srv-host=_vlmcs._tcp.lan/d' /etc/dnsmasq.conf")
	end
	--luci.sys.exec("/etc/init.d/dnsmasq restart >/dev/null")
	Flag.write(self, section, value)
end

function m.on_commit(self)
	local isEnable =luci.model.uci.cursor():get("vlmcsd", "config", "enabled")
	if isEnable == '1' then
		luci.sys.call("/etc/init.d/vlmcsd start >/dev/null")
		luci.sys.call("/etc/init.d/vlmcsd enable >/dev/null")
	else
		luci.sys.call("/etc/init.d/vlmcsd stop >/dev/null")
		luci.sys.call("/etc/init.d/vlmcsd disable >/dev/null")
	end
	luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null")
end

return m
