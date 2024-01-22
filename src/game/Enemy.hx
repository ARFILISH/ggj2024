package game;

import hscript.Interp;
import hscript.Parser;
import heaps.Sprite;

private enum EnemyPosition {
    Local(x : Float, y : Float);
    Relative(x : Float, y : Float);
    World(x : Float, y : Float);
    Entity(ent : Entity, x : Float, y : Float);
}

private typedef EnemyEvent = {
    time : Float,
    cb : Void->Void,
}

private typedef EnemyDestinationPoint = {
    pos : EnemyPosition,
    speed : Float,
}

class Enemy extends Entity {
    @:allow(game.Playfield)
    private var tag : String;

    private var parent : Enemy;

    private var sprite : Sprite;

    private var lx(get, set) : Float;
        inline private function get_lx():Float return x - (parent != null ? parent.x : Const.ENEMY_BASE_X);
        inline private function set_lx(val: Float):Float return x = (parent != null ? parent.x : Const.ENEMY_BASE_X) + val;
    private var ly(get, set) : Float;
        inline private function get_ly():Float return y - (parent != null ? parent.y : Const.ENEMY_BASE_Y);
        inline private function set_ly(val: Float):Float return y = (parent != null ? parent.x : Const.ENEMY_BASE_Y) + val;
    private var rx(get, set) : Float;
        inline private function get_rx():Float return x - Const.ENEMY_BASE_X;
        inline private function set_rx(val: Float):Float return x = Const.ENEMY_BASE_X + val;
    private var ry(get, set) : Float;
        inline private function get_ry():Float return y - Const.ENEMY_BASE_Y;
        inline private function set_ry(val: Float):Float return y = Const.ENEMY_BASE_Y + val;

    private var events : List<EnemyEvent>;
    private var time : Float;
    private var player : Player;
    private var moveDestQueue : List<EnemyDestinationPoint>;

    private var preparedParams : Map<String, Any>;

