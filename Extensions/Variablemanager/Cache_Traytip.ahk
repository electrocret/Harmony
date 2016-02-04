cache_Traytip_hook_Datastore(ExtendedBy,VariableFunc,Var_Info,Value,nat_varinstance,name)
{
	if(name != "")
		module_guihelper.traytip_trimmed("V-" name, Value)
}
cache_Traytip_hook_init(ExtendedBy)
{
	this.extension_priority("datastore_Traytip",this.datastore_Get("Priority_Highest","Extension",0)++)
	module_dependency.Extension("guihelper","traytip")
}