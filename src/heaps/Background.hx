package heaps;

import h2d.Tile;
import h2d.Drawable;

private typedef BackgroundLayer = {
    tile : Tile,
    hScroll : Float,
    vScroll : Float,
    ?hScrollSpeed : Float,
    ?vScrollSpeed : Float,
    ?parallaxScale : Float,
	?r : Float,
	?g : Float,
	?b : Float,
    ?a : Float,
    ?hWrap : Bool,
	?vWrap : Bool,
	?followCamera : Bool,
}

private typedef BackgroundColorTween = {
	withTime : Float,
	time : Float,
	startR : Float,
	startG : Float,
	startB : Float,
    startA : Float,
	?r : Float,
	?g : Float,
	?b : Float,
    ?a : Float,
}

class Background extends Drawable {
	public var cameraVelocityX : Float;
	public var cameraVelocityY : Float;
    public var cameraX : Float;
    public var cameraY : Float;

    public var layer : BackgroundLayer;
	private var tween : BackgroundColorTween;

    public function new(parent: h2d.Object) {
        super(parent);
		layer = null;
		tween = null;
		cameraVelocityX = 0.0;
		cameraVelocityY = 0.0;
		cameraX = 0.0;
		cameraY = 0.0;
    }

	public function load(path: String):Void {
		final xmlContent = hxd.Res.load(path).toText();
        final xmlTree = Xml.parse(xmlContent).firstElement();
        if (xmlTree.nodeName != "background") throw 'Invalid background $path!';
		if (xmlTree.get("cameraX") != null) cameraX = Std.parseFloat(xmlTree.get("cameraX"));
		if (xmlTree.get("cameraY") != null) cameraX = Std.parseFloat(xmlTree.get("cameraY"));
		if (xmlTree.get("cameraVelocityX") != null) cameraX = Std.parseFloat(xmlTree.get("cameraVelocityX"));
		if (xmlTree.get("cameraVelocityY") != null) cameraX = Std.parseFloat(xmlTree.get("cameraVelocityY"));
		cameraY = Std.parseFloat(xmlTree.get("cameraY")) ?? cameraY;
		cameraVelocityX = Std.parseFloat(xmlTree.get("cameraVelocityX")) ?? cameraVelocityX;
		cameraVelocityY = Std.parseFloat(xmlTree.get("cameraVelocityY")) ?? cameraVelocityY;
		for (el in xmlTree.elementsNamed("layer")) {
            if (el.get("idx") == null) throw 'Invalid background $path - no index!';
			final idx = Std.parseInt(el.get("idx"));
			if (el.get("src") == null) throw 'Invalid background $path!';
			layer = {
				tile : hxd.Res.load(el.get("src")).toTile(),
				hScroll : Std.parseFloat(el.get("hScroll") ?? "0"),
				vScroll : Std.parseFloat(el.get("vScroll") ?? "0"),
				hScrollSpeed : Std.parseFloat(el.get("hScrollSpeed") ?? "0"),
				vScrollSpeed : Std.parseFloat(el.get("vScrollSpeed") ?? "0"),
				parallaxScale : Std.parseFloat(el.get("parallaxScale") ?? "1"),
				r : Std.parseFloat(el.get("r") ?? "1"),
				g : Std.parseFloat(el.get("g") ?? "1"),
				b : Std.parseFloat(el.get("b") ?? "1"),
				a : Std.parseFloat(el.get("a") ?? "1"),
				hWrap : (el.get("hWrap") ?? "true") != "false",
				vWrap : (el.get("vWrap") ?? "true") != "false",
				followCamera : (el.get("followCamera") ?? "false") != "false",
			};
			return;
        }
	}

	@:keep public function changeLayerColor(?r: Float, ?g: Float, ?b: Float, ?a: Float, ?time: Float):Void {
		if (layer == null) return;
		if (time == null || time <= 0.0) {
			if (r != null) layer.r = r;
			if (g != null) layer.g = g;
			if (b != null) layer.b = b;
			if (a != null) layer.a = a;
			return;
		}
		tween = { 
			withTime : time,
			time : 0.0,
			startR : layer.r,
			startG : layer.g,
			startB : layer.b,
			startA : layer.a,
			r : r,
			g : g,
			b : b,
			a : a,
		};
	}

