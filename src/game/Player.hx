package game;

import h2d.Particles;
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
    private var grazeParticles : Particles;
    private var grazeParticleSettings : Dynamic;
    private var hitboxSprite : Bitmap;

    private var invincibility : Float;

    private var focusing : Bool;

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite(s2d);
        sprite.load("sprites/game/sprPlayer.xml");
        sprite.addShader(new shaders.Blink(0, 0.17, Vector4.fromColor(0x00000000), 1.0));
        hitboxSprite = new Bitmap(hxd.Res.sprites.game.sprPlayerHitbox.toTile().center(), s2d);
        grazeParticles = new Particles(s2d);
        grazeParticles.onEnd = grazeParticles.removeGroup.bind(grazeParticles.getGroup("main"));
        grazeParticleSettings = haxe.Json.parse(hxd.Res.particles.ptcPlayerGraze_json.entry.getText());
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
        grazeParticles.remove();
        grazeParticles = null;
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
        sprite.x = hitboxSprite.x = grazeParticles.x = x;
        sprite.y = hitboxSprite.y = grazeParticles.y = y;
    }

    public function graze(by: { grazeCount : Int }):Void {
        if (by.grazeCount < 1) {
            by.grazeCount++;
            grazeParticles.load(grazeParticleSettings);
            if (!AudioManager.instance.isPlaying(1)) AudioManager.instance.playSound(1, "sounds/sndPlayerGraze.wav");
        }
    }

    public function applyDamage():Void {
        if (invincibility > 0.0) return;
        AudioManager.instance.playSound(0, "sounds/sndPlayerDamage.wav");
        invincibility = 2.0;
        x = Const.PLAYER_START_X;
        y = Const.PLAYER_START_Y;
    }
}