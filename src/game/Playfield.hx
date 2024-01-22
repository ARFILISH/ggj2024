package game;

class Playfield extends Scene {
    private var mainEnemy : Enemy;

    private override function entered(s2d: h2d.Scene):Void {
        spawnEntity(160.0, 140.0, Player);
        mainEnemy = spawnEntity(160.0, 0.0, Enemy);
        mainEnemy.tag = "main";
        mainEnemy.loadScript("data/levels/level_01.hs");
    }
}