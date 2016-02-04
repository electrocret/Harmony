;Source of EmptyMem function: http://autohotkey.com/board/topic/30042-run-ahk-scripts-with-less-half-or-even-less-memory-usage/


EmptyMem(PID="AHK Rocks"){
    pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}
EmptyMem_hook_module_postinit(ExtendedModule){
	if(this.__class != "module_base")
		this.EmptyMem()	
}
EmptyMem_hook_module_init(ExtendedModule){
	if(ExtendedModule.__class == "module_actionmanager")
		ExtendedModule.reg("ActionManager.EmptyMem")
}
Action_Emptymem(Action_Info, Eventinfo){
	directive:=eventinfo.directive
	if(directive == "Execute")
	{
		if(Action_Info == "")
			this.EmptyMem()
		else
			this.EmptyMem(Action_Info)
		return
	}
	if(directive == "Wizard")
	{
		msgbox,4,EmptyMem,Would you like to empty the memory for this script?
		ifmsgbox, no
		{
			Inputbox, toclear,EmptyMem, What Process ID would you like to clear the memory for?
			if(Errorlevel)
				module_actionmanager.wizard()
		}
		module_actionmanager.wizard(toclear)
	}
	if(directive == "Initialize")
		return "Wizard"
}