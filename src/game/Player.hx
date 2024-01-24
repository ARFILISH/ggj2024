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
    private var hud : HUD;
    private var grazeParticles : Particles;
    private var grazeParticleSettings : Dynamic;
    private var hitboxSprite : Bitmap;

    private var invincibility : Float;

    private var focusing : Bool;

    private var damagedTime : Float;
    private var timeBeforeDeath : Float;

    public var score(default, null) : Int;
    public var lives(default, null) : Int;
    public var availableBullets(default, null) : Int;
    public var bulletLevel(default, null) : Int;
    public var power(default, null) : Float;
    public var grazePoints(default, null) : Int;
    
    public var canShoot : Bool;

    private override function added(s2d: h2d.Scene):Void {
        sprite = new Sprite();
        s2d.add(sprite, 3);
        sprite.load("sprites/game/sprPlayer.xml");
        sprite.addShader(new shaders.Blink(0, 0.17, Vector4.fromColor(0x00000000), 1.0));
        hitboxSprite = new Bitmap(hxd.Res.sprites.game.sprPlayerHitbox.toTile().center(), s2d);
        grazeParticles = new Particles(s2d);
        grazeParticles.onEnd = grazeParticles.removeGroup.bind(grazeParticles.getGroup("main"));
        grazeParticleSettings = haxe.Json.parse(hxd.Res.particles.ptcPlayerGraze_json.entry.getText());
        velX = 0.0;
        velY = 0.0;
        focusing = false;
        availableBullets = 6;
        bulletLevel = 0;
        power = 0.0;
        hud = new HUD();
        Main.instance.hud.add(hud, 0);
        damagedTime = 0.0;
        timeBeforeDeath = -1.0;
        canShoot = false;
    }

    private override function destroyed(s2d: h2d.Scene) {
        sprite.remove();
        sprite = null;
        hitboxSprite.remove();
        hitboxSprite = null;
        grazeParticles.remove();
        grazeParticles = null;
        hud.remove();
    }

    private override function preUpdate() {
        final input = InputManager.instance;
        if (timeBeforeDeath > 0.0) {
            velX = 0.0;
            velY = 0.0;
            return;
        }
        if (input.getActionResult(Types.InputActions.Shoot)) shoot();
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
        if (timeBeforeDeath > 0.0) {
            timeBeforeDeath = hxd.Math.max(timeBeforeDeath - delta, 0.0);
            return;
        } else if (timeBeforeDeath == 0.0) {
            destroy();
            return;
        }
        if (damagedTime > 0.0) {
            grazePoints = 0;
            damagedTime -= delta;
        } else if (damagedTime < 0.0) damagedTime = 0.0;
        if (invincibility > 0.0) invincibility = hxd.Math.max(invincibility - delta, 0.0);
        x += velX * delta;
        x = hxd.Math.clamp(x, Const.PLAYFIELD_PLAYABLE_LEFT + 16.0, Const.PLAYFIELD_PLAYABLE_RIGHT - 16.0);
        y += velY * delta;
        y = hxd.Math.clamp(y, Const.PLAYFIELD_PLAYABLE_TOP + 16.0, Const.PLAYFIELD_PLAYABLE_BOTTOM - 16.0);
    }

    private override function render():Void {
        sprite.getShader(shaders.Blink).enabled = (invincibility > 0.0 ? 1 : 0);
        if (focusing) sprite.play(PlayerAnimation.Focus);
        else sprite.play(velX < 0.0 ? PlayerAnimation.Left : (velX > 0.0 ? PlayerAnimation.Right : PlayerAnimation.Forward));
        hitboxSprite.visible = focusing;
        sprite.x = hitboxSprite.x = grazeParticles.x = x;
        sprite.y = hitboxSprite.y = grazeParticles.y = y;
    }

    public function levelStarted():Void {
        canShoot = true;
        invincibility = 2.0;
        x = Const.PLAYER_START_X;
        y = Const.PLAYER_START_Y;
        score = 0;
        lives = 4;
        grazePoints = 0;
        hud.update(this);
    }

    private function shoot():Void {
        if (availableBullets <= 0) return;
        final bullet = scene.spawnEntity(x, y - 16.0, PlayerBullet);
        bullet.setLevel(bulletLevel);
        availableBullets--;
        if (availableBullets <= 0) bulletLevel = 0;
        hud.update(this);
    }

    public function addPower(power: Float):Void {
        if (this.power >= 5.0) return;
        this.power = hxd.Math.min(this.power + power, 5.0);
        hud.update(this);
    }

    public function addBullet():Void {
        availableBullets++;
        if (bulletLevel < 3 && availableBullets == 8 * (bulletLevel + 1) * 2) {
            availableBullets = Std.int(availableBullets / 2);
            bulletLevel++;
        }
        hud.update(this);
    }

    public function addScore(score: Int):Void {
        this.score += score;
        hud.update(this);
    }

    public function graze(by: { grazeCount : Int }):Void {
        if (damagedTime > 0.0 || timeBeforeDeath >= 0.0) return;
        if (by.grazeCount < 1) {
            by.grazeCount++;
            grazeParticles.load(grazeParticleSettings);
            if (!AudioManager.instance.isPlaying(1)) AudioManager.instance.playSound(1, "sounds/sndPlayerGraze.wav");
            grazePoints++;
            hud.update(this);
        }
    }

    public function applyDamage():Void {
        if (invincibility > 0.0 || timeBeforeDeath >= 0.0) return;
        AudioManager.instance.playSound(0, "sounds/sndPlayerDamage.wav");
        lives--;
        if (lives > 0) {
            invincibility = 2.0;
            x = Const.PLAYER_START_X;
            y = Const.PLAYER_START_Y;
            damagedTime = 0.08;
            grazePoints = 0;
        } else {
            sprite.visible = false;
            timeBeforeDeath = 0.3;
        }
        hud.update(this);
    }

    @:keep inline public function isAlive():Bool {
        return !markedForDeletion && timeBeforeDeath < 0.0 && lives > 0;
    }
}