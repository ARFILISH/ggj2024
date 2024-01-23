package heaps;

import h2d.Tile;
import h2d.Drawable;

private typedef BackgroundLayer = {
    tile : Tile,
    hScroll : Float,
    vScroll : Float,
    hScrollSpeed : Float,
    vScrollSpeed : Float,
    parallaxScale : Float,
    alpha : Float,
    wrap : Bool,
}

class Background extends Drawable {
    public var cameraX : Float;
    public var cameraY : Float;

    private var layers : Map<Int, BackgroundLayer>;

    public function new(parent: h2d.Object) {
        super(parent);
    }

    public function addLayer(idx: Int, layer: BackgroundLayer):Void {
		if (layer.wrap) layer.tile.getTexture().wrap = Repeat;
        layers[idx] = layer;
    }

	public function removeLayer(idx: Int):Void {
		if (!layers.exists(idx)) return;
		layers.remove(idx);
	}

    private override function draw(ctx: h2d.RenderContext):Void {
        for (l in layers) emitLayer(ctx, l);
	}

    private function emitLayer(ctx: h2d.RenderContext, layer: BackgroundLayer):Void {
        if (layer == null) return;
		if (!ctx.hasBuffering()) {
			if(!ctx.drawTile(this, layer.tile)) return;
			return;
		}
		if (!ctx.beginDrawBatch(this, layer.tile.getTexture())) return;

		var alpha = color.a * ctx.globalAlpha * layer.alpha;
		var ax = absX + layer.tile.dx * matA + layer.tile.dy * matC + (layer.hScroll - cameraX) * layer.parallaxScale;
		var ay = absY + layer.tile.dx * matB + layer.tile.dy * matD + (layer.vScroll - cameraY) * layer.parallaxScale;
		var buf = ctx.buffer;
		var pos = ctx.bufPos;
		buf.grow(pos + 4 * 8);

		inline function emit(v:Float) buf[pos++] = v;

		emit(ax);
		emit(ay);
		@:privateAccess emit(layer.tile.u);
		@:privateAccess emit(layer.tile.v);
		emit(color.r);
		emit(color.g);
		emit(color.b);
		emit(alpha);

		var tw = layer.tile.width;
		var th = layer.tile.height;
		var dx1 = tw * matA;
		var dy1 = tw * matB;
		var dx2 = th * matC;
		var dy2 = th * matD;

		emit(ax + dx1);
		emit(ay + dy1);
		@:privateAccess emit(layer.tile.u2);
		@:privateAccess emit(layer.tile.v);
		emit(color.r);
		emit(color.g);
		emit(color.b);
		emit(alpha);

		emit(ax + dx2);
		emit(ay + dy2);
		@:privateAccess emit(layer.tile.u);
		@:privateAccess emit(layer.tile.v2);
		emit(color.r);
		emit(color.g);
		emit(color.b);
		emit(alpha);

		emit(ax + dx1 + dx2);
		emit(ay + dy1 + dy2);
		@:privateAccess emit(layer.tile.u2);
		@:privateAccess emit(layer.tile.v2);
		emit(color.r);
		emit(color.g);
		emit(color.b);
		emit(alpha);

		ctx.bufPos = pos;
    }
}