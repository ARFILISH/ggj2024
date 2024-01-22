function spawn() {
    for (i in -2...7) {
        setPreparedParam("offX", i * 3.0);
        setPreparedParam("speed", i * 30.0);
        setPreparedParam("i", i);
        spawnEnemy(LocalSpace(35.0 * i, 25.0), "data/levels/level_01_enemy0.hs");
    }
    clearPreparedParams();
}

addEvent(6.0, spawn);