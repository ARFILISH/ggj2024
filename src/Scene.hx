class Scene {
    @:allow(Main.update)
    private function entered(s2d: h2d.Scene):Void { }
    @:allow(Main.update)
    private function exited(s2d: h2d.Scene):Void { }

    public function spawnEntity<T:Entity>(x: Float, y: Float, cl: Class<Entity>):Void {
        var ent = Type.createInstance(cl, [x, y, this]);
        Main.instance.addEntity(ent);
    }
}