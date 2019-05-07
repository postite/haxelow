import tjson.TJSON;

class Main{
public function new(){
    var db= new HaxeLow("db.json");
    var cop=new Cop();
    cop.id="1";
    cop.data="onep";
    cop.annex="alea";
    var cops=db.idCol(Cop);
    if( !cops.idInsert(cop) )
    cops.idUpdate("1",{data:"dussi"});
    
    


    db.save();
}
static public function main():Void
{
//     var p=new Cop();
//    var tj= TJSON.encode(p);
//     trace(tj);
   new Main();
}
}

class Cop{
    public function new(){

    }
        public var id:String="";
        public var annex:String="";
        public var data:String="";
}