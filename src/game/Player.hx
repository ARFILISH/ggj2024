package game;

import h3d.Vector4;
import h2d.Bitmap;
import heaps.Sprite;

enum abstract PlayerAnimation(Int) from Int to Int {
    final Forward = 0;
    final Left = 1;
    final Right = 2;
    final Focus = 3;
}

class Player extends Entity {
    public var velX : Float;
    public var velY : Float;

    private var sprite : Sprite;
    private var hitboxSprite : Bitmap;

    private var invincibility : Float;

    private var focusing : Bool;

    private override function added(s2d: h2d.Scene):Void {
        final tiles = hxd.Res.sprites.game.sprPlayer.toTile().grid(32.0);
        sprite = new Sprite(s2d);
        sprite.addAnimation(PlayerAnimation.Forward, [tiles[0][0].center(), tiles[1][0].center()], 15.0, true);
        sprite.addAnimation(PlayerAnimation.Left, [tiles[0][1].center(), tiles[1][1].center()], 15.0, true);
        sprite.addAnimation(PlayerAnimation.Right, [tiles[0][2].center(), tiles[1][2].center()], 15.0, true);
        sprite.addAnimation(PlayerAnimation.Focus, [tiles[0][3].center()], 15.0, true);
        sprite.addShader(new shaders.Blink(0, 0.17, Vector4.fromColor(0x00000000), 1.0));
        hitboxSprite = new Bitmap(hxd.Res.sprites.game.sprPlayerHitbox.toTile().center(), s2d);
        velX = 0.0;
        velY = 0.0;
        focusing = false;
        invincibility = 2.0;
    }

    private override function destroyed(s2d: h2d.Scene) {
        sprite.remove();
        sprite = null;
        hitboxSprite.remove();
        hitboxSprite = null;
    }

    private override function preUpdate() {
        final input = InputManager.instance;
        focusing = input.getActionResult(Types.InputActions.Focus);
        final hInput = input.getActionValue(Types.InputActions.MoveRight) - input.getActionValue(Types.InputActions.MoveLeft);
        final vInput = input.getActionValue(Types.InputActions.MoveDown) - input.getActionValue(Types.InputActions.MoveUp);
        var length = (hInput * hInput + vInput * vInput);
        if (length > 0.0) { 
            length = Math.sqrt(length);
            velX = hInput / length * (focusing ? Const.PLAYER_FOCUS_MOVEMENT_SPEED : Const.PLAYER_DEFAULT_MOVEMENT_SPEED);
            velY = vInput / length * (focusing ? Const.PLAYER_FOCUS_MOVEMENT_SPEED : Const.PLAYER_DEFAULT_MOVEMENT_SPEED);
        } else velX = velY = 0.0;
    }

    private override function update(delta: Float) {
        if (invincibility > 0.0) invincibility = hxd.Math.max(invincibility - delta, 0.0);
        x += velX * delta;
        x = hxd.Math.clamp(x, 16.0, 304.0);
        y += velY * delta;
        y = hxd.Math.clamp(y, 16.0, 164.0);
    }

    private override function render():Void {
        sprite.getShader(shaders.Blink).enabled = (invincibility > 0.0 ? 1 : 0);
        if (focusing) sprite.play(PlayerAnimation.Focus);
        else sprite.play(velX < 0.0 ? PlayerAnimation.Left : (velX > 0.0 ? PlayerAnimation.Right : PlayerAnimation.Forward));
        hitboxSprite.visible = focusing;
        sprite.x = hitboxSprite.x = x;
        sprite.y = hitboxSprite.y = y;
    }
}