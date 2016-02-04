	log_isLevel(LogLevel)	{
	if(this.Extension_module(A_thisfunc) != this.__Class)
		{
			module:=this.Extension_module(A_thisfunc)
			return %module%.log_isLevel(LogLevel)
		}
		logmode:=this.datastore_get("mode","log")
		this.log_Level_Convert(LogLevel)
		if(instr(logmode,","))
		{
			if LogLevel in %logmode%
				return 1
		}
		else if( LogLevel == logmode)
			return 1
		return 0
	}
	log_set_Level(LogLevel)	{
		this.log_Level_Convert(LogLevel)
		this.datastore_set("mode","log",LogLevel)
	}
	log_Level_Convert(byref Loglevel)	{
		StringLower,LogLevel,LogLevel
		if(instr(LogLevel,","))
		{
			loop,parse, Loglevel,`,
			{
				if A_Loopfield in emergencies,emergency,emerg,0
					output:=output == ""?"0":",0"
				else if A_Loopfield in alerts,alert,1
					output:=output == ""?"1":",1"
				else if A_Loopfield in criticals,critical,crit,2
					output:=output == ""?"2":",2"
				else if A_Loopfield in errors,error,err,3
					output:=output == ""?"3":",3"
				else if A_Loopfield in warnings,warning,warn,4
					output:=output == ""?"4":",4"
				else if A_Loopfield in notifications,notification,notice,5
					output:=output == ""?"5":",5"
				else if A_Loopfield in informations,information,info,6
					output:=output == ""?"6":",6"
				else if A_Loopfield in debugs,debug,7
					output:=output == ""?"7":",7"
			}
		}
		else if Loglevel in emergencies,emergency,emerg,0
			output:="0"
		else if Loglevel in alerts,alert,1
			output:="1"
		else if Loglevel in criticals,critical,crit,2
			output:="2"
		else if Loglevel in errors,error,err,3
			output:="3"
		else if Loglevel in warnings,warning,warn,4
			output:="4"
		else if Loglevel in notifications,notification,notice,5
			output:="5"
		else if Loglevel in informations,information,info,6
			output:="6"
		else if Loglevel in debugs,debug,7
			output:="7"
		Loglevel:=output
	}
	log_log(LogFunction,LogMessage:="",prependtoLogMessage:="",LogLevel:="6")	{
		static logfile:=""
		if(this.Extension_module(A_thisfunc) != this.__Class)
		{
			module:=this.Extension_module(A_thisfunc)
			return %module%.log_log(LogFunction,LogMessage,AppendtoLogMessage,LogLevel)
			
		}
		if(LogMessage == "")
			LogMessage:=A_LastError
		if(this.log_isLevel(LogLevel))
		{
			timestampformat:=this.datastore_get("timestampformat","log","dd-MM-HH-mm-ss")
			FormatTime, timestamp,%timestampformat%
			if(logfile == "")
			{
				FileCreateDir, %A_ScriptDir%\logs\	;Creates Log directory
				logfile:=A_ScriptDir "\logs\" this.__Class "-" timestamp ".log"
				FileAppend,t:<Timestamp>-f:<LogFunction>-l:<LogLevel>-m:<LogMessage>, %logfile%
			}
			LogMessage:=isObject(LogMessage)?this.module_format_toString(LogMessage):LogMessage
			FileAppend,t:%timestamp%-f:%LogFunction%-l:%LogLevel%-m:%prependtoLogMessage%%LogMessage%, %logfile%
		}
		if(LogLevel == 0)
		{
			ExtensionModule:=this.Extension_module(A_thisfunc)
			prependtoLogMessage:=prependtoLogMessage == ""? : prependtoLogMessage "`n"
			msgbox, 16,  Logged - %ExtensionModule%,LogLevel: %LogLevel%`nLogFunction: %LogFunction%`nLogMessage: %prependtoLogMessage%%LogMessage%
		}
	}
	log_debug(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,7)
	}
	log_info(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,6)
	}
	log_notice(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,5)
	}
	log_warn(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,4)
	}
	log_err(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,3)
	}
	log_crit(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,2)
	}
	log_alert(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,1)
	}
	log_emerg(LogFunction,LogMessage:="",prependtoLogMessage:="")	{
		return this.log_log(LogFunction,LogMessage,prependtoLogMessage,0)
	}