	public override function sync(ctx: h2d.RenderContext):Void {
		layer.hScroll += layer.hScrollSpeed * ctx.elapsedTime;
		layer.vScroll += layer.vScrollSpeed * ctx.elapsedTime;
		cameraX += cameraVelocityX * ctx.elapsedTime;
		cameraY += cameraVelocityY * ctx.elapsedTime;
	}

    private override function draw(ctx: h2d.RenderContext):Void {
		if (tween != null) {
			final t = hxd.Math.clamp(tween.time / tween.withTime);
			if (tween.r != null) layer.r = hxd.Math.lerp(tween.startR, tween.r, t);
			if (tween.g != null) layer.g = hxd.Math.lerp(tween.startG, tween.g, t);
			if (tween.b != null) layer.b = hxd.Math.lerp(tween.startB, tween.b, t);
			if (tween.a != null) layer.a = hxd.Math.lerp(tween.startA, tween.a, t);
			if (t == 1.0) tween = null;
			else tween.time += ctx.elapsedTime;
		}
		final cameraX = layer.followCamera ? 0.0 : this.cameraX;
		final cameraY = layer.followCamera ? 0.0 : this.cameraY;
		layer.tile.setPosition(layer.hWrap ? (-layer.hScroll + cameraX) * layer.parallaxScale : 0.0, layer.vWrap ? (-layer.vScroll + cameraY) * layer.parallaxScale : 0.0);
		if (!layer.hWrap) layer.tile.dx = (layer.hScroll - cameraX) * layer.parallaxScale;
		if (!layer.vWrap) layer.tile.dy = (layer.vScroll - cameraY) * layer.parallaxScale;
		final szX = (layer.hWrap ? ctx.scene.width : layer.tile.width);
		final szY = (layer.vWrap ? ctx.scene.height : layer.tile.height);
		layer.tile.setSize(szX, szY);
		layer.tile.scaleToSize(szX, szY);
		tileWrap = layer.hWrap || layer.vWrap;
		emitLayer(layer, ctx);
	}

