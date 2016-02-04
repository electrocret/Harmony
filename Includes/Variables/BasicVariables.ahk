Include_Variable_BasicVariables()
{
	module_variablemanager.reg("InputBox","Variable")
}
Variable_InputBox(Var_Info,EventInfo)
{
	if(EventInfo.Directive == "Translate")
	{
		if(isobject(Var_Info))
		{
			title:=Var_Info.Title,	Prompt:=Var_Info.Prompt,	Hide:=Var_Info.Hide,	Width:=Var_Info.Width,	Height:=Var_Info.Height,	X:=Var_Info.X,	Y:=Var_Info.Y,	Timeout:=Var_Info.Timeout,	Default:=Var_Info.Default
			InputBox, OutputVar , %Title%, %Prompt%, %HIDE%, %Width%, %Height%, %X%, %Y%,, %Timeout%, %Default%
		}
		else
			InputBox, OutputVar , InputBox, %Var_Info%
		return outputvar
	}
	if(EventInfo.Directive == "Wizard")
	{
		Inputbox, toask, Inputbox, What would you like to ask?
		if(Errorlevel)
			module_variablemanager.wizard()
		module_variablemanager.wizard(toask)
	}

	if(EventInfo.Directive == "Initialize")
		return "Wizard"
}
Variable_Variable(Var_Info,EventInfo)
{
	if(EventInfo.Directive == "Translate")
	{
		return %Var_Info%
	}
	if(EventInfo.Directive == "Wizard")
	{
		Inputbox, vari, Variable, What variable would you like to reference?
		if(Errorlevel)
			module_variablemanager.wizard()
		module_variablemanager.wizard(vari)
	}

	if(EventInfo.Directive == "Initialize")
		return "Wizard"
}