import game.Playfield;
import haxe.Rest;
import hxd.App;

class Main extends hxd.App {
    public static var instance(default, null) : Main = null;

    private var inputManager : InputManager;

    public var scene(default, null) : Scene;
    private var nextScene : Scene;
    private var entities : Array<Entity>;
    @:allow(Entity.dontDestroy)
    private var dontDestroy : Array<Entity>;

    private var fixedAccum : Float;
    private var time : Float;

    private static function main():Void {
        new Main();
    }

    private function new():Void {
        super();
        instance = this;
        entities = new Array();
        dontDestroy = new Array();
        fixedAccum = 0.0;
    }

    private override function init():Void {
        #if debug
        hxd.Res.initLocal();
        hxd.res.Resource.LIVE_UPDATE = true;
        #else
        hxd.Res.initPak();
        #end
        s2d.scaleMode = LetterBox(320, 180, true, Center, Center);
        inputManager = new InputManager();
        inputManager.addAction(Types.InputActions.MoveUp, [ InputManager.ActionInput.Down(hxd.Key.UP) ]);
        inputManager.addAction(Types.InputActions.MoveDown, [ InputManager.ActionInput.Down(hxd.Key.DOWN) ]);
        inputManager.addAction(Types.InputActions.MoveRight, [ InputManager.ActionInput.Down(hxd.Key.RIGHT) ]);
        inputManager.addAction(Types.InputActions.MoveLeft, [ InputManager.ActionInput.Down(hxd.Key.LEFT) ]);
        inputManager.addAction(Types.InputActions.Focus, [ InputManager.ActionInput.Down(hxd.Key.SHIFT) ]);
        inputManager.addAction(Types.InputActions.Shoot, [ InputManager.ActionInput.Pressed(hxd.Key.Z) ]);
        changeScene(Playfield, []);
    }

    private override function update(dt: Float):Void {
        time += dt;
        inputManager.update();
        fixedAccum += dt;
        for (ent in entities)
            if (ent.markedForDeletion) {
                ent.destroyed(s2d);
                entities.remove(ent);
            }
        if (nextScene != null) {
            if (scene != null) scene.exited(s2d);
            for (ent in entities) ent.scene = nextScene;
            scene = nextScene;
            scene.entered(s2d);
            nextScene = null;
        }
        for (ent in entities) ent.preUpdate();
        for (ent in entities) if (!ent.markedForDeletion) ent.update(dt);
        var fixedDelta = 1.0 / Const.FIXED_FPS;
        for (i in 0...Const.FIXED_ITERATIONS) {
            for (ent in entities) if (!ent.markedForDeletion) ent.fixedUpdate(fixedDelta);
            if (fixedAccum >= fixedDelta) fixedAccum -= fixedDelta;
            else break;
        }
        for (ent in entities) ent.render();
    }

    @:allow(Scene.spawnEntity)
    private function addEntity(ent: Entity):Void {
        if (entities.contains(ent)) return;
        entities.push(ent);
        ent.added(s2d);
    }

    public function changeScene<T:Scene>(cl: Class<T>, args: Rest<Any>):Void {
        if (nextScene != null) throw "Can't change scene multiple times at once!";
        final scene = Type.createInstance(cl, args);
        for (ent in entities) {
            if (dontDestroy.contains(ent)) dontDestroy.remove(ent);
            else ent.destroy();
        }
        nextScene = scene;
    }

    inline public function getEntities():Iterator<Entity> {
        return entities.iterator();
    }
}