	private function emitLayer(l: BackgroundLayer, ctx: h2d.RenderContext):Bool {
		var matA, matB, matC, matD, absX, absY;
		if (@:privateAccess  ctx.inFilter != null) {
			@:privateAccess var f1 = ctx.baseShader.filterMatrixA;
			@:privateAccess var f2 = ctx.baseShader.filterMatrixB;
			var tmpA = this.matA * f1.x + this.matB * f1.y;
			var tmpB = this.matA * f2.x + this.matB * f2.y;
			var tmpC = this.matC * f1.x + this.matD * f1.y;
			var tmpD = this.matC * f2.x + this.matD * f2.y;
			var tmpX = this.absX * f1.x + this.absY * f1.y + f1.z;
			var tmpY = this.absX * f2.x + this.absY * f2.y + f2.z;
			@:privateAccess matA = tmpA * ctx.viewA + tmpB * ctx.viewC;
			@:privateAccess matB = tmpA * ctx.viewB + tmpB * ctx.viewD;
			@:privateAccess matC = tmpC * ctx.viewA + tmpD * ctx.viewC;
			@:privateAccess matD = tmpC * ctx.viewB + tmpD * ctx.viewD;
			@:privateAccess absX = tmpX * ctx.viewA + tmpY * ctx.viewC + ctx.viewX;
			@:privateAccess absY = tmpX * ctx.viewB + tmpY * ctx.viewD + ctx.viewY;
		} else {
			@:privateAccess matA = this.matA * ctx.viewA + this.matB * ctx.viewC;
			@:privateAccess matB = this.matA * ctx.viewB + this.matB * ctx.viewD;
			@:privateAccess matC = this.matC * ctx.viewA + this.matD * ctx.viewC;
			@:privateAccess matD = this.matC * ctx.viewB + this.matD * ctx.viewD;
			@:privateAccess absX = this.absX * ctx.viewA + this.absY * ctx.viewC + ctx.viewX;
			@:privateAccess absY = this.absX * ctx.viewB + this.absY * ctx.viewD + ctx.viewY;
		}

		// check if our tile is outside of the viewport
		if( matB == 0 && matC == 0 ) {
			var tx = l.tile.dx + l.tile.width * 0.5;
			var ty = l.tile.dy + l.tile.height * 0.5;
			var tr = (l.tile.width > l.tile.height ? l.tile.width : l.tile.height) * 1.5 * hxd.Math.max(hxd.Math.abs(matA),hxd.Math.abs(matD));
			var cx = absX + tx * matA;
			var cy = absY + ty * matD;
			if ( cx + tr < -1 || cx - tr > 1 || cy + tr < -1 || cy - tr > 1) return false;
		} else {
			var xMin = 1e20, yMin = 1e20, xMax = -1e20, yMax = -1e20;
			inline function calc(x:Float, y:Float) {
				var px = (x + l.tile.dx) * matA + (y + l.tile.dy) * matC;
				var py = (x + l.tile.dx) * matB + (y + l.tile.dy) * matD;
				if( px < xMin ) xMin = px;
				if( px > xMax ) xMax = px;
				if( py < yMin ) yMin = py;
				if( py > yMax ) yMax = py;
			}
			var hw = l.tile.width * 0.5;
			var hh = l.tile.height * 0.5;
			calc(0, 0);
			calc(l.tile.width, 0);
			calc(0, l.tile.height);
			calc(l.tile.width, l.tile.height);
			if (absX + xMax < -1 || absY + yMax < -1 || absX + xMin > 1 || absY + yMin > 1)
				return false;
		}

		if (@:privateAccess !ctx.beginDraw(this, l.tile.getTexture(), true, true)) return false;

		#if sceneprof h3d.impl.SceneProf.mark(this); #end
		@:privateAccess setupRenderColor(l, ctx);
		@:privateAccess ctx.baseShader.absoluteMatrixA.set(l.tile.width * this.matA, l.tile.height * this.matC, this.absX + l.tile.dx * this.matA + l.tile.dy * this.matC);
		@:privateAccess ctx.baseShader.absoluteMatrixB.set(l.tile.width * this.matB, l.tile.height * this.matD, this.absY + l.tile.dx * this.matB + l.tile.dy * this.matD);
		@:privateAccess ctx.baseShader.uvPos.set(l.tile.u, l.tile.v, l.tile.u2 - l.tile.u, l.tile.v2 - l.tile.v);
		ctx.beforeDraw();
		if (@:privateAccess ctx.fixedBuffer == null || @:privateAccess ctx.fixedBuffer.isDisposed() ) {
			@:privateAccess ctx.fixedBuffer = new h3d.Buffer(4, hxd.BufferFormat.H2D);
			var k = new hxd.FloatBuffer();
			for (v in [ 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ])
				k.push(v);
			@:privateAccess ctx.fixedBuffer.uploadFloats(k, 0, 4);
		}
		ctx.engine.renderQuadBuffer(@:privateAccess ctx.fixedBuffer);
		return true;
	}

	inline private function setupRenderColor(l: BackgroundLayer, ctx: h2d.RenderContext):Void {
		@:privateAccess if (ctx.inFilter != null && ctx.inFilter.spr == this) ctx.baseShader.color.set(
			this.color.r * l.r, this.color.g * l.g, this.color.b * l.b, this.color.a * l.a
		);
		else if (ctx.inFilterBlend != null) ctx.baseShader.color.set(
			ctx.globalAlpha * l.a, ctx.globalAlpha * l.a, ctx.globalAlpha * l.a, ctx.globalAlpha * l.a
		);
		else ctx.baseShader.color.set(this.color.r * l.r, this.color.g * l.g, this.color.b * l.b, this.color.a * ctx.globalAlpha * l.a);
	}
}