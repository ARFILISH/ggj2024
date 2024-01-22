setSprite("sprites/game/sprPlayer.png");

function test1() {
    setSprite("sprites/game/sprPlayerHitbox.png");
}

function test2() {
    enqueueMoveToByTime(WorldSpace(player.x + offX, player.y), 0.2);
    enqueueMoveToBySpeed(EntitySpace(player, 0.0, 0.0), speed);
    enqueueMoveToByTime(RelativeSpace(0.0, 80.0), 1.5);
}

function skip() {
    trace("Skipped");
    nextMove();
}

addEvent(2.0, test1);
addEvent(6.0, test2);
if (i < 3) {
    addEvent(8.0, skip);
}