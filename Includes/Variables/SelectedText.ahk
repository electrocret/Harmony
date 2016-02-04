

Variable_NumberByDigits(Var_Info,EventInfo)
{
	combinekey:=module_funchelper.config(A_thisfunc, "SelectedText","Combine Selected","Shift")
	if(EventInfo.Directive == "Initialize")
	{
		Trigger.reg("SelectedText", "module_variablemanager NumberByDigits")
		module_funchelper.config_description(A_thisfunc, "SelectedText","Combine Selected","When this key is pressed down, the previously selected number/s and newly selected number will be joined in a list.")
	}
	if(EventInfo.Directive == "Execute")
	{
		
	
	}
	if(EventInfo.Directive == "Translate")
	{
		InputBox, OutputVar , NumberByDigits, No %Var_Info% found. What would you like to use in its place?
		return OutputVar
	}
}