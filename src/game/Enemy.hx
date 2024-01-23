package game;

import hscript.Interp;
import hscript.Parser;
import heaps.Sprite;

private typedef EnemyEvent = {
    time : Float,
    cb : Void->Void,
}

private typedef EnemyDestinationPoint = {
    pos : Types.Position,
    speed : Float,
    ?cb : Void->Void,
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
    public var player(default, null) : Player;
    private var moveDestQueue : List<EnemyDestinationPoint>;
    private var children : Array<Enemy>;

    private var preparedParams : Map<String, Any>;

    private var bulletManagers : Map<Int, BulletManager>;

    private var radius : Float;
    private var mask : Int;

    private var grazeCount : Int;

    private override function added(s2d: h2d.Scene):Void {
        parent = null;
        sprite = new Sprite(s2d);
        time = 0.0;
        events = new List();
        moveDestQueue = new List();
        bulletManagers = new Map();
        player = scene.getEntity(Player);
        radius = 0.0;
        mask = 0;
        children = new Array();
        grazeCount = 0;
    }

    private override function destroyed(s2d: h2d.Scene):Void {
        sprite.remove();
        events.clear();
        moveDestQueue.clear();
        if (parent != null) {
            parent.children.remove(this);
            parent = null;
        }
        for (m in bulletManagers) {
            if (m.destroyWithParent) m.destroy();
            else m.parent = null;
        }
        bulletManagers.clear();
        for (c in children) c.destroy();
        children = null;
        grazeCount = 0;
    }

    public function loadScript(path: String, ?params: Map<String, Any>) {
        final file = hxd.Res.load(path).toText();
        final parser = new Parser();
        final ast = parser.parseString(file, 'enemy_$tag');
        final interp = new Interp();
        interp.variables["getLocalX"] = get_lx;
        interp.variables["setLocalX"] = set_lx;
        interp.variables["getLocalY"] = get_ly;
        interp.variables["setLocalY"] = set_ly;
        interp.variables["getRelativeX"] = get_rx;
        interp.variables["setRelativeX"] = set_rx;
        interp.variables["getRelativeY"] = get_ry;
        interp.variables["setRelativeY"] = set_ry;
        interp.variables["getWorldX"] = function():Float { return x; };
        interp.variables["setWorldX"] = function(val: Float):Float { return x = val; };
        interp.variables["getWorldY"] = function():Float { return y; };
        interp.variables["setWorldY"] = function(val: Float):Float { return y = val; };
        interp.variables["getRadius"] = function():Float { return radius; };
        interp.variables["setRadius"] = function(val: Float):Float { return radius = val; };
        interp.variables["getMask"] = function():Int { return mask; };
        interp.variables["setMask"] = function(val: Int):Int { return mask = val; };
        interp.variables["player"] = player;
        interp.variables["addEvent"] = addEvent;
        interp.variables["setSprite"] = setSprite;
        interp.variables["playAnimation"] = playAnimation;
        interp.variables["playAnimationOverride"] = playAnimationOverride;
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
        interp.variables["createBulletManager"] = createBulletManager;
        interp.variables["destroyBulletManager"] = destroyBulletManager;
        interp.variables["freeBulletManager"] = freeBulletManager;
        interp.variables["loadBulletManagerBullets"] = loadBulletManagerBullets;
        interp.variables["setBulletManagerTile"] = setBulletManagerTile;
        interp.variables["setBulletManagerAutoDestroy"] = setBulletManagerAutoDestroy;
        interp.variables["setBulletManagerDestroyWithParent"] = setBulletManagerDestroyWithParent;
        interp.variables["setBulletManagerAimType"] = setBulletManagerAimType;
        interp.variables["setBulletManagerCount"] = setBulletManagerCount;
        interp.variables["setBulletManagerAngle"] = setBulletManagerAngle;
        interp.variables["setBulletManagerSpeed"] = setBulletManagerSpeed;
        interp.variables["setBulletManagerRadius"] = setBulletManagerRadius;
        interp.variables["setBulletManagerHitmask"] = setBulletManagerHitmask;
        interp.variables["setBulletManagerHitRadius"] = setBulletManagerHitRadius;
        interp.variables["setBulletManagerMoveType"] = setBulletManagerMoveType;
        interp.variables["bulletManagerShoot"] = bulletManagerShoot;
        interp.variables["LocalSpace"] = Types.Position.Local;
        interp.variables["RelativeSpace"] = Types.Position.Relative;
        interp.variables["WorldSpace"] = Types.Position.World;
        interp.variables["EntitySpace"] = Types.Position.Entity;
        interp.variables["MoveTypeStop"] = Types.BulletMoveType.Stop;
        interp.variables["MoveTypeFixed"] = Types.BulletMoveType.Fixed;
        interp.variables["MoveTypePosition"] = Types.BulletMoveType.Position;
        interp.variables["AimEntityFan"] = Types.BulletAim.EntityFan;
        interp.variables["AimFan"] = Types.BulletAim.Fan;
        interp.variables["AimEntityCircle"] = Types.BulletAim.EntityCircle;
        interp.variables["AimCircle"] = Types.BulletAim.Circle;
        interp.variables["AimRandomFan"] = Types.BulletAim.RandomFan;
        interp.variables["AimRandomCircle"] = Types.BulletAim.RandomCircle;
        interp.variables["AimTotallyRandomFan"] = Types.BulletAim.TotallyRandomFan;
        interp.variables["Math"] = hxd.Math;
        if (params != null) for (k => v in params) interp.variables[k] = v;
        interp.execute(ast);
    }

    private override function update(delta: Float):Void {
        while (!events.isEmpty() && events.first().time <= time) events.pop().cb();
        if (events.isEmpty() && moveDestQueue.isEmpty() && children.length == 0) {
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
            final length = hInput * hInput + vInput * vInput;
            if (length > 0.0 && Math.sqrt(length) > speed) {
                hInput = hInput / Math.sqrt(length) * speed;
                vInput = vInput / Math.sqrt(length) * speed;
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
            } else {
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
                };
                moveDestQueue.pop();
                if (moveDestination.cb != null) moveDestination.cb();
            }
        }
        time += delta;
    }

    private override function fixedUpdate(dt: Float):Void {
        if (player != null) {
            final distance = (x - player.x) * (x - player.x) + (y - player.y) * (y - player.y);
            if (mask & Types.CollisionLayers.Player == Types.CollisionLayers.Player &&
                    (distance == 0.0 ||
                    distance <= (Const.PLAYER_HITBOX_RADIUS + radius) * (Const.PLAYER_HITBOX_RADIUS + radius)))
                player.applyDamage();
            else if (mask & Types.CollisionLayers.Graze == Types.CollisionLayers.Graze &&
                    distance <= (Const.PLAYER_GRAZEBOX_RADIUS + radius) * (Const.PLAYER_GRAZEBOX_RADIUS + radius))
                player.graze(cast this);
            else grazeCount = 0;
        }
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

    inline private function setSprite(path: String):Void {
        sprite.load(path);
    }

    inline private function playAnimation(id: Int, start: Float = 0.0):Void {
        sprite.play(id, start);
    }

    inline private function playAnimationOverride(id: Int, start: Float = 0.0):Void {
        sprite.playOverride(id, start);
    }

    private function moveToByTime(pos: Types.Position, time: Float, ?cb: Void->Void):Void {
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
        moveDestQueue.push({ pos: pos, speed: speed, cb: cb });
    }

    private function moveToBySpeed(pos: Types.Position, speed: Float, ?cb: Void->Void):Void {
        moveDestQueue.pop();
        moveDestQueue.push({ pos: pos, speed: speed, cb: cb });
    }

    private function enqueueMoveToByTime(pos: Types.Position, time: Float, ?cb: Void->Void):Void {
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
        moveDestQueue.add({ pos: pos, speed: speed, cb: cb });
    }

    private function enqueueMoveToBySpeed(pos: Types.Position, speed: Float, ?cb: Void->Void):Void {
        moveDestQueue.add({ pos: pos, speed: speed, cb: cb });
    }

    private function nextMove():Void {
        moveDestQueue.pop();
    }

    private function stopMoving():Void {
        moveDestQueue.clear();
    }

    private function spawnEnemy(pos: Types.Position, script: String, health: Int):Void {
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
        children.push(enemy);
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

    private function createBulletManager(idx: Int):Void {
        if (bulletManagers.exists(idx)) bulletManagers[idx].parent = null;
        final mgr = scene.spawnEntity(x, y, BulletManager);
        mgr.parent = this;
        bulletManagers[idx] = mgr;
        mgr.player = player;
    }

    private function destroyBulletManager(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].destroy();
        bulletManagers.remove(idx);
    }

    private function freeBulletManager(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].parent = null;
        bulletManagers.remove(idx);
    }

    private function loadBulletManagerBullets(idx: Int, path: String):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].load(path);
    }

    private function setBulletManagerTile(idx: Int, tile: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].bulletType = tile;
    }

    private function setBulletManagerAutoDestroy(idx: Int, ad: Bool):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].autoDestroy = ad;
    }

    private function setBulletManagerDestroyWithParent(idx: Int, dwp: Bool):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].destroyWithParent = dwp;
    }

    private function setBulletManagerAimType(idx: Int, aim: Types.BulletAim):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].aim = aim;
    }

    private function setBulletManagerCount(idx: Int, countA: Int, countB: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].countA = countA;
        bulletManagers[idx].countB = countB;
    }

    private function setBulletManagerAngle(idx: Int, angleA: Float, angleB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].angleA = angleA;
        bulletManagers[idx].angleB = angleB;
    }

    private function setBulletManagerSpeed(idx: Int, speedA: Float, speedB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].speedA = speedA;
        bulletManagers[idx].speedB = speedB;
    }

    private function setBulletManagerRadius(idx: Int, radiusA: Float, radiusB: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].radiusA = radiusA;
        bulletManagers[idx].radiusB = radiusB;
    }

    private function setBulletManagerMoveType(idx: Int, moveType: Types.BulletMoveType):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].moveType = moveType;
    }

    private function setBulletManagerHitmask(idx: Int, mask: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].hitmask = mask;
    }

    private function setBulletManagerHitRadius(idx: Int, radius: Float):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].hitRadius = radius;
    }

    private function bulletManagerShoot(idx: Int):Void {
        if (!bulletManagers.exists(idx)) throw 'Bullet manager $idx does not exist!';
        bulletManagers[idx].shoot();
    }
}