    private var radius : Float;
    private var mask : Int;

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite(s2d);
        time = 0.0;
        events = new List();
        moveDestQueue = new List();
        player = scene.getEntity(Player);
        radius = 0.0;
        mask = 0;
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        sprite.remove();
        events.clear();
        moveDestQueue.clear();
    }

    public function loadScript(path: String, ?params: Map<String, Any>) {
        final file = hxd.Res.load(path).toText();
        final parser = new Parser();
        final ast = parser.parseString(file, 'enemy_$tag');
        final interp = new Interp();
        interp.variables["localX"] = lx;
        interp.variables["localY"] = ly;
        interp.variables["relativeX"] = rx;
        interp.variables["relativeY"] = ry;
        interp.variables["worldX"] = x;
        interp.variables["worldY"] = y;
        interp.variables["player"] = player;
        interp.variables["addEvent"] = addEvent;
        interp.variables["setSprite"] = setSprite;
        interp.variables["destroy"] = destroy;
        interp.variables["moveToByTime"] = moveToByTime;
        interp.variables["moveToBySpeed"] = moveToBySpeed;
        interp.variables["enqueueMoveToByTime"] = enqueueMoveToByTime;
        interp.variables["enqueueMoveToBySpeed"] = enqueueMoveToBySpeed;
        interp.variables["nextMove"] = nextMove;
        interp.variables["spawnEnemy"] = spawnEnemy;
        interp.variables["stopMoving"] = stopMoving;
        interp.variables["setPreparedParam"] = setPreparedParam;
        interp.variables["clearPreparedParams"] = clearPreparedParams;
        interp.variables["LocalSpace"] = EnemyPosition.Local;
        interp.variables["RelativeSpace"] = EnemyPosition.Relative;
        interp.variables["WorldSpace"] = EnemyPosition.World;
        interp.variables["EntitySpace"] = EnemyPosition.Entity;
        if (params != null) for (k => v in params) interp.variables[k] = v;
        interp.execute(ast);
    }

    private override function update(delta: Float):Void {
        while (!events.isEmpty() && events.first().time <= time) events.pop().cb();
        if (events.isEmpty() && moveDestQueue.isEmpty()) {
            destroy();
            return;
        }
        if (!moveDestQueue.isEmpty()) {
            final moveDestination = moveDestQueue.first();
            final speed = moveDestination.speed * delta;
            var destX : Float;
            var destY : Float;
            var thisX : Float;
            var thisY : Float;
            switch (moveDestination.pos) {
                case Local(x, y): {
                    destX = x;
                    destY = y;
                    thisX = lx;
                    thisY = ly;
                }
                case Relative(x, y): {
                    destX = x;
                    destY = y;
                    thisX = rx;
                    thisY = ry;
                }
                case World(x, y): {
                    destX = x;
                    destY = y;
                    thisX = this.x;
                    thisY = this.y;
                }
                case Entity(ent, x, y): {
                    destX = ent.x + x;
                    destY = ent.y + y;
                    thisX = this.x;
                    thisY = this.y;
                }
            }
            var hInput = destX - thisX;
            var vInput = destY - thisY;
            var length = hInput * hInput + vInput * vInput;
            if (length > 0.0) {
                length = Math.sqrt(length);
                if (length <= speed) {
                    switch (moveDestination.pos) {
                        case Local(_, _): {
                            lx = destX;
                            ly = destY;
                        }
                        case Relative(_, _): {
                            rx = destX;
                            ry = destY;
                        }
                        case World(_, _) | Entity(_, _, _): {
                            x = destX;
                            y = destY;
                        }
                    }
                    moveDestQueue.pop();
                } else {
                    hInput /= length;
                    vInput /= length;
                    hInput *= speed;
                    vInput *= speed;
                    switch (moveDestination.pos) {
                        case Local(_, _): {
                            lx += hInput;
                            ly += vInput;
                        }
                        case Relative(_, _): {
                            rx += hInput;
                            ry += vInput;
                        }
                        case World(_, _) | Entity(_, _, _): {
                            x += hInput;
                            y += vInput;
                        }
                    }
                }
            } else moveDestQueue.pop();
        }
        time += delta;
    }

    private override function render():Void {
        sprite.x = x;
        sprite.y = y;
    }

    private function addEvent(time: Float, cb: Void->Void):Void {
        final event = { time: time, cb: cb };
        if (events.length == 0) {
            events.add(event);
            return;
        }
        if (event.time >= events.last().time) {
            events.add(event);
            return;
        }
        if (event.time <= events.first().time) {
            events.push(event);
            return;
        }
        throw 'Can\'t add event with time that is not in order!';
    }

    private function setSprite(path: String):Void {
        final tile = hxd.Res.load(path).toTile().center();
        if (sprite.hasAnimation(0)) sprite.removeAnimation(0);
        sprite.addAnimation(0, [ tile ], 1.0, true);
    }

    private function moveToByTime(pos: EnemyPosition, time: Float):Void {
        var destX : Float;
        var destY : Float;
        var thisX : Float;
        var thisY : Float;
        switch (pos) {
            case Local(x, y): {
                destX = x;
                destY = y;
                thisX = lx;
                thisY = ly;
            }
            case Relative(x, y): {
                destX = x;
                destY = y;
                thisX = rx;
                thisY = ry;
            }
            case World(x, y): {
                destX = x;
                destY = y;
                thisX = this.x;
                thisY = this.y;
            }
            case Entity(ent, x, y): {
                destX = ent.x + x;
                destY = ent.y + y;
                thisX = this.x;
                thisY = this.y;
            }
        }
        var distance = (destX - thisX) * (destX - thisX) + (destY - thisY) * (destY - thisY);
        var speed : Float = 0.0;
        if (distance > 0.0) speed = Math.sqrt(distance) / time;
        moveDestQueue.pop();
        moveDestQueue.push({ pos: pos, speed: speed });
    }

    private function moveToBySpeed(pos: EnemyPosition, speed: Float):Void {
        moveDestQueue.pop();
        moveDestQueue.push({ pos: pos, speed: speed });
    }

    private function enqueueMoveToByTime(pos: EnemyPosition, time: Float):Void {
        var destX : Float;
        var destY : Float;
        var thisX : Float;
        var thisY : Float;
        switch (pos) {
            case Local(x, y): {
                destX = x;
                destY = y;
                thisX = lx;
                thisY = ly;
            }
            case Relative(x, y): {
                destX = x;
                destY = y;
                thisX = rx;
                thisY = ry;
            }
            case World(x, y): {
                destX = x;
                destY = y;
                thisX = this.x;
                thisY = this.y;
            }
            case Entity(ent, x, y): {
                destX = ent.x + x;
                destY = ent.y + y;
                thisX = this.x;
                thisY = this.y;
            }
        }
        var distance = (destX - thisX) * (destX - thisX) + (destY - thisY) * (destY - thisY);
        var speed : Float = 0.0;
        if (distance > 0.0) speed = Math.sqrt(distance) / time;
        moveDestQueue.add({ pos: pos, speed: speed });
    }

    private function enqueueMoveToBySpeed(pos: EnemyPosition, speed: Float):Void {
        moveDestQueue.add({ pos: pos, speed: speed });
    }

    private function nextMove():Void {
        moveDestQueue.pop();
    }

    private function stopMoving():Void {
        moveDestQueue.clear();
    }

    private function spawnEnemy(pos: EnemyPosition, script: String, health: Int):Void {
        var newX : Float;
        var newY : Float;
        switch (pos) {
            case Local(x, y): {
                newX = this.x + x;
                newY = this.y + y;
            }
            case Relative(x, y): {
                newX = Const.ENEMY_BASE_X + x;
                newY = Const.ENEMY_BASE_Y + y;
            }
            case World(x, y): {
                newX = x;
                newY = y;
            }
            case Entity(ent, x, y): {
                newX = ent.x + x;
                newY = ent.y + y;
            }
        }
        final enemy = scene.spawnEntity(newX, newY, Enemy);
        enemy.loadScript(script, preparedParams);
        enemy.parent = this;
    }

    private function setPreparedParam(k: String, v: Any):Void {
        if (preparedParams == null) preparedParams = [ k => v ];
        else preparedParams[k] = v;
    }

    private function clearPreparedParams():Void {
        if (preparedParams == null) throw "Prepared params do not exist!";
        preparedParams.clear();
        preparedParams = null;
    }
}