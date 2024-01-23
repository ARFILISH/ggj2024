setSprite("sprites/game/sprPlayer.xml");
enqueueMoveToByTime(RelativeSpace(getRelativeX() * 3.0, 25.0), 1.0);
setRadius(16.0);
setMask(1 | 2);
createBulletManager(0);
loadBulletManagerBullets(0, "sprites/game/sprBullets01.xml");
setBulletManagerTile(0, 0);
setBulletManagerAimType(0, AimEntityFan(player));
setBulletManagerSpeed(0, 150.0, 200.0);
setBulletManagerCount(0, 3, 3);
setBulletManagerAngle(0, 0.0, Math.degToRad(5.0));
setBulletManagerHitmask(0, 1 | 2);
setBulletManagerRadius(0, 2.0, 4.0);
setBulletManagerHitRadius(0, 4.0);
setBulletManagerMoveType(0, MoveTypeFixed());
setBulletManagerAutoDestroy(0, false);

function test2() {
    enqueueMoveToByTime(RelativeSpace(idx * 40.0, 30.0), 0.5);
}

function shoot() {
    bulletManagerShoot(0);
}

function stop() {
    setBulletManagerMoveType(0, MoveTypeStop);
}

function changeAim() {
    setBulletManagerAimType(0, AimFan);
    setBulletManagerAngle(0, Math.PI * 0.5, Math.degToRad(5.0));
}

function changeDir() {
    setBulletManagerMoveType(0, MoveTypePosition(EntitySpace(player)));
}

function resetDir() {
    setBulletManagerMoveType(0, MoveTypeFixed(getSpeed));
    setBulletManagerAutoDestroy(0, true);
}

function getSpeed() {
    return Math.degToRad(80.0);
}

function wait() {
    setBulletManagerMoveType(0, MoveTypeFixed(getSpeed));
    setBulletManagerSpeed(0, 120.0, 150.0);
    setBulletManagerCount(0, 15, 4);
    setBulletManagerAimType(0, AimRandomCircle);
    setBulletManagerTile(0, 1);
    setBulletManagerAngle(0, 0.0, Math.degToRad(4.0));
    moveToByTime(RelativeSpace(idx < 0 ? -190.0 : 190.0, idx > 0 ? 140.0 : 90.0), 2.0);
}

addEvent(2.0, test2);
for (i in 0...4) addEvent(3.0 + i * 0.15, shoot);
addEvent(4.0, changeAim);
for (i in 0...3) addEvent(4.1 + i * 0.15, shoot);
addEvent(5.0, stop);
addEvent(6.0, changeDir);
addEvent(7.04, resetDir);
addEvent(8.0, wait);
addEvent(9.0, shoot);