setSprite("sprites/game/sprPlayer.xml");
setRadius(3.0);

function test2() {
    enqueueMoveToByTime(WorldSpace(player.x + offX, player.y), 0.2);
    enqueueMoveToBySpeed(EntitySpace(player, 0.0, 0.0), speed);
    enqueueMoveToByTime(RelativeSpace(0.0, 80.0), 1.5, destroy);
}

function skip() {
    nextMove();
}

addEvent(6.0, test2);
if (i < 3) {
    addEvent(8.0, skip);
}