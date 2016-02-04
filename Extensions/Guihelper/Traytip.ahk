	traytip(title:="",text:="",seconds:=10,options:=16,forced:=0)
	{
		static cache:=Array()
		if(title == "" and text == "" and seconds == 10 and options == 16 and forced == 0)
		{
			if(cache.length() > 0)
			{
				title:=cache.title,	text:=cache.text,	seconds:=cache.seconds,	options:=cache.options
				cache:=array()
				TrayTip,%title%,%text%,%seconds%,%options%
			}
			return
		}
		if(!cache.forced)
		{
			if(forced)
			{
				cache.forced:=forced,cache.title:=title,cache.text:=text,cache.seconds:=seconds,cache.options:=options
			}
			else if(cache.title == "" and cache.text == "")
			{
				cache.title:=title,	cache.text:=text,	cache.seconds:=seconds,	cache.options:=options
			}
			else if(!cache.multiple)
			{
				cache.multiple:=1,	cache.seconds:=this.datastore_get("multiple_seconds","traytip",10), cache.options:=this.datastore_get("multiple_option","traytip",16), cache.text:= "*" cache.title " - " cache.text, cache.title:="Multiple Notifications"
			}
			if(cache.multiple)
				cache.text.="`n*"title " - " text
		}
		this.Notifier_aggregate(A_thisfunc)
	}
	traytip_trimmed(title:="",text:="",seconds:=10,options:=16,trimlength:="", forced:=0)
	{
		trimlength:=trimlength is number? trimlength : this.datastore_get("trimmed_default","traytip",30)
		if(strlen(text) > trimlength)
			text:=substr(text,1,trimlength-3) "..."
		this.traytip(title,text,seconds,options,forced)
	}
	traytip_hook_extension_configure(extendedby)
	{
		editinfo:=Array()
		editinfo.push({Variable:"Multiple_Seconds",type:"integer",prompt:"When there are multiple notifications being aggregated, how many seconds should the notification be displayed?`n(Default is 10 - Look at AutoHotkey Documentation for more info)"})
		editinfo.push({Variable:"Multiple_Options",type:"integer",prompt:"When there are multiple notifications being aggregated, what traytip option should be used? `n(Default is 16 - Look at AutoHotkey Documentation for more info)"})
		editinfo.push({Variable:"Trimmed_Default",type:"integer",prompt:"When you are using trimmed traytip, how many characters should it be trimmed to if not specified? `n(Default is 30)"})
		this.config_edit("module_extensionmanager.module_configure",editinfo,"traytip")
	}