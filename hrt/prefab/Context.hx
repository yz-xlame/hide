package hrt.prefab;

@:final class Context {

	public var local2d : h2d.Object;
	public var local3d : h3d.scene.Object;
	public var shared : ContextShared;
	public var cleanup(default, set) : Void -> Void;
	public var custom : Dynamic;

	/**
		isSceneReference is set to true when this
		context is a local reference to another prefab
		within the same scene.
	**/
	public var isSceneReference : Bool;

	public function new() {
	}

	function set_cleanup( fct : Void -> Void ) {
		this.cleanup = fct;
		if( fct != null && shared != null && shared.customCleanup != null )
			shared.customCleanup(this);
		return this.cleanup;
	}

	public function init( ?res : hxd.res.Resource ) {
		if( shared == null )
			shared = new ContextShared(res);
		local2d = shared.root2d;
		local3d = shared.root3d;
	}

	public function clone( p : Prefab ) {
		var c = new Context();
		c.shared = shared;
		c.local2d = local2d;
		c.local3d = local3d;
		c.custom = custom;
		c.isSceneReference = isSceneReference;
		if( p != null ) {
			if( !isSceneReference )
				shared.contexts.set(p, c);
			else @:privateAccess {
				var arr = shared.sceneReferences.get(p);
				if( arr == null ) {
					arr = [];
					shared.sceneReferences.set(p, arr);
				}
				arr.push(c);
			}
		}
		return c;
	}

	public function loadModel( path : String ) {
		return shared.loadModel(path);
	}

	public function loadAnimation( path : String ) {
		return shared.loadAnimation(path);
	}

	public function loadTexture( path : String ) {
		return shared.loadTexture(path);
	}

	public function loadShader( name : String ) {
		return shared.loadShader(name);
	}

	public function locateObject( path : String ) {
		if( path == null )
			return null;
		var parts = path.split(".");
		var root = shared.root3d;
		while( parts.length > 0 ) {
			var v = null;
			var pname = parts.shift();
			for( o in root )
				if( o.name == pname ) {
					v = o;
					break;
				}
			if( v == null ) {
				v = root.getObjectByName(pname);
				//if( v != null && v.parent != root ) v = null; ??
			}
			if( v == null ) {
				var parts2 = path.split(".");
				for( i in 0...parts.length ) parts2.pop();
				return null;
			}
			root = v;
		}
		return root;
	}

	#if editor
	public function setCurrent() {
		var shared = Std.downcast(shared, hide.prefab.ContextShared);
		if( shared == null ) throw "This context was not created by editor!";
		shared.scene.setCurrent();
	}
	#end

}
