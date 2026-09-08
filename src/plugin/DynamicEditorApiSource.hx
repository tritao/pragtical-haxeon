package plugin;

class DynamicEditorApiSource {
	public static final CONTENT = "package pragtical;\n"
		+ "@:hlNative(\"pragtical_hx\", \"plugin_api_call\") extern function hostCall(operation:Int, token:String, a:String, b:String, c:String):String;\n"
		+ "class Editor {\n"
		+ "  public static inline final API_VERSION = 2;\n"
		+ "  static var token:String = \"\";\n"
		+ "  public static function connect(id:String):Void { token = hostCall(0, \"\", id, \"\", \"\"); }\n"
		+ "  public static function activeDocumentText():String return hostCall(1, token, \"\", \"\", \"\");\n"
		+ "  public static function replaceSelections(text:String):Bool return hostCall(2, token, text, \"\", \"\") == \"1\";\n"
		+ "  public static function addPanel(id:String, title:String, text:String):Bool return hostCall(3, token, id, title, text) == \"1\";\n"
		+ "  public static function setPanelText(id:String, text:String):Bool return hostCall(4, token, id, text, \"\") == \"1\";\n"
		+ "  public static function onDocumentChanged(functionName:String):Bool return hostCall(5, token, functionName, \"\", \"\") == \"1\";\n"
		+ "  public static function configuration(name:String):String return hostCall(6, token, name, \"\", \"\");\n"
		+ "  public static function addStatusItem(id:String, text:String, priority:String = \"0\"):Bool return hostCall(7, token, id, text, priority) == \"1\";\n"
		+ "  public static function setStatusItemText(id:String, text:String):Bool return hostCall(8, token, id, text, \"\") == \"1\";\n"
		+ "  public static function addDecoration(id:String, range:String, color:String):Bool return hostCall(9, token, id, range, color) == \"1\";\n"
		+ "}\n";
}
