package game;

import h2d.Tile;
import h2d.Object;
import h2d.SpriteBatch;

class Bullet extends BatchElement {
    public var speed : Float;
    public var grazeCount : Int;
    public var radius : Float;

    public function new(t: Tile, speed: Float, rotation: Float):Void {
        this.rotation = rotation;
        this.speed = speed;
        grazeCount = 0;
        super(t);
    }

    private override function update(delta: Float):Bool {
        if (x < Const.PLAYFIELD_PLAYABLE_LEFT - t.dx || x > Const.PLAYFIELD_PLAYABLE_RIGHT + t.dx ||
                y < Const.PLAYFIELD_PLAYABLE_TOP + t.dy || x > Const.PLAYFIELD_PLAYABLE_BOTTOM + t.dx)
            return false;
        final mgr : BulletManager = cast batch;
        final speed = this.speed * delta;
        var vx : Float = 0.0;
        var vy : Float = 0.0;
        switch (mgr.moveType) {
            case Stop: { }
            case Fixed(rotSpeed): {
                rotation += rotSpeed() * delta;
                vx = Math.acos(rotation);
                vy = Math.asin(rotation);
            }
            case Position(pos): {
                var destX : Float;
                var destY : Float;
                var thisX : Float;
                var thisY : Float;
                switch (pos) {
                    case Local(x, y): {
                        destX = x;
                        destY = y;
                        thisX = this.x - mgr.owner.x;
                        thisY = this.y - mgr.owner.y;
                    }
                    case Relative(x, y): {
                        destX = x;
                        destY = y;
                        thisX = this.x - Const.ENEMY_BASE_X;
                        thisY = this.y - Const.ENEMY_BASE_Y;
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
                };
                vx = destX - thisX;
                vy = destY - thisY;
                var length = vx * vx + vy * vy;
                if (length > 0.0 && Math.sqrt(length) > speed) {
                    length = Math.sqrt(length); 
                    vx /= length;
                    vy /= length;
                    rotation = Math.atan2(vy, vx);
                } else {
                    vx = 0.0;
                    vy = 0.0;
                }
            }
        }
        x += vx * speed;
        y += vy * speed;
		return true;
	}
}

class BulletManager extends SpriteBatch {
    public var owner(default, null) : Enemy;

    private var idx : Int;

    public var aim : Types.BulletAim;
    public var countA : Int;
    public var countB : Int;
    public var angleA : Float;
    public var angleB : Float;
    public var speedA : Float;
    public var speedB : Float;
    public var radiusA : Float;
    public var radiusB : Float;
    public var moveType : Types.BulletMoveType;

    private var tiles : Array<Tile>;
    public var bulletType : Int;

    public var mask : Int;
    public var radius : Float;

    public function new(owner: Enemy, idx: Int, parent: Object) {
        this.idx = idx;
        super(null, parent);
        tiles = new Array();
        hasUpdate = true;
    }

    public function fixedUpdate(delta: Float):Void {
        if (owner.player == null) return;
        for (e in getElements()) {
            final b : Bullet = cast e;
            final distance = (b.x - owner.player.x) * (b.x - owner.player.x) + (b.y - owner.player.y) * (b.y - owner.player.y);
            if (mask & Types.CollisionLayers.Player == Types.CollisionLayers.Player &&
                    (distance <= 0.0 ||
                    distance <= (Const.PLAYER_HITBOX_RADIUS + b.radius) * (Const.PLAYER_HITBOX_RADIUS + b.radius))) {
                owner.player.applyDamage();
                b.remove();
            }
            else if (mask & Types.CollisionLayers.Graze == Types.CollisionLayers.Graze &&
                    distance <= (Const.PLAYER_GRAZEBOX_RADIUS + b.radius) * (Const.PLAYER_GRAZEBOX_RADIUS + b.radius))
                owner.player.graze(cast b);
            else b.grazeCount = 0;
        }
    }

    public function load(path: String):Void {
        final xmlContent = hxd.Res.load(path).toText();
        final xmlTree = Xml.parse(xmlContent).firstElement();
        if (xmlTree.nodeName != "bullets") throw 'Invalid bullet set $path!';
        final sources = new Array<Tile>();
        for (el in xmlTree.elementsNamed("source")) {
            final value = el.firstChild().nodeValue;
            final originalTile = hxd.Res.load(value).toTile();
            sources.push(originalTile);
        }
        if (sources.length == 0) return;
        for (el in xmlTree.elementsNamed("tile")) {
            final src = Std.parseInt(el.get("src" ?? "0"));
            final x = Std.parseFloat(el.get("x") ?? "0");
            final y = Std.parseFloat(el.get("y") ?? "0");
            var width = Std.parseFloat(el.get("width") ?? '${sources[src].width}');
            if (width > sources[src].width) width = sources[src].width;
            var height = Std.parseFloat(el.get("height") ?? '${sources[src].height}');
            if (height > sources[src].height) height = sources[src].height;
            final tile = sources[src].sub(x, y, width, height).center();
            tiles.push(tile);
        }
    }

    public function shoot():Void {
        if (tiles.length == 0) return;
        switch (aim) {
            case EntityFan(ent): {
                final stepT = 1.0 / countB;
                var distX = ent.x - owner.x;
                var distY = ent.y - owner.y;
                var length = distX * distX + distY * distY;
                var baseAngle = angleA;
                if (length > 0.0) {
                    length = Math.sqrt(length);
                    distX /= length;
                    distY /= length;
                    baseAngle += Math.atan2(distY, distX);
                }
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedB, speedA, stepT * j);
                        final rotation = baseAngle * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case Fan: {
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedB, speedA, stepT * j);
                        final rotation = angleA * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case EntityCircle(ent): {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                var distX = ent.x - owner.x;
                var distY = ent.y - owner.y;
                var length = distX * distX + distY * distY;
                var baseAngle = angleA;
                if (length > 0.0) {
                    length = Math.sqrt(length);
                    distX /= length;
                    distY /= length;
                    baseAngle += Math.atan2(distY, distX);
                }
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedB, speedA, stepT * j);
                        final rotation = (angleStep + baseAngle) * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case Circle: {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedB, speedA, stepT * j);
                        final rotation = (angleStep + angleA) * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case RandomFan: {
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = hxd.Math.lerp(speedB, speedA, stepT * j);
                        final rotation = angleB * i + (hxd.Math.random(angleA * 2.0) - angleA) * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case RandomCircle: {
                final angleStep = 2.0 * hxd.Math.PI / countA;
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = speedB + (hxd.Math.random(speedA * 2.0) - speedA) * j;
                        final rotation = (angleStep + angleA) * i + angleB * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
            case TotallyRandomFan: {
                final stepT = 1.0 / countB;
                for (i in 0...countA)
                    for (j in 0...countB) {
                        final speed = speedB + (hxd.Math.random(speedA * 2.0) - speedA) * j;
                        final rotation = angleB * i + (hxd.Math.random(angleA * 2.0) - angleA) * j;
                        final radius = hxd.Math.lerp(radiusB, radiusA, stepT * j);
                        final bullet = new Bullet(tiles[bulletType % tiles.length], speed, rotation);
                        final xOff = radius * Math.cos(rotation);
                        final yOff = radius * Math.sin(rotation);
                        add(bullet);
                        bullet.x = (owner.x ?? 0.0) + xOff;
                        bullet.y = (owner.y ?? 0.0) + yOff;
                    }
            }
        }
    }
}