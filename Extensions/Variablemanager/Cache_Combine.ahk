cache_Combine_hook_Datastore(ExtendedBy,VariableFunc,Var_Info,byref Value,nat_varinstance,name)
{
	combinekey:=this.datastore_get("Combine_Key","datastore_Combine","Shift")
	getkeystate, keystate, %combinekey%
	if(keystate == "D")
	{
		currentvalue:=this.datastore_get(nat_varinstance,"VCache")
		if(currentvalue != "")
		{
			StringReplace, nVariableFunc,VariableFunc,.,#,All
			separator:=this.datastore_get("Separator_" nVariableFunc,"datastore_Combine",",")
			Value.=separator currentvalue
		}
	}
}
cache_Combine_hook_extension_Configure(ExtendedBy)
{
	editinfo:=Array()
	this.datastore_set("Combine_Key","datastore_Combine",this.datastore_get("Combine_Key","datastore_Combine","Shift"))
	editinfo.push({Variable:"Combine_Key",inputtype: "DropdownList",Dropdownlist:"|Shift|Ctrl|Alt",help:"What key should be pressed down for the cached Variable Value is combined with the New Variable Value?`n(Default is Shift)"})
	Variable_Functions:=this.datastore_get("Variable_Functions","",Array())
	loop % Variable_Functions.MaxIndex()
	{
		VariableFunc:=Variable_Functions[A_Index]
		StringReplace, nVariableFunc,VariableFunc,.,#,All
		this.datastore_set("Separator_" nVariableFunc,"datastore_Combine",this.datastore_get("Separator_" nVariableFunc,"datastore_Combine",","))
		editinfo.push({Variable: "Separator_" nVariableFunc,prompt:"What should separate the new cached value from the old cached value of " VariableFunc " values?"})
	}
	this.config_edit("module_extensionmanager.module_configure",editinfo,"datastore_Combine")
}