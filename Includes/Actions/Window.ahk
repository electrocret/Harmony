Include_Action_Window()
{
	module_includer.dependentTrigger("Hotkeys")
	module_actionmanager.reg("WindowMemory","PreviousWindow","OpenBrowser","OpenWindow")
}
Action_OpenWindow(Action_Info,Eventinfo)
{
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		if(isobject(Action_Info))
		{
			title:=Action_Info.title
			exec:=Action_Info.Execute
		}
		else
		{
			StringSplit, v, Action_Info, |
			title:=v1
			exec:=v2
		}
		SetTitleMatchMode, 2
		Action_PreviousWindow("Store",Eventinfo)
		IfWinExist %title%
		{
			WinActivate %title%
		}
		else
		{
			if exec not contains .exe,.bat,.lnk,.txt,.doc,.xls,.ahk
			{
				Action_openBrowser(Action_Info,Eventinfo)
			}
			else
			{
				ifexist, %exec%
					Run %exec%
			}
		}

	}
	if(directive == "Initialize")
	{
		Hotkeys.reg("~LButton","WindowMonitor")
	}
}
Action_OpenBrowser(Action_Info,Eventinfo)
{
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		if(isobject(Action_Info))
		{
			title:=Action_Info.title
			exec:=Action_Info.Execute
		}
		else
		{
			StringSplit, v, Action_Info, |
			title:=v1
			exec:=v2
		}
		browsers:=Action_WindowMonitor("Retrieve",Eventinfo)
		Action_PreviousWindow("Store",Eventinfo)
		chromeactive:=browsers.chromeactive, firefoxactive:=browsers.firefoxactive, internetexploreractive:=browsers.internetexploreractive
		found:="false"
		Loop, 3
		{
			if(chromeactive = A_Index && found = "false")
			{
				found:=Tab_WindowSearch(title,"- Google Chrome")
			}
			if(firefoxactive = A_Index && found = "false")
			{
				found:=Tab_WindowSearch(title,"- Mozilla Firefox")
			}
			if(internetexploreractive = A_Index && found = "false")
			{
				found:=Tab_WindowSearch(title,"- Windows Internet Explorer")
			}
			if(found = "true")
			{
				break
			}
		}
		if(found = "false")
		{
				Run %exec%
		}
	}
	if(directive == "Initialize")
	{
		Hotkeys.reg("~LButton","WindowMonitor")
	}
}
Action_PreviousWindow(Action_Info,Eventinfo)
{
	if(Action_Info == "Store")
	{
			WinGetActiveTitle, previous
			module_funchelper.var(A_ThisFunc,"Previous",previous)
			return
	}
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		Action_OpenWindow(module_funchelper.var(A_ThisFunc,"Previous"),Eventinfo)
	}
	if(directive == "Initialize")
	{
		Hotkeys.reg("~LButton","WindowMonitor")
	}
}
Action_WindowMemory(Action_Info,Eventinfo)
{
	storekey:=module_funchelper.config(A_ThisFunc,"Window","Memory_StoreKey","Ctrl")
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		storekey:=module_funchelper.config(A_ThisFunc,"Window","StoreKey",Ctrl)
		
		GetKeyState, state, %storekey%
		if state = D
		{
			WinGetActiveTitle, Title
			Window:=module_funchelper.var(A_ThisFunc,Action_Info,Title)
			;tooltip  Set - %Number% - %Title%
			;SetTimer, ReSetToolTip, 1000
		}
		else
		{
			Window:=module_funchelper.var(A_ThisFunc,Action_Info)
			Action_OpenWindow(Window,Eventinfo)
		}

	}
	if(directive == "Initialize")
	{
		module_funchelper.config_edit_dropdown("Window","Memory_StoreKey","|Ctrl|Shift")
		module_funchelper.config_description(A_ThisFunc,"Window","Memory_StoreKey","If this Button is pressed when the WindowMemory Action is called, then it will store that window in the memory space.")
		Hotkeys.reg("~LButton","WindowMonitor")
	}
}
Action_WindowMonitor(Action_Info,Eventinfo)
{
	storedbrowsers:=module_funchelper.var(A_ThisFunc,"Browsers")
	browsers:= isobject(storedbrowsers) ? storedbrowsers : array()
	if Action_Info in Retrieve
		return browsers
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		chromeactive:=browsers.chromeactive, firefoxactive:=browsers.firefoxactive, internetexploreractive:=browsers.internetexploreractive
		SetTitleMatchMode, 2
		Maxchecks:=3
		ifWinActive, - Google Chrome
		{
			if(chromeactive != 1)
			{
				browsers.chromeactive:=1

				if(firefoxactive < MaxChecks)
				{
					browsers.firefoxactive++
				}
				if(internetexploreractive < MaxChecks)
				{
					browsers.internetexploreractive++
				}
			
			}
		}
		ifWinActive, - Mozilla Firefox
		{
			if(firefoxactive != 1)
			{
				browsers.firefoxactive:=1

				if(chromeactive < MaxChecks)
				{
					browsers.chromeactive++
				}
				if(internetexploreractive < MaxChecks)
				{
					browsers.internetexploreractive++
				}
			
			}
		}
		ifWinActive, - Windows Internet Explorer
		{
			if(internetexploreractive != 1)
			{
				browsers.internetexploreractive:=1

				if(firefoxactive < MaxChecks)
				{
					browsers.firefoxactive++
				}
				if(chromeactive < MaxChecks)
				{
					browsers.chromeactive++
				}
			
			}
		}
		module_funchelper.var(A_ThisFunc,"Browsers",browsers)
	}
}
Tab_WindowSearch(name,windowtitle="",wintext="",wintitleexclude="",wintextexclude="",matchmode="2")
{
   	SetTitleMatchMode, %matchmode%
	WinGet, numOfWindows, Count, %windowtitle% ,%wintext%,%wintitleexclude%,%wintextexclude%
	Loop, %numofWindows%
	{
		WinActivateBottom, %windowtitle%,%wintext%,%wintitleexclude%,%wintextexclude%
		if(Tab_Search(name,matchmode) = "true")
		{
			return "true"
		}
	}
	return "false"
}
Tab_Search(name,matchmode="2")
{

        WinGetTitle, firstTabTitle, A ; The initial tab title
        WinGetTitle, title, A 
	if(matchmode = "3")
	{
	        Loop,50
	        {
	            if(title = name)
			{	
              		  return "true"
            		}
           		SendInput {Ctrl down}{Tab}{Ctrl up}
           		Sleep, 8
           		WinGetTitle, title, A  ;get active window title
           		if(InStr(firstTabTitle,title)>0)
			{
				return "false"
        		}
        	}
	}
	else
	{
	        Loop,50
	        {
	            if(InStr(title, name)>0){
	                return "true"
	            }
	            Send {Ctrl down}{Tab}{Ctrl up}
	            Sleep, 1
	            WinGetTitle, title, A  ;get active window title
	            if(InStr(firstTabTitle,title)>0){
			return "false"
	            }
	        }
	}
	return "false"		
}