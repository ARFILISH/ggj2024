package game;

class Playfield extends Scene {
    public var background(default, null) : heaps.Background;
    private var mainEnemy : Enemy;

    private override function entered(s2d: h2d.Scene):Void {
        background = new heaps.Background(s2d);
        spawnEntity(Const.PLAYER_START_X, Const.PLAYER_START_Y, Player);
        mainEnemy = spawnEntity(Const.ENEMY_BASE_X, Const.ENEMY_BASE_Y, Enemy);
        mainEnemy.loadScript("data/levels/level_01.hscript");
    }

    private override function exited(s2d: h2d.Scene):Void {
        background.remove();
    }
}