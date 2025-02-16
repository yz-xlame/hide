package hide.comp;

class CodeEditor extends Component {

	static var INIT_DONE = false;
	static var COMPLETIONS = [];

	var lang : String;
	var editor : monaco.ScriptEditor;
	var errorMessage : Element;
	var currrentDecos : Array<String> = [];
	public var code(get,never) : String;
	public var propagateKeys : Bool = false;
	public var saveOnBlur : Bool = true;

	public function new( code : String, lang : String, ?parent : Element, ?root : Element ) {

		if( !INIT_DONE ) {
			INIT_DONE = true;
			// disable default completion
			(monaco.Languages : Dynamic).typescript.javascriptDefaults.setModeConfiguration({ completionItems : false });
			(monaco.Languages : Dynamic).html.htmlDefaults.setModeConfiguration({ completionItems : false });
			(monaco.Languages : Dynamic).css.lessDefaults.setModeConfiguration({ completionItems : false });
		}

		super(parent,root);
		var root = element;
		this.lang = lang;
		root.addClass("codeeditor");
		root.on("keydown", function(e) {
			if( e.keyCode == 27 && root.find(".suggest-widget.visible").length == 0 ) onClose();
			if( !propagateKeys ) e.stopPropagation();
		});
		editor = monaco.ScriptEditor.create(root[0],{
			value : code,
			language : lang == null ? "javascript" : lang,
			automaticLayout : true,
			wordWrap : true,
			minimap : { enabled : false },
			theme : "vs-dark",
			lineNumbersMinChars: 3,
			fontSize: "13px",
			mouseWheelZoom: true,
			scrollBeyondLastLine: false
		});
		var model = editor.getModel();
		(model : Dynamic).__comp__ = this;
		model.updateOptions({ insertSpaces:false, trimAutoWhitespace:true });
		editor.onDidChangeModelContent(function() onChanged());
		editor.onDidBlurEditorText(function() if( saveOnBlur ) onSave());
		editor.addCommand(monaco.KeyCode.KEY_S | monaco.KeyMod.CtrlCmd, function() { saveBind(); });
		errorMessage = new Element('<div class="codeErrorMessage"></div>').appendTo(root).hide();
	}

	function saveBind() {
		clearSpaces();
		onSave();
		customCtrlSBehavior();
	}

	public dynamic function customCtrlSBehavior() {
	}

	function initCompletion( ?chars ) {
		if( COMPLETIONS.indexOf(lang) < 0 ) {
			COMPLETIONS.push(lang);
			monaco.Languages.registerCompletionItemProvider(lang, {
				triggerCharacters : chars,
				provideCompletionItems : function(model,position,_,_) {
					var comp : CodeEditor = (model : Dynamic).__comp__;
			        var code = model.getValueInRange({startLineNumber: 1, startColumn: 1, endLineNumber: position.lineNumber, endColumn: position.column});
					var res = comp.getCompletion(code.length);
					for( r in res )
						if( r.insertText == null )
							r.insertText = r.label;
					return { suggestions : res };
				}
			});
		}
	}

	function getCompletion( position : Int ) : Array<monaco.Languages.CompletionItem> {
		return [];
	}

	function clearSpaces() {
		var code = code;
		var newCode = [for( l in StringTools.trim(code).split("\n") ) StringTools.rtrim(l)].join("\n");
		if( newCode != code ) {
			var p = editor.getPosition();
			setCode(newCode);
			editor.setPosition(p);
		}
	}

	function get_code() {
		return editor.getValue({preserveBOM:true});
	}

	public function setCode( code : String ) {
		editor.setValue(code);
	}

	public function focus() {
		editor.focus();
	}

	public dynamic function onChanged() {
	}

	public dynamic function onSave() {
	}

	public dynamic function onClose() {
	}

	public function clearError() {
		if( currrentDecos.length != 0 )
			currrentDecos = editor.deltaDecorations(currrentDecos,[]);
		errorMessage.toggle(false);
	}

	public function setError( msg : String, line : Int, pmin : Int, pmax : Int ) {
		var linePos = code.substr(0,pmin).lastIndexOf("\n");
		if( linePos < 0 ) linePos = 0 else linePos++;
		var range = new monaco.Range(line,pmin + 1 - linePos,line,pmax + 2 - linePos);
		currrentDecos = editor.deltaDecorations(currrentDecos,[
			{ range : range, options : { inlineClassName: "codeErrorContentLine", isWholeLine : true } },
			{ range : range, options : { linesDecorationsClassName: "codeErrorLine", inlineClassName: "codeErrorContent" } }
		]);
		errorMessage.html([for( l in msg.split("\n") ) StringTools.htmlEscape(l)].join("<br/>"));
		errorMessage.toggle(true);
		var rect = errorMessage[0].getBoundingClientRect();
		if( rect.bottom > js.Browser.window.innerHeight )
			errorMessage[0].scrollIntoView(false);
	}

}