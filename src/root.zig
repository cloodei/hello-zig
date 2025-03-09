//! Testing zig's SDL, raylib-ish game engine

const std = @import("std");
const math = std.math;
const sdl = @import("sdl");

const SCREEN_WIDTH  = 800;
const SCREEN_HEIGHT = 600;

const Player = struct {
    x:      f32,
    y:      f32,
    width:  f32,
    height: f32,
    speed:  f32,
};

const Obstacle = struct {
    x:      f32,
    y:      f32,
    width:  f32,
    height: f32,
    speed:  f32,
};

const Projectile = struct {
    x:     f32,
    y:     f32,
    speed: f32,
};

fn initPlayer() Player {
    return Player{
        .x = SCREEN_WIDTH / 2 - 25,
        .y = SCREEN_HEIGHT - 60,
        .width = 50,
        .height = 50,
        .speed = 5.0,
    };
}

fn initObstacle(x: f32, y: f32) Obstacle {
    return Obstacle{
        .x = x,
        .y = y,
        .width = 40,
        .height = 40,
        .speed = 2.0,
    };
}

fn drawRect(renderer: *sdl.Renderer, x: f32, y: f32, width: f32, height: f32, r: u8, g: u8, b: u8) void {
    renderer.setDrawColor(r, g, b, 255);
    const rect = sdl.Rect{
        .x = @intFromFloat(x),
        .y = @intFromFloat(y),
        .w = @intFromFloat(width),
        .h = @intFromFloat(height),
    };
    renderer.fillRect(rect);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try sdl.init(.{ .video = true });
    defer sdl.quit();

    var window = try sdl.createWindow(
        "Shooter Game",
        .{
            .width = SCREEN_WIDTH,
            .height = SCREEN_HEIGHT
        },
    );
    defer window.destroy();

    var renderer = try sdl.createRenderer(window, null, .{});
    defer renderer.destroy();

    var player = initPlayer();
    var obstacles = std.ArrayList(Obstacle).init(allocator);
    defer obstacles.deinit();

    var projectiles = std.ArrayList(Projectile).init(allocator);
    defer projectiles.deinit();

    var rng = std.Random.DefaultPrng.init(0);
    const random = rng.random();

    var i: usize = 0;
    inline while(i < 5) : (i += 1) {
        const x = random.float(f32) * (SCREEN_WIDTH - 40);
        const y = random.float(f32) * (SCREEN_HEIGHT / 2);
        try obstacles.append(initObstacle(x, y));
    }

    var running = true;
    while(running) {
        var event: sdl.Event = undefined;
        while(sdl.pollEvent(&event)) {
            switch(event.type) {
                .quit => running = false,
                else => {},
            }
        }
        const keys = sdl.getKeyboardState();
        if(keys[sdl.Scancode.up])
            player.y -= player.speed;
        if(keys[sdl.Scancode.down])
            player.y += player.speed;
        if(keys[sdl.Scancode.left])
            player.x -= player.speed;
        if(keys[sdl.Scancode.right])
            player.x += player.speed;

        player.x = math.clamp(player.x, 0, SCREEN_WIDTH - player.width);
        player.y = math.clamp(player.y, 0, SCREEN_HEIGHT - player.height);

        if(keys[sdl.Scancode.space]) {
            try projectiles.append(Projectile {
                .x = player.x + player.width / 2,
                .y = player.y,
                .speed = 7.0,
            });
        }

        for(projectiles.items) |*proj|
            proj.y -= proj.speed;

        var j: usize = 0;
        while(j < projectiles.items.len) {
            if(projectiles.items[j].y < 0) {
                _ = projectiles.swapRemove(j);
            }
            else {
                j += 1;
            }
        }

        for(obstacles.items) |*obs| {
            obs.y += obs.speed;
            if(obs.y > SCREEN_HEIGHT) {
                obs.y = -obs.height;
                obs.x = random.float(f32) * (SCREEN_WIDTH - obs.width);
            }
        }

        for(obstacles.items) |obs| {
            if(player.x < obs.x + obs.width and
            player.x + player.width > obs.x and
            player.y < obs.y + obs.height and
            player.y + player.height > obs.y)
                running = false;
        }

        var k: usize = 0;
        while(k < projectiles.items.len) {
            var hit = false;
            var l: usize = 0;
            while(l < obstacles.items.len) : (l += 1) {
                const proj = projectiles.items[k];
                const obs = obstacles.items[l];
                if(proj.x < obs.x + obs.width and
                proj.x > obs.x and
                proj.y < obs.y + obs.height and
                proj.y > obs.y) {
                    _ = projectiles.swapRemove(k);
                    _ = obstacles.swapRemove(l);
                    hit = true;
                    break;
                }
            }

            if(!hit)
                k += 1;
        }

        renderer.setDrawColor(0, 0, 0, 255);
        renderer.clear();

        drawRect(renderer, player.x, player.y, player.width, player.height, 0, 255, 0);

        for(obstacles.items) |obs| {
            drawRect(renderer, obs.x, obs.y, obs.width, obs.height, 255, 0, 0);
        }

        for(projectiles.items) |proj| {
            drawRect(renderer, proj.x, proj.y, 5, 10, 255, 255, 255);
        }

        renderer.present();
        sdl.delay(16);
    }

    std.debug.print("Game Over!\n", .{});
}
