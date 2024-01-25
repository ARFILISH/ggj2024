package game;

class Playfield extends Scene {
    public var background(default, null) : heaps.Background;
    public var mainEnemy(default, null) : Enemy;
    public var player(default, null) : Player;
    public var itemManager(default, null) : ItemManager;

    private var neededLevel : String;

    private function new(?level: String):Void {
        neededLevel = level;
    }

    private override function entered(s2d: h2d.Scene):Void {
        background = new heaps.Background();
        s2d.add(background, 0);
        player = spawnEntity(Const.PLAYER_START_X, Const.PLAYER_START_Y, Player);
        player.onDestroyed = playerDeath;
        itemManager = spawnEntity(0.0, 0.0, ItemManager);
        if (Scenario.instance == null && neededLevel != null) {
            spawnEntity(0.0, 0.0, Scenario);
            Scenario.instance.addLevel(neededLevel);
        }
        loadScript(Scenario.instance.getCurrentScript());
    }

    private override function exited(s2d: h2d.Scene):Void {
        if (mainEnemy != null) mainEnemy.onDestroyed = null;
        if (player != null) player.onDestroyed = null;
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

    private function playerDeath(ent: Entity):Void {
        recordScore();
        Main.instance.changeScene(GameOver);
    }

    private function recordScore():Void {
        if (player == null) return;
        if (Scenario.instance != null) Scenario.instance.currentLevelData = {
            score : player.score,
            graze : player.grazePoints,
            deaths : Const.PLAYER_START_HP - player.lives
        };
    }
}