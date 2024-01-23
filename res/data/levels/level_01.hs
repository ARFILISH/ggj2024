function spawn() {
    for (i in 0...1) {
        setPreparedParam("idx", i);
        spawnEnemy(LocalSpace(35.0 * i, -40.0), "data/levels/level_01_enemy0.hs");
    }
    clearPreparedParams();
}

addEvent(6.0, spawn);