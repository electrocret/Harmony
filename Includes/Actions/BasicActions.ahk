Include_Action_BasicActions()
{
	module_actionmanager.reg("Label","Function","SendInput","Send","SendRaw","SendPlay","Msgbox","Suspend","Reload","Run","Explore","Find","Edit","Sleep","SendLevel")
}

Action_Label(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
		if(islabel(Action_Info))
			goto, %Action_Info%
	if(directive == "Wizard")
	{
		Inputbox, nlabel, Label Name, What Label would you like to call?
		if(Errorlevel)
			module_actionmanager.wizard()
		else if(!islabel(nlabel))
		{
			msgbox,,Label Error, Error! %nlabel% not found.
			Action_Label(Action_Info,Eventinfo)
		}
		else
		 module_actionmanager.wizard(nlabel)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_Function(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		StringSplit, v, Action_Info, |
		module_funchelper.module_func_exec(v1,v2,v3,v4,v5,v6,v7,v8,v9,v10)
	}
	if(directive == "Wizard")
	{
		Inputbox, function, Function Name, What Function would you like to call?
		if(Errorlevel)
			module_actionmanager.wizard()
		else if(!isfunc(function))
		{
			msgbox ,,Function Error, Error! %function% not found.
			Action_Function(Action_Info,Eventinfo)
		}
		else
		{
			paramcount:=isfunc(Function)
			ifinString, function, .
				paramcount --
			Loop, %paramcount%
			{
				Inputbox, param, Parameter %A_Index%, What should Parameter %A_Index% be?
				params.="|" param
			}
			module_actionmanager.wizard(function params)
		}
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
	
}
Action_SendInput(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		SendInput %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, toinput, Send Input, What Input would you like to send?
		if(Errorlevel)
			module_actionmanager.wizard()
		module_actionmanager.wizard(toinput)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_Send(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		Send %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, toinput, Send , What Input would you like to send?
		if(Errorlevel)
			module_actionmanager.wizard()
		module_actionmanager.wizard(toinput)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_SendRaw(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		SendRaw %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, toinput, Send Raw, What Raw Input would you like to send?
		if(Errorlevel)
			module_actionmanager.wizard()
		module_actionmanager.wizard(toinput)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_SendPlay(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		SendPlay %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, toinput, Send Play, What Input would you like to send?
		if(Errorlevel)
			module_actionmanager.wizard()
		module_actionmanager.wizard(toinput)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_Msgbox(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		msgbox,,Message Box, %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, todisplay, Message Box, What would you like to display in the Message box?
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		module_actionmanager.wizard(todisplay)
	}
	if(directive == "Initialize")
		return "Wizard"
}
Action_Suspend(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
		module_guihelper.suspend()
	if(directive == "Wizard")
		module_actionmanager.wizard()
	if(directive == "Initialize")
		return "Wizard"
}
Action_reload(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		reload
	}
	if(directive == "Wizard")
	{
		module_actionmanager.wizard()
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_run(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		IfExist, %Action_Info%
			Run %Action_Info%
		else
			module_funchelper.debug_errorlog("Action_Run unable to find Target: " Action_Info) 
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, runtarget, Run - Target, What is the Run Target?
		if(Errorlevel)
			module_actionmanager.wizard()
		module_actionmanager.wizard(runtarget)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_explore(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		run, explore %Action_Info%
	}
	if(directive == "Wizard")
	{
		Inputbox, directory, Explore - Directory, What Directory do you want to open?
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		module_actionmanager.wizard(directory)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_find(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		Run, find %Action_Info%
		return 
	}
	if(directive == "Wizard")
	{
		Inputbox, search, Find, What do you want to find?
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		module_actionmanager.wizard(search)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_edit(Action_Info,Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		Run, edit %Action_Info%
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, editfile, Edit, What file do you want to edit?
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		module_actionmanager.wizard(editfile)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_Sleep(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		if Action_Info is number
			Sleep, %Action_Info%
		else
			module_funchelper.log_err(A_thisfunc,Action_Info,"Not Number:")
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, sleeptime, Sleep, How many milliseconds do you want the script to sleep?
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		else if sleeptime is not number
		{
			msgbox,,Sleep Error, Error! %sleeptime% is not a number.
			Action_Sleep(Action_Info,Eventinfo)
		}
		module_actionmanager.wizard(sleeptime)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}
Action_SendLevel(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		if Action_Info is number
			SendLevel, %Action_Info%
		else
			module_funchelper.log_err(A_thisfunc,Action_Info,"Not Number:")
		return
	}
	if(directive == "Wizard")
	{
		Inputbox, soundlevel, Send Level, What should the Sound Level be?`n(Number must be between 0-100)
		if(Errorlevel)
		{
			module_actionmanager.wizard()
		}
		else if(soundlevel >= 0 and soundlevel <= 100
		{
			msgbox,,SoundLevel Error, Error! %soundlevel% is not between 0 and 100.
			Action_SendLevel(Action_Info,Eventinfo)
		}
		module_actionmanager.wizard(soundlevel)
		return
	}
	if(directive == "Initialize")
	{
		return "Wizard"
	}
}