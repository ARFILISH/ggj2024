package game;

class Playfield extends Scene {
    private override function entered(s2d: h2d.Scene):Void {
        spawnEntity(160.0, 140.0, Player);
    }
}