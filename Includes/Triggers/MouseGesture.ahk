Include_Trigger_MouseGesture(){
module_dependency.include("Hotkey","Trigger")
module_manager.module_reg("module_mousegesture")
}
Class module_mousegesture extends module_base_trigger{
	static module_version:= 1.0
	static module_about:="MouseGesture is a Trigger for MouseGestures. `nOriginally by Learning one (Boris Mudrinić)`nModified for Harmony Compatibility by Electrocret"
	static MouseGestureMinDistance:=9
	static MouseGestureDirLimit:=3
	static ConfigVariables:=Array("MouseGestureMinDistance","MouseGestureDirLimit")
	static mod_unregister_reload:=1
	#include *i %A_ScriptDir%\Generated\Extensions_MouseGesture.ahk
	trigger_reg(Listenkey,Gesture,Action)	{
		module_hotkey.trigger_reg(Listenkey,this.__Class)
		base.trigger_reg(Listenkey "_" Gesture, Action)
		return
	}
	trigger_unreg(Listenkey,Gesture,Action)	{
		base.trigger_unreg(Listenkey "_" Gesture,Action)
	}
	GetGesture(Angle) {
		Loop, 4
		{
			if (Angle <= 90*A_Index-45)
			{
				Sector := A_Index
				Break
			}
			Else if (A_Index = 4)
				Sector := 1
		}
		if Sector = 1
			Return "U"
		else if Sector = 2
			Return "R"
		else if Sector = 3
			Return "D"
		else if Sector = 4
			Return "L"
	}
	GetRadius(StartX, StartY, EndX, EndY) {
		a := Abs(endX-startX), b := Abs(endY-startY), Radius := Sqrt(a*a+b*b)
		Return Radius    
	}
	GetAngle(StartX, StartY, EndX, EndY) {
		x := EndX-StartX, y := EndY-StartY
		if (x = 0) {
			if y > 0
				Return 180
			Else if y < 0
				Return 360
			Else
				Return
		}
		Angle := ATan(y/x)*57.295779513
		if x > 0
			return Angle + 90
		else
			return Angle + 270	
	}
	Action(Action_Info, eventinfo)	{
		Listenkey:=eventinfo.event_name,	directive:=eventinfo.directive
		if directive in Register,Unregister,Initialize
			Return 0
		MouseGestureMinDistance:=this.MouseGestureMinDistance, MouseGestureDirLimit:=this.MouseGestureDirLimit
		Thread, NoTimers	
		CoordMode, mouse, screen
		MouseGetPos, mx1, my1, WinUMID, ControlUMClass
		Loop
		{
			Sleep, 20   
			if (GetKeyState(Listenkey, "p") = 0) {	
				if (Gesture = "")
					SendInput, {%Listenkey%}
				else
					this.trigger_fire(Listenkey "," Gesture,Listenkey "_" Gesture)
		
			
				EndX := "", EndY := "", Gesture := "", LastGesture := ""
				Return
			}
			MouseGetPos, EndX, EndY
			Radius := this.GetRadius(mx1, my1, EndX, EndY)
			if (Radius < MouseGestureMinDistance)
				Continue
			Angle := this.GetAngle(mx1, my1, EndX, EndY)
			MouseGetPos, mx1, my1
			CurGesture := this.GetGesture(Angle)
			if (CurGesture != LastGesture) {
				Gesture .= CurGesture
				LastGesture := CurGesture
				if (StrLen(Gesture) > MouseGestureDirLimit) {   
					EndX := "", EndY := "", Gesture := "", LastGesture := ""
					Progress, m2 b fs10 zh0 w80 WMn700, Gesture cancelled
					Sleep, 200
					KeyWait, %Listenkey%
					Progress, off
					Return
				}
			}
			if this.trigger_isreg(Listenkey "_A" Gesture)
			{
				if MoveMouseOnMGA	
				{
					Sleep, 30 
					if (StrLen(Gesture) = 1)	
						MouseMove, imx1, imy1  
					else	
						MouseMove, mx1, my1
				}
				this.trigger_fire(Listenkey "," Gesture,Listenkey "_" Gesture)
				return
			}		
		}
		EndX := "", EndY := "", Gesture := "", LastGesture := ""	
	}
	trigger_constructor(guiinfo:="")	{
		if(isobject(guiinfo))
		{
			if(guiinfo.GuiAction == "GuiClose" or GuiInfo.vDropdownList1 == "")
			{
				module_triggermanager.construct()
				return
			}
			direction:=substr(GuiInfo.vDropdownList1,1,1)
			GuiInfo.Gesture.=direction
			if(strlen(guiinfo.Gesture) == this.MouseGestureDirLimit or guiinfo.GuiAction == "Button2")
			{
				module_triggermanager.construct(GuiInfo.ListenKey "|" GuiInfo.Gesture)
				return
			}
			
			guiinfo.DropDownList1:=direction == "U" ? "Down|Left|Right" : direction == "D" ? "Up|Left|Right" : direction == "L" ? "Up|Down|Right" : "Up|Down|Left"
			nlen:=strlen(guiinfo.Gesture)
			nlen++
			msgbox %nlen%
			if(nlen == this.MouseGestureDirLimit)
			{
				guiinfo.Button1:=guiinfo.Button2,GuiInfo.groupbox1:="Last Direction"
				module_guitemplate.OneButtonDropdown(A_thisfunc,guiinfo)
			}
			else
			{
				GuiInfo.groupbox1:="Next Direction"
				module_guitemplate.TwoButtonDropdown(A_thisfunc,guiinfo)
			}
			return
		}
		InputBox, listenkey, ListenKey, What would you like the listen key to be? `n(Mouse Gestures begin listening when this button is pressed down.),,,,,,,,RButton
		if(!ErrorLevel)
		{
			ginfo:={Windowtitle: "Mouse Gesture",Button1: "Select and Continue",Button2: "Select and End Gesture",groupbox1: "First Direction",DropDownList1: "Up|Down|Left|Right",ListenKey:listenkey}
			module_guitemplate.OneButtonDropdown(A_thisfunc,ginfo)
			return
		}
		module_triggermanager.construct()
	}
	trigger_loader(loadmode, instance,action)	{
		StringGetPos, pos,Instance,|
		listenkey:=substr(instance,1,pos)
		pos:=pos+2
		gesture:=substr(instance,pos)
		if(loadmode)
			this.trigger_reg(listenkey,gesture,action)
		else
			this.trigger_unreg(listenkey,gesture,action)
	}
}
