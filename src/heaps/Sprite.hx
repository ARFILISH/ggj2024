package heaps;

import h2d.RenderContext;
import h2d.Tile;
import h2d.Drawable;

private class Animation {
    public var frames(default, null) : Array<Tile>;
    public var speed(default, null) : Float;
    public var loop(default, null) : Bool;
    public var length(get, never) : Int;
        inline private function get_length():Int return frames.length;
    public var endTime(get, never) : Float;
        inline private function get_endTime():Float return length / speed;

    inline public function new(frames : Array<Tile>, speed : Float, loop : Bool):Void {
        this.frames = frames;
        this.speed = speed;
        this.loop = loop;
    }

    inline public function getFrame(time: Float):Tile {
        return frames[Std.int(time * speed)];
    }

    inline public function getTime(original: Float):Float {
        if (original >= endTime) return loop ? 0.0 : endTime;
        return original;
    }
}

class Sprite extends Drawable {
    public var animations(default, null) : Map<Int, Animation>;
    private var animCount : Int;
    public var current(default, null) : Int;
    public var pause : Bool;
    private var time : Float;

    public function new(parent: h2d.Object):Void {
        super(parent);
        animations = new Map();
        current = -1;
        time = -1.0;
        pause = false;
        animCount = 0;
    }

    public function addAnimation(id: Int, frames: Array<Tile>, speed: Float, loop: Bool):Void {
        if (animations.exists(id)) throw 'Animation $id already exists!';
        animations[id] = new Animation(frames, speed, loop);
        if (animCount == 0) {
            current = 0;
            time = 0.0;
        }
        animCount++;
    }

    public function removeAnimation(id: Int):Void {
        if (!animations.exists(id)) throw 'Animation $id does not exist!';
        animations.remove(id);
        animCount--;
        if (animCount == 0) {
            current = -1;
            time = -1.0;
        }
    }

    inline public function hasAnimation(id: Int):Bool {
        return animations.exists(id);
    }

    public function play(id: Int, start: Float = 0.0):Void {
        if (current == id) return;
        if (!animations.exists(id)) throw 'Animation $id does not exist!';
        current = id;
    }

    public function playOverride(id: Int, start: Float = 0.0):Void {
        if (!animations.exists(id)) throw 'Animation $id does not exist!';
        current = id;
    }

    private override function getBoundsRec(relativeTo: h2d.Object, out: h2d.col.Bounds, forSize: Bool):Void {
		super.getBoundsRec(relativeTo, out, forSize);
        if (current == -1) return;
        final tile = animations[current].getFrame(time);
        if (tile != null) addBounds(relativeTo, out, tile.dx, tile.dy, tile.width, tile.height);
	}

    public dynamic function animationEnded(id: Int):Void { }

    private override function sync(ctx: RenderContext):Void {
        super.sync(ctx);
        if (pause || current == -1) return;
        final previous = time;
        time += ctx.elapsedTime;
        time = animations[current].getTime(time);
        if ((time > previous && time == animations[current].endTime) || time < previous) animationEnded(current);
	}

    private override function draw(ctx: RenderContext):Void {
        if (current == -1) return;
        final tile = animations[current].getFrame(time);
        emitTile(ctx, tile);
	}
}