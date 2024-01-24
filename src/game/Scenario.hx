package game;

class Scenario extends Entity {
    public static var instance : Scenario;

    public var score(default, null) : Int;
    private var levels : List<String>;

    private override function added(s2d: h2d.Scene):Void {
        if (instance != null) {
            destroy();
            return;
        }
        instance = this;
        levels = new List();
        dontDestroy();
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        if (instance != this) return;
        instance = null;
        levels.clear();
        levels = null;
    }

    inline public function getCurrentScript():String
        return levels != null ? levels.first() : null;
}