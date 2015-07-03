import tjson.TJSON;

#if js
import js.Lib;
#end

using Lambda;

interface HaxeLowDisk {
	public function readFileSync(file : String) : String;
	public function writeFile(file : String, data : String) : Void;
}

#if js
class LocalStorageDisk implements HaxeLowDisk {
	public function new() {}

	public function readFileSync(file : String) 
		return js.Browser.getLocalStorage().getItem(file);

	public function writeFile(file : String, data : String)
		js.Browser.getLocalStorage().setItem(file, data);
}

class NodeJsDisk implements HaxeLowDisk {
	var steno : Dynamic;
	
	public function new() {
		this.steno = Lib.require('steno');
		if (this.steno == null) throw "Node.js error: package 'steno' not found. Please install with 'npm install --save steno'";
	}

	public function readFileSync(file : String) {
		var fs = Lib.require('fs');
		return fs.existsSync(file) ? fs.readFileSync(file, {encoding: 'utf8'}) : null;
	}

	public function writeFile(file : String, data : String) {
		steno.writeFile(file, data, function(_) {});
	}
}

class NodeJsDiskSync implements HaxeLowDisk {
	var steno : Dynamic;
	
	public function new() {
		this.steno = Lib.require('steno');
		if (this.steno == null) throw "Node.js error: package 'steno' not found. Please install with 'npm install --save steno'";
	}

	public function readFileSync(file : String) {
		var fs = Lib.require('fs');
		return fs.existsSync(file) ? fs.readFileSync(file, {encoding: 'utf8'}) : null;
	}

	public function writeFile(file : String, data : String) {
		steno.writeFileSync(file, data);
	}
}
#end

//////////////////////////////////////////////////////////////////////////

// Based on https://github.com/typicode/lowdb
class HaxeLow
{
	public static function uuid() {
		// Based on https://gist.github.com/LeverOne/1308368
	    var uid = new StringBuf(), a = 8;
        uid.add(StringTools.hex(Std.int(Date.now().getTime()), 8));
	    while((a++) < 36) {
	        uid.add(a*51 & 52 != 0
	            ? StringTools.hex(a^15 != 0 ? 8^Std.int(Math.random() * (a^20 != 0 ? 16 : 4)) : 4)
	            : "-"
	        );
	    }
	    return uid.toString().toLowerCase();
	}

	public var file(default, null) : String;

	var db : Dynamic;
	var checksum : String;
	var disk : HaxeLowDisk;

	public function new(?file : String, ?disk : HaxeLowDisk) {
		this.file = file;
		this.db = {};

		#if js
		// Node.js detection from http://stackoverflow.com/a/5197219/70894
		var isNode = untyped __js__("typeof module !== 'undefined' && module.exports");
		this.disk = (disk == null && file != null) 
			? (isNode ? new NodeJsDisk() : new LocalStorageDisk())
			: disk;
		#else
		this.disk = disk;
		#end

		if(this.file != null) {
			if(this.disk == null) throw 'HaxeLow: no disk storage set.';

			this.checksum = this.disk.readFileSync(this.file);
			if(this.checksum != null) try {
				this.db = TJSON.parse(checksum);
			} catch(e : Dynamic) {
				throw 'HaxeLow: JSON parsing failed: file "${this.file}" is corrupt. ' + e;
			}
		}
	}

	public function backup(?file : String) {
		var backup = TJSON.encode(db, 'fancy');
		if(file != null) disk.writeFile(file, backup);
		return backup;
	}
	
	public function restore(s : String) {
		db = TJSON.parse(s); 
		return this; 
	}

	public function save() : HaxeLow {
		if(file == null) return this;

		var data = backup();
		if(data == checksum) return this;

		checksum = data;
		disk.writeFile(file, data);

		return this;
	}

	public function col<T>(cls : Class<T>) : Array<T> {
		var name = Type.getClassName(cls);
		if(!Reflect.hasField(db, name)) {
			Reflect.setField(db, name, new Array<T>());
			save();
		}

		return cast Reflect.field(db, name);
	}

	public function keyCol<T, K>(cls : Class<T>, keyField : String, ?keyType : Class<K>) : HaxeLowCol<T, K>
		return new HaxeLowCol(col(cls), keyField);

	public function idCol<T : HaxeLowId<K>, K>(cls : Class<T>, ?keyType : Class<K>) : HaxeLowCol<T, K>
		return keyCol(cls, 'id', keyType);

	public function _idCol<T : HaxeLowDashId<K>, K>(cls : Class<T>, ?keyType : Class<K>) : HaxeLowCol<T, K>
		return keyCol(cls, '_id', keyType);
}

typedef HaxeLowId<K> = { public var id(default, null) : K; }
typedef HaxeLowDashId<K> = { public var _id(default, null) : K; }
