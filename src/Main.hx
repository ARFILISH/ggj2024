import game.Playfield;
import haxe.Rest;
import hxd.App;

class Main extends hxd.App {
    public static var instance(default, null) : Main = null;

    private var inputManager : InputManager;
    private var audioManager : AudioManager;

    public var scene(default, null) : Scene;
    private var nextScene : Scene;
    private var entities : Array<Entity>;
    @:allow(Entity.dontDestroy)
    private var dontDestroy : Array<Entity>;

    private var fixedAccum : Float;

    public var hud(default, null) : h2d.Scene;

    public var save(default, null) : { firstGame : Bool, bestScore : Int, soundVolume : Float, musicVolume : Float };

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

    private override function onResize():Void {
        s2d.scaleMode = LetterBox(320, 180, true, Center, Center);
    }

    private override function loadAssets(onLoaded: Void->Void):Void {
        new hxd.fmt.pak.Loader(s2d, onLoaded);
    }

    private override function init():Void {
        save = hxd.Save.load({ firstGame : true, bestScore : 0, soundVolume : 1.0, musicVolume : 1.0 });
        hud = new h2d.Scene();
        s2d.scaleMode = hud.scaleMode = LetterBox(320, 180, true, Center, Center);
        inputManager = new InputManager();
        inputManager.addAction(Types.InputActions.MoveUp, [ InputManager.ActionInput.Down(hxd.Key.UP) ]);
        inputManager.addAction(Types.InputActions.MoveDown, [ InputManager.ActionInput.Down(hxd.Key.DOWN) ]);
        inputManager.addAction(Types.InputActions.MoveRight, [ InputManager.ActionInput.Down(hxd.Key.RIGHT) ]);
        inputManager.addAction(Types.InputActions.MoveLeft, [ InputManager.ActionInput.Down(hxd.Key.LEFT) ]);
        inputManager.addAction(Types.InputActions.Focus, [ InputManager.ActionInput.Down(hxd.Key.SHIFT) ]);
        inputManager.addAction(Types.InputActions.Shoot, [ InputManager.ActionInput.Pressed(hxd.Key.Z) ]);
        audioManager = new AudioManager();
        changeScene(Playfield, "stages/stage01.hscript");
        hxd.Window.getInstance().addResizeEvent(onResize);
        hxd.Window.getInstance().addEventTarget(onEvent);
    }

    private function onEvent(event: hxd.Event):Void {
        if (scene != null) scene.event(event);
        for (e in entities) if (!e.markedForDeletion) e.event(event);
    }

    public override function render(e:h3d.Engine):Void {
        s2d.render(e);
        hud.render(e);
    }

    private override function update(dt: Float):Void {
        inputManager.update();
        fixedAccum += dt;
        for (ent in entities)
            if (ent.markedForDeletion) {
                if (ent.onDestroyed != null) ent.onDestroyed(ent);
                ent.destroyed(s2d);
                entities.remove(ent);
            }
        if (nextScene != null) {
            if (scene != null) scene.exited(s2d);
            for (ent in entities) {
                ent.scene = nextScene;
                ent.sceneReloaded();
            }
            scene = nextScene;
            scene.entered(s2d);
            nextScene = null;
        }
        for (ent in entities) ent.preUpdate();
        for (ent in entities) if (!ent.markedForDeletion) ent.update(dt);
        var fixedDelta = 1.0 / Const.FIXED_FPS;
        for (_ in 0...Const.FIXED_ITERATIONS) {
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
            if (!dontDestroy.contains(ent)) ent.destroy();
        }
        nextScene = scene;
    }

    private override function dispose():Void {
        hxd.Save.save(save);
        super.dispose();
        hxd.Save.save(save);
        if (hud != null) hud.dispose();
    }

    inline public function getEntities():Iterator<Entity> {
        return entities.iterator();
    }
}