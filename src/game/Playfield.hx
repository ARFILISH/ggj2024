package game;

class Playfield extends Scene {
    public var background(default, null) : heaps.Background;
    public var mainEnemy(default, null) : Enemy;
    public var player(default, null) : Player;
    public var itemManager(default, null) : ItemManager;

    private override function entered(s2d: h2d.Scene):Void {
        background = new heaps.Background();
        s2d.add(background, 0);
        player = spawnEntity(Const.PLAYER_START_X, Const.PLAYER_START_Y, Player);
        itemManager = spawnEntity(0.0, 0.0, ItemManager);
        if (Scenario.instance != null) loadScript(Scenario.instance.getCurrentScript());
        else loadScript("data/levels/level_01.hscript");
    }

    private override function exited(s2d: h2d.Scene):Void {
        mainEnemy.onDestroyed = null;
        player.onDestroyed = null;
        background.remove();
        itemManager.clear();
    }

    private function clear():Void {
        if (mainEnemy != null) {
            mainEnemy.destroy();
            player.canShoot = false;
        }
        itemManager.clear();
        background.clear();
    }

    private function loadScript(path: String):Void {
        if (path == null) throw 'Invalid script $path!';
        mainEnemy = spawnEntity(Const.ENEMY_BASE_X, Const.ENEMY_BASE_Y, Enemy);
        mainEnemy.loadScript(path);
        player.levelStarted();
    }
}