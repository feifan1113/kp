local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"

local o,t,e
local v=luci.sys.exec("/usr/share/koolproxy/koolproxy -v")
local s=luci.sys.exec("head -3 /usr/share/koolproxy/data/rules/koolproxy.txt | grep rules | awk -F' ' '{print $3,$4}'")
local u=luci.sys.exec("head -4 /usr/share/koolproxy/data/rules/koolproxy.txt | grep video | awk -F' ' '{print $3,$4}'")
local p=luci.sys.exec("head -3 /usr/share/koolproxy/data/rules/daily.txt | grep rules | awk -F' ' '{print $3,$4}'")
local l=luci.sys.exec("grep -v !x /usr/share/koolproxy/data/rules/koolproxy.txt | wc -l")
local q=luci.sys.exec("grep -v !x /usr/share/koolproxy/data/rules/daily.txt | wc -l")
local h=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/user.txt | wc -l")
local i=luci.sys.exec("cat /usr/share/koolproxy/dnsmasq.adblock | wc -l")
local abx_rules_local=luci.sys.exec("cat /usr/share/koolproxy/data/rules/chengfeng.txt | sed -n '3p'|awk '{print $3,$4}'")
local abx_nu_local=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/chengfeng.txt | wc -l")
local fanboy_rules_local=luci.sys.exec("cat /usr/share/koolproxy/data/rules/fanboy.txt | sed -n '4p'|awk '{print $3,$4}'")
local fanboy_nu_local=luci.sys.exec("grep -v '^!' /usr/share/koolproxy/data/rules/fanboy.txt | wc -l")

if luci.sys.call("pidof koolproxy >/dev/null") == 0 then
	status = translate("<strong><font color=\"green\">KoolProxy is Running</font></strong>")
else
	status = translate("<strong><font color=\"red\">KoolProxy is Not Running</font></strong>")
end

o = Map("koolproxy", translate("KoolProxy"), translate("A powerful advertisement blocker. <br /><font color=\"red\">Adblock Plus Host list + koolproxy Blacklist mode runs without loss of bandwidth due to performance issues.<br /></font>"))

t = o:section(TypedSection, "global")
t.anonymous = true
t.description = translate(string.format("%s<br /><br />", status))

t:tab("base",translate("Basic Settings"))

e = t:taboption("base", Flag, "enabled", translate("Enable"))
e.default = 0
e.rmempty = false

e = t:taboption("base", DummyValue, "koolproxy_status", translate("????????????"))
e.value = string.format("[ %s ]", v)

