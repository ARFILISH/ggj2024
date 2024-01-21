package game;

import heaps.Sprite;

private typedef EnemyEvent = {
    time : Float,
    cb : Void->Void,
}

class Enemy extends Entity {
    private var sprite : Sprite;

    private var events : Array<EnemyEvent>;
    private var time : Float;

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite(s2d);
        time = 0.0;
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        sprite.remove();
    }

    private override function update(delta: Float):Void {
        if (events.length == 0) {
            destroy();
            return;
        }

        final toComplete = new Array<EnemyEvent>();
        while (events.length != 0 && events[0].time <= time) toComplete.push(events.shift());
        for (e in toComplete) e.cb();

        time += delta;
    }
}