e = t:taboption("base", Value, "startup_delay", translate("Startup Delay"))
e:value(0, translate("Not enabled"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	e:value(v, translate("%u seconds") %{v})
end
e.datatype = "uinteger"
e.default = 0
e.rmempty = false

e = t:taboption("base", ListValue, "koolproxy_mode", translate("Filter Mode"))
e.default = 1
e.rmempty = false
e:value(1, translate("????????????"))
e:value(2, translate("IPSET??????"))
e:value(3, translate("????????????"))

e = t:taboption("base", MultiValue, "koolproxy_rules", translate("????????????"))
e.optional = false
e.rmempty = false
e:value("koolproxy.txt", translate("????????????"))
e:value("daily.txt", translate("????????????"))
e:value("kp.dat", translate("????????????"))
e:value("user.txt", translate("???????????????"))

e = t:taboption("base", MultiValue, "thirdparty_rules", translate("???????????????"))
e.optional = false
e.rmempty = false
e:value("chengfeng.txt", translate("????????????"))
e:value("fanboy.txt", translate("Fanboy??????"))

e = t:taboption("base", ListValue, "koolproxy_port", translate("????????????"))
e.default = 0
e.rmempty = false
e:value(0, translate("??????"))
e:value(1, translate("??????"))

e = t:taboption("base", Value, "koolproxy_bp_port", translate("????????????"))
e:depends("koolproxy_port", "1")
e.rmempty = false
e.description = translate(string.format("<font color=\"red\"><strong>?????????:80&nbsp;&nbsp;?????????:80,443</strong></font>"))

e=t:taboption("base",Flag,"koolproxy_host",translate("??????Adblock Plus Host"))
e.default=0
e:depends("koolproxy_mode","2")


e = t:taboption("base", ListValue, "koolproxy_acl_default", translate("??????????????????"))
e.default = 1
e.rmempty = false
e:value(0, translate("?????????"))
e:value(1, translate("http only"))
e:value(2, translate("http + https"))
e:value(3, translate("full port"))
e.description = translate(string.format("<font color=\"blue\"><strong>????????????????????????????????????????????????</strong></font>"))

e = t:taboption("base", ListValue, "time_update", translate("????????????"))
for t = 0,23 do
	e:value(t,translate("??????"..t.."???"))
end
e.default = 0
e.rmempty = false
e.description = translate(string.format("<font color=\"red\"><strong>???????????????????????????Adblock Plus Host</strong></font>"))

e = t:taboption("base", Button, "restart", translate("????????????"))
e.inputtitle = translate("????????????")
e.inputstyle = "reload"
e.write = function()
	luci.sys.call("/usr/share/koolproxy/kpupdate 2>&1 >/dev/null")
	luci.http.redirect(luci.dispatcher.build_url("admin","services","koolproxy"))
end
e.description = translate(string.format("<font color=\"red\"><strong>?????????????????????Adblock Plus Host</strong></font><br /><font color=\"green\">????????????: %s / %s??? ????????????: %s<br />????????????: %s / %s??? ???????????????: %s???<br />Host: %s???</font><br /><font color=\"blue\">????????????: %s / %s???<br />Fanboy??????: %s / %s???</font>", s, l, u, p, q, h, i, abx_rules_local, abx_nu_local, fanboy_rules_local, fanboy_nu_local))

t:tab("cert",translate("Certificate Management"))

e=t:taboption("cert",DummyValue,"c1status",translate("<div align=\"left\">Certificate Restore</div>"))
e=t:taboption("cert",FileUpload,"")
e.template="koolproxy/caupload"
e=t:taboption("cert",DummyValue,"",nil)
e.template="koolproxy/cadvalue"
if nixio.fs.access("/usr/share/koolproxy/data/certs/ca.crt")then
	e=t:taboption("cert",DummyValue,"c2status",translate("<div align=\"left\">Certificate Backup</div>"))
	e=t:taboption("cert",Button,"certificate")
	e.inputtitle=translate("Backup Download")
	e.inputstyle="reload"
	e.write=function()
		luci.sys.call("/usr/share/koolproxy/camanagement backup 2>&1 >/dev/null")
		Download()
		luci.http.redirect(luci.dispatcher.build_url("admin","services","koolproxy"))
	end
end

t:tab("white_weblist",translate("?????????????????????"))

local i = "/etc/adblocklist/adbypass"
e = t:taboption("white_weblist", TextValue, "adbypass_domain")
e.description = translate("These had been joined websites will not usefilter.Please input the domain names of websites,every line can input only one website domain.For example,google.com.")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adbypass", value)
	if (luci.sys.call("cmp -s /tmp/adbypass /etc/adblocklist/adbypass") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adbypass")
end

t:tab("weblist",translate("Set Backlist Of Websites"))

local i = "/etc/adblocklist/adblock"
e = t:taboption("weblist", TextValue, "adblock_domain")
e.description = translate("These had been joined websites will use filter,but only blacklist model.Please input the domain names of websites,every line can input only one website domain.For example,google.com.")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adblock", value)
	if (luci.sys.call("cmp -s /tmp/adblock /etc/adblocklist/adblock") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adblock")
end

t:tab("white_iplist",translate("IP???????????????"))

local i = "/etc/adblocklist/adbypassip"
e = t:taboption("white_iplist", TextValue, "adbypass_ip")
e.description = translate("These had been joined ip addresses will use proxy, but only GFW model.Please input the ip address or ip address segment,every line can input only one ip address.For example,112.123.134.145/24 or 112.123.134.145.")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adbypassip", value)
	if (luci.sys.call("cmp -s /tmp/adbypassip /etc/adblocklist/adbypassip") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adbypassip")
end

t:tab("iplist",translate("IP???????????????"))

local i = "/etc/adblocklist/adblockip"
e = t:taboption("iplist", TextValue, "adblock_ip")
e.description = translate("These had been joined ip addresses will not use filter.Please input the ip address or ip address segment,every line can input only one ip address.For example,112.123.134.145/24 or 112.123.134.145.")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/adblockip", value)
	if (luci.sys.call("cmp -s /tmp/adblockip /etc/adblocklist/adblockip") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/adblockip")
end

t:tab("customlist", translate("Set Backlist Of custom"))

local i = "/usr/share/koolproxy/data/user.txt"
e = t:taboption("customlist", TextValue, "user_rule")
e.description = translate("Enter your custom rules, each row.")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
	if value then
		value = value:gsub("\r\n", "\n")
	else
		value = ""
	end
	fs.writefile("/tmp/user.txt", value)
	if (luci.sys.call("cmp -s /tmp/user.txt /usr/share/koolproxy/data/user.txt") == 1) then
		fs.writefile(i, value)
	end
	fs.remove("/tmp/user.txt")
end

t:tab("logs",translate("View the logs"))

local i = "/var/log/koolproxy.log"
e = t:taboption("logs", TextValue, "kpupdate_log")
e.description = translate("Koolproxy Logs")
e.rows = 28
e.wrap = "off"
e.rmempty = false

function e.cfgvalue()
	return fs.readfile(i) or ""
end

function e.write(self, section, value)
end

t=o:section(TypedSection,"acl_rule",translate("KoolProxy ????????????"),
translate("ACLs is a tools which used to designate specific IP filter mode,The MAC addresses added to the list will be filtered using https"))
t.template="cbi/tblsection"
t.sortable=true
t.anonymous=true
t.addremove=true
e=t:option(Value,"remarks",translate("Client Remarks"))
e.width="30%"
e.rmempty=true
e=t:option(Value,"ipaddr",translate("IP Address"))
e.width="20%"
e.datatype="ip4addr"
luci.ip.neighbors({family = 4}, function(neighbor)
	if neighbor.reachable then
		e:value(neighbor.dest:string(), "%s (%s)" %{neighbor.dest:string(), neighbor.mac})
	end
end)
e=t:option(Value,"mac",translate("MAC Address"))
e.width="20%"
e.rmempty=true
e.datatype="macaddr"
luci.ip.neighbors({family = 4}, function(neighbor)
	if neighbor.reachable then
		e:value(neighbor.mac, "%s (%s)" %{neighbor.mac, neighbor.dest:string()})
	end
end)
e=t:option(ListValue,"proxy_mode",translate("????????????"))
e.width="20%"
e.default=1
e.rmempty=false
e:value(0,translate("?????????"))
e:value(1,translate("http only"))
e:value(2,translate("http + https"))
e:value(3,translate("full port"))

t=o:section(TypedSection,"rss_rule",translate("KoolProxy ????????????"), translate("?????????????????????????????????"))
t.anonymous=true
t.addremove=true
t.sortable=true
t.template="cbi/tblsection"
t.extedit=luci.dispatcher.build_url("admin/services/koolproxy/rss_rule/%s")

t.create=function(...)
	local sid=TypedSection.create(...)
	if sid then
		luci.http.redirect(t.extedit % sid)
		return
	end
end

e=t:option(Flag,"load",translate("??????"))
e.default=0
e.rmempty=false

e=t:option(DummyValue,"name",translate("????????????"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

e=t:option(DummyValue,"url",translate("????????????"))
function e.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

e=t:option(DummyValue,"time",translate("????????????"))

function Download()
	local t,e
	t=nixio.open("/tmp/upload/koolproxyca.tar.gz","r")
	luci.http.header('Content-Disposition','attachment; filename="koolproxyCA.tar.gz"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end
local t,e
t="/tmp/upload/"
nixio.fs.mkdir(t)
luci.http.setfilehandler(
function(o,a,i)
	if not e then
		if not o then return end
		e=nixio.open(t..o.file,"w")
		if not e then
			return
		end
	end
	if a and e then
		e:write(a)
	end
	if i and e then
		e:close()
		e=nil
		luci.sys.call("/usr/share/koolproxy/camanagement restore 2>&1 >/dev/null")
	end
end
)
return o
