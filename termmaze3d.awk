#!/usr/bin/awk -f

# Name    : termmaze3d.awk
# Purpose : Pseudo-3D first-person shooter written in AWK
#
# Author  : KUSANAGI Mitsuhisa <mikkun@mbg.nifty.com>
# License : MIT License

# Usage : ./termmaze3d.awk

BEGIN {
    TERM_W = 80
    TERM_H = 22
    MINIMAP_COL = 9
    MINIMAP_ROW = 9
    MINIMAP_X   = TERM_W - 2 - MINIMAP_COL * 2
    MINIMAP_Y   = TERM_H - 1 - MINIMAP_ROW
    SCREEN_W = TERM_W - 6 - MINIMAP_COL * 2
    SCREEN_H = TERM_H - 2
    SCREEN_X = 2
    SCREEN_Y = 1
    INFO_X = MINIMAP_X
    INFO_Y = SCREEN_Y

    WORLD_MAP_W = 22
    WORLD_MAP_H = 22

    TEXTURE_W = 20
    TEXTURE_H = 10
    TEXTURE_STR["monster", 0] = \
    "00000000000000000000" \
    "00009000000000900000" \
    "00009999111999900000" \
    "00000117227115115000" \
    "00115111111115011500" \
    "11150051111110009190" \
    "91910011100511000000" \
    "00000115000111500000" \
    "00009195000111500000" \
    "00000000000919190000"
    TEXTURE_STR["monster", 1] = \
    "00000000000000000000" \
    "00000900000000090000" \
    "00000999911199990000" \
    "00011151172271100000" \
    "00115011111111511500" \
    "09190001111115001115" \
    "00000011100511001919" \
    "00000111500011500000" \
    "00000111500019190000" \
    "00009191900000000000"
    TEXTURE_STR["monster", 2] = \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00009000000000000000" \
    "00009991722741999900" \
    "00091919511919411000" \
    "09951115400111195990"
    TEXTURE_STR["tree", 0] = \
    "00000022222202000000" \
    "00002302222322320000" \
    "00022222322222202000" \
    "00203222223122223200" \
    "02022223222223222020" \
    "02222322222232232220" \
    "00020232133321022000" \
    "00000003331310000000" \
    "00000003333310000000" \
    "00000033103031000000"
    TEXTURE_STR["treasure", 0] = \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00003535555535300000" \
    "00003333333333300000" \
    "00003555393555300000" \
    "00003355555553300000"
    TEXTURE_STR["treasure", 1] = \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000"
    TEXTURE_STR["pistol", 0] = \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000064000000000" \
    "00000000244600000000" \
    "00000000466400000000" \
    "00000088422488000000" \
    "00000009888888000000"
    TEXTURE_STR["pistol", 1] = \
    "00000000000000000000" \
    "00000000011000000000" \
    "00000000133100000000" \
    "00000001377310000000" \
    "00000001777710000000" \
    "00000000175100000000" \
    "00000000244600000000" \
    "00000000422400000000" \
    "00000088466488000000" \
    "00000009888888000000"
    TEXTURE_STR["pistol", 2] = \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000000000000000" \
    "00000000064000000000" \
    "00000000244600000000" \
    "00000000244600000000" \
    "00000000466480000000" \
    "00000088422488000000" \
    "00000009888888000000" \
    "00000000998888800000"

    STATE["STAND"]  = 1
    STATE["CHASE"]  = 2
    STATE["SHIFT"]  = 3
    STATE["ATTACK"] = 4
    STATE["HURT"]   = 7
    STATE["DEAD"]   = 8
    STATE["EMPTY"]  = 9

    MONSTER_SPEED = 0.03
    NUM_MONSTERS  = 4
    NUM_TREES     = 6
    NUM_TREASURES = 5
    NUM_SPRITES = NUM_MONSTERS + NUM_TREES + NUM_TREASURES
    split("name, frame_wait, frame_count, texture_num," \
          "pos_x, pos_y, next_pos_x, next_pos_y, dist," \
          "health, is_target, state",                   \
          SPRITE_PROP_KEYS,                             \
          /[,\\ \n]+/)

    WEAPON_X = int((SCREEN_W - TEXTURE_W) / 2)
    WEAPON_Y = SCREEN_H - TEXTURE_H
    NUM_WEAPONS = 1
    split("name, frame_wait, frame_count, texture_num," \
          "hitbox_w, damage, max_ammo, ammo",           \
          WEAPON_PROP_KEYS,                             \
          /[,\\ \n]+/)
    WEAPON_PROPS[0] \
        = "name: pistol, frame_wait: 6, hitbox_w: 4, damage: 2, max_ammo: 13"

    MOVE_SPEED = 0.1
    ROT_SPEED  = 0.3
    COLLISION_R = 0.25
    EPSILON = 0.00001

    START_TIME = 4000
    DIFF_TIME  =    2
    DAMAGE = int(START_TIME / 10)

    DELAY_SEC = 0.1
    READING_KEY_CMD \
        = "((while :; do echo ''; sleep " DELAY_SEC "; done) &"       \
          " (while :; do echo $(dd bs=1 count=1 conv=lcase); done)) " \
          "2> /dev/null"

    error_message = ""
    if (system("sleep 0.1 2> /dev/null")) {
        error_message = "'sleep' does not support floating point numbers"
        prog_name = ENVIRON["_"]
        sub(/^.*\//, "", prog_name)
        print prog_name ": " error_message > "/dev/stderr"
        exit 1
    }

    srand()
    printf("\033[?25l")
    printf("\033[1;1H")
    printf("\033[2J")
    stty_cmd = "stty -g"
    stty_cmd | getline prev_term_settings
    close(stty_cmd)
    system("stty raw -echo")

    pos_x      = 1.5
    pos_y      = 1.5
    next_pos_x = pos_x
    next_pos_y = pos_y
    dir_x      = 1
    dir_y      = 0
    prev_dir_x = dir_x
    plane_x      = 0
    plane_y      = 0.66
    prev_plane_x = plane_x

    sprite_id = 0
    generate_world_map()
    load_textures()
    init_sprites()
    init_weapons()

    time_left = START_TIME
    treasure_count = 0
    is_attacked = 0
    is_gameover = 0
    has_won     = 0

    frame_count = 0
    is_paused = 0
    while (1) {
        if (frame_count % 2 == 0) {
            frame_count = 0
            read_keys()
            if (is_paused) {
                frame_count++
                continue
            }
            update_weapon()
            update_sprites()
            raycast()
            time_left--
            if (time_left < 0) {
                time_left = 0
                exit 0
            }
            is_firing = 0
        }
        else {
            buffer = build_info(INFO_X, INFO_Y)
            if (!is_paused) {
                buffer = buffer build_screen(SCREEN_X, SCREEN_Y)
                buffer = buffer build_minimap(MINIMAP_X, MINIMAP_Y)
            }
            printf buffer
            system("")
        }
        frame_count++
    }
}

END {
    if (error_message) {
        close("/dev/stderr")
        exit 1
    }

    is_gameover = 1
    buffer = build_info(INFO_X, INFO_Y)
    printf buffer
    system("")

    system("sleep 0.7 2> /dev/null")
    printf("\033[1;1H")
    close(READING_KEY_CMD)
    system("stty " prev_term_settings)
    printf("\033[%d;1H", TERM_H + 1)
    printf("\033[?25h")
}

function abs(num) {
    return num < 0 ? -num : num
}

function has_collision(x1, y1, x2, y2,    dx, dy, dist) {
    dx = x2 - x1
    dy = y2 - y1
    dist = COLLISION_R * 2

    if (abs(dx) > dist || abs(dy) > dist) { return 0 }
    if (dx ^ 2 + dy ^ 2 > dist ^ 2)       { return 0 }
    return 1
}

function _init_cells(    x, y) {
    for (y = 0; y < WORLD_MAP_H; y++) {
        for (x = 0; x < WORLD_MAP_W; x++) {
            if (x % 2 == 0 || y % 2 == 0) { world_map[x, y] = 0 }
            else { world_map[x, y] = int(rand() * 2) }
        }
    }
}

function _count_walls(center_x, center_y, r,    num_walls, x, y) {
    num_walls = 0
    for (y = center_y - r; y <= center_y + r; y++) {
        for (x = center_x - r; x <= center_x + r; x++) {
            if (x != center_x || y != center_y) {
                if ( x < 0 || x > WORLD_MAP_W - 1 \
                  || y < 0 || y > WORLD_MAP_H - 1 \
                  || world_map[x, y] == 1 ) { num_walls++ }
            }
        }
    }
    return num_walls
}

function _place_wall(x, y,    num_walls_r1, num_walls_r2) {
    num_walls_r1 = _count_walls(x, y, 1)
    num_walls_r2 = _count_walls(x, y, 2)

    if (world_map[x, y] == 1) {
        if (num_walls_r1 >= 3) { return 1 }
    }
    else {
        if (num_walls_r1 >= 5 || num_walls_r2 <= 2) { return 1 }
    }
    return 0
}

function _place_sprites(name, num_sprites,    i, x, y) {
    if (num_sprites < 1) { return }
    num_sprites = num_sprites > WORLD_MAP_W ? WORLD_MAP_W : num_sprites

    i = 0
    while (1) {
        for (y = 0; y < WORLD_MAP_H; y += 2) {
            for (x = 0; x < WORLD_MAP_W; x++) {
                if ( world_map[x, y] == 0 \
                  && int(rand() * (WORLD_MAP_W * WORLD_MAP_H)) == 0 ) {
                    sprite_props[sprite_id++] \
                        = sprintf("name: %s, pos_x: %.1f, pos_y: %.1f", \
                                   name,     x + 0.5,     y + 0.5)
                    world_map[x, y] = 9
                    if (++i == num_sprites) { return }
                }
            }
        }
    }
}

function generate_world_map(    x, y) {
    _init_cells()
    for (y = 0; y < WORLD_MAP_H; y++) {
        for (x = 0; x < WORLD_MAP_W; x++) {
            world_map[x, y] = _place_wall(x, y)
        }
    }

    for (y = int(pos_y) - 2; y <= int(pos_y) + 2; y++) {
        for (x = int(pos_x) - 2; x <= int(pos_x) + 2; x++) {
            if ( x >= 0 && x <= WORLD_MAP_W - 1 \
              && y >= 0 && y <= WORLD_MAP_H - 1 ) { world_map[x, y] = 0 }
        }
    }
    for (y = 0; y < WORLD_MAP_H; y++) {
        for (x = 0; x < WORLD_MAP_W; x++) {
            if ( x == 0 || x == WORLD_MAP_W - 1 \
              || y == 0 || y == WORLD_MAP_H - 1 ) { world_map[x, y] = 1 }
        }
    }

    world_map[int(pos_x), int(pos_y)] = 9
    _place_sprites("monster",  NUM_MONSTERS)
    _place_sprites("tree",     NUM_TREES)
    _place_sprites("treasure", NUM_TREASURES)
    for (y = 0; y < WORLD_MAP_H; y++) {
        for (x = 0; x < WORLD_MAP_W; x++) {
            if (world_map[x, y] == 9) { world_map[x, y] = 0 }
        }
    }
}

function load_textures(    prop_values, x, y) {
    for (prop_values in TEXTURE_STR) {
        for (y = 0; y < TEXTURE_H; y++) {
            for (x = 0; x < TEXTURE_W; x++) {
                texture[prop_values, x, y] \
                    = substr(TEXTURE_STR[prop_values], \
                             TEXTURE_W * y + x + 1,    \
                             1) + 0
            }
        }
    }
}

function init_sprites(    prop_key, num_pairs, keys_and_values, i, j) {
    num_pairs = gsub(/:/, ":", sprite_props[0])
    for (i = 0; i < NUM_SPRITES; i++) {
        for (prop_key in SPRITE_PROP_KEYS) {
            sprites[i, SPRITE_PROP_KEYS[prop_key]] = 0
        }
        split(sprite_props[i], keys_and_values, /[:,\\ \n]+/)
        for (j = 1; j < num_pairs * 2; j += 2) {
            sprites[i, keys_and_values[j]] = keys_and_values[j + 1]
        }
        sprites[i, "next_pos_x"] = sprites[i, "pos_x"]
        sprites[i, "next_pos_y"] = sprites[i, "pos_y"]
        sprites[i, "state"]      = STATE["STAND"]
        if (sprites[i, "name"] == "monster") {
            sprites[i, "frame_wait"] = 2
            sprites[i, "health"]     = 5
            sprites[i, "state"]      = STATE["CHASE"]
        }
    }
}

function init_weapons(    prop_key, num_pairs, keys_and_values, i, j) {
    num_pairs = gsub(/:/, ":", WEAPON_PROPS[0])
    for (i = 0; i < NUM_WEAPONS; i++) {
        for (prop_key in WEAPON_PROP_KEYS) {
            weapons[i, WEAPON_PROP_KEYS[prop_key]] = 0
        }
        split(WEAPON_PROPS[i], keys_and_values, /[:,\\ \n]+/)
        for (j = 1; j < num_pairs * 2; j += 2) {
            weapons[i, keys_and_values[j]] = keys_and_values[j + 1]
        }
        weapons[i, "ammo"] = weapons[i, "max_ammo"]
    }
    weapon_num = 0
    hitbox_start = int((SCREEN_W - weapons[weapon_num, "hitbox_w"]) / 2)
    hitbox_end   = hitbox_start + weapons[weapon_num, "hitbox_w"]
    can_fire  = 1
    is_firing = 0
}

function read_keys(    key, can_move, i) {
    READING_KEY_CMD | getline key

    if (is_paused) {
        if (key == "q") { exit 0        }
        if (key == "p") { is_paused = 0 }
        return
    }
    if (key == "q") { exit 0                }
    if (key == "p") { is_paused = 1; return }

    if (key == "") {
        time_left -= DIFF_TIME
        return
    }

    if (key == "w") {
        next_pos_x = pos_x + dir_x * MOVE_SPEED
        next_pos_y = pos_y + dir_y * MOVE_SPEED
    }
    if (key == "s") {
        next_pos_x = pos_x - dir_x * MOVE_SPEED
        next_pos_y = pos_y - dir_y * MOVE_SPEED
    }
    if (key == "a") {
        next_pos_x = pos_x - plane_x * MOVE_SPEED
        next_pos_y = pos_y - plane_y * MOVE_SPEED
    }
    if (key == "d") {
        next_pos_x = pos_x + plane_x * MOVE_SPEED
        next_pos_y = pos_y + plane_y * MOVE_SPEED
    }
    can_move = 1
    for (i = 0; i < NUM_SPRITES; i++) {
        if (sprites[i, "state"] == STATE["DEAD"])  { continue }
        if (sprites[i, "state"] == STATE["EMPTY"]) { continue }
        if ( has_collision(next_pos_x, next_pos_y, \
                           sprites[i, "pos_x"], sprites[i, "pos_y"]) ) {
            can_move = 0
            if (sprites[i, "name"] == "treasure") {
                sprites[i, "texture_num"] = 1
                sprites[i, "state"]       = STATE["EMPTY"]
                treasure_count++
                if (treasure_count == NUM_TREASURES) {
                    has_won = 1
                    exit 0
                }
                can_move = 1
            }
        }
    }
    if (can_move) {
        if (world_map[int(next_pos_x), int(pos_y)] != 1) {
            pos_x = next_pos_x
        }
        if (world_map[int(pos_x), int(next_pos_y)] != 1) {
            pos_y = next_pos_y
        }
    }

    if (key == "j") {
        prev_dir_x = dir_x
        dir_x = dir_x * cos(-ROT_SPEED) - dir_y * sin(-ROT_SPEED)
        dir_y = prev_dir_x * sin(-ROT_SPEED) + dir_y * cos(-ROT_SPEED)
        prev_plane_x = plane_x
        plane_x = plane_x * cos(-ROT_SPEED) - plane_y * sin(-ROT_SPEED)
        plane_y = prev_plane_x * sin(-ROT_SPEED) + plane_y * cos(-ROT_SPEED)
    }
    if (key == "l") {
        prev_dir_x = dir_x
        dir_x = dir_x * cos(ROT_SPEED) - dir_y * sin(ROT_SPEED)
        dir_y = prev_dir_x * sin(ROT_SPEED) + dir_y * cos(ROT_SPEED)
        prev_plane_x = plane_x
        plane_x = plane_x * cos(ROT_SPEED) - plane_y * sin(ROT_SPEED)
        plane_y = prev_plane_x * sin(ROT_SPEED) + plane_y * cos(ROT_SPEED)
    }

    if (key == "k") {
        if (can_fire && weapons[weapon_num, "ammo"] > 0) {
            can_fire  = 0
            is_firing = 1
        }
    }
}

function update_weapon() {
    if (is_firing) {
        weapons[weapon_num, "frame_count"] = 0
        weapons[weapon_num, "texture_num"] = 1
        weapons[weapon_num, "ammo"]--
    }
    if (weapons[weapon_num, "frame_count"] \
            == weapons[weapon_num, "frame_wait"]) {
        weapons[weapon_num, "frame_count"] = 0
        if (weapons[weapon_num, "texture_num"] == 1) {
            weapons[weapon_num, "texture_num"] = 2
        }
        else if (weapons[weapon_num, "texture_num"] == 2) {
            weapons[weapon_num, "texture_num"] = 0
            can_fire = 1
        }
    }
    else {
        weapons[weapon_num, "frame_count"]++
    }
}

function update_sprites(    can_move, has_moved, offset_r, i, j) {
    is_attacked = 0
    for (i = NUM_SPRITES - 1; i >= 0; i--) {
        if (sprites[i, "state"] == STATE["ATTACK"]) {
            if (sprites[i, "dist"] > COLLISION_R * 2) {
                sprites[i, "frame_count"] = 0
                sprites[i, "state"]       = STATE["CHASE"]
            }
            else {
                if (sprites[i, "frame_count"] \
                        == sprites[i, "frame_wait"] * 4) {
                    sprites[i, "frame_count"] = 0
                    sprites[i, "texture_num"] \
                        = sprites[i, "texture_num"] == 0 ? 1 : 0
                    time_left -= DAMAGE
                    if (time_left < 0) {
                        time_left = 0
                        exit 0
                    }
                    is_attacked = 1
                }
                else {
                    sprites[i, "frame_count"]++
                }
            }
        }
        else if (sprites[i, "state"] == STATE["HURT"]) {
            if (sprites[i, "frame_count"] == sprites[i, "frame_wait"] * 3) {
                sprites[i, "frame_count"] = 0
                sprites[i, "state"]       = STATE["CHASE"]
            }
            else {
                sprites[i, "frame_count"]++
            }
        }
        else if (sprites[i, "state"] == STATE["DEAD"]) {
            sprites[i, "texture_num"] = 2
        }

        if (is_firing && sprites[i, "is_target"]) {
            if ( sprites[i, "name"]  == "monster" \
              && sprites[i, "state"] != STATE["DEAD"] ) {
                sprites[i, "health"] -= sprites[i, "dist"] > 21           \
                                      ? 0                                 \
                                      : sprites[i, "dist"] >  8           \
                                      ? weapons[weapon_num, "damage"] / 2 \
                                      : weapons[weapon_num, "damage"]
                sprites[i, "state"]   = sprites[i, "health"] > 0 \
                                      ? STATE["HURT"]            \
                                      : STATE["DEAD"]
                if (sprites[i, "state"] == STATE["HURT"]) {
                    sprites[i, "frame_count"] = 0
                }
            }
            is_firing = 0
        }

        if (sprites[i, "name"]  != "monster") { continue }
        if (sprites[i, "state"] == STATE["CHASE"]) {
            sprites[i, "next_pos_x"] \
                = pos_x - sprites[i, "pos_x"] >  COLLISION_R * 2 \
                ? sprites[i, "pos_x"] + MONSTER_SPEED            \
                : pos_x - sprites[i, "pos_x"] < -COLLISION_R * 2 \
                ? sprites[i, "pos_x"] - MONSTER_SPEED            \
                : sprites[i, "pos_x"]
            sprites[i, "next_pos_y"] \
                = pos_y - sprites[i, "pos_y"] >  COLLISION_R * 2 \
                ? sprites[i, "pos_y"] + MONSTER_SPEED            \
                : pos_y - sprites[i, "pos_y"] < -COLLISION_R * 2 \
                ? sprites[i, "pos_y"] - MONSTER_SPEED            \
                : sprites[i, "pos_y"]
        }
        else if (sprites[i, "state"] == STATE["SHIFT"]) {
            sprites[i, "next_pos_x"] \
                = sprites[i, "dist"] > COLLISION_R * 2                      \
                ? sprites[i, "pos_x"] + (int(rand() * 3) - 1) * COLLISION_R \
                : sprites[i, "pos_x"]
            sprites[i, "next_pos_y"] \
                = sprites[i, "dist"] > COLLISION_R * 2                      \
                ? sprites[i, "pos_y"] + (int(rand() * 3) - 1) * COLLISION_R \
                : sprites[i, "pos_y"]
            sprites[i, "state"] = STATE["CHASE"]
        }
        else { continue }
        can_move  = 1
        has_moved = 0
        for (j = NUM_SPRITES - 1; j >= 0; j--) {
            if (j == i) { continue }
            if (sprites[j, "state"] == STATE["DEAD"])  { continue }
            if (sprites[j, "state"] == STATE["EMPTY"]) { continue }
            if ( has_collision(sprites[i, "next_pos_x"], \
                               sprites[i, "next_pos_y"], \
                               sprites[j, "pos_x"],      \
                               sprites[j, "pos_y"]) ) {
                can_move = 0
            }
        }
        if (can_move) {
            offset_r = sprites[i, "next_pos_x"] - sprites[i, "pos_x"] > 0 \
                     ?  COLLISION_R * 2                                   \
                     : -COLLISION_R * 2
            if ( sprites[i, "next_pos_x"] != sprites[i, "pos_x"]     \
              && world_map[int(sprites[i, "next_pos_x"] + offset_r), \
                           int(sprites[i, "pos_y"])] != 1 ) {
                sprites[i, "pos_x"] = sprites[i, "next_pos_x"]
                has_moved = 1
            }
            offset_r = sprites[i, "next_pos_y"] - sprites[i, "pos_y"] > 0 \
                     ?  COLLISION_R * 2                                   \
                     : -COLLISION_R * 2
            if ( sprites[i, "next_pos_y"] != sprites[i, "pos_y"] \
              && world_map[int(sprites[i, "pos_x"]),             \
                           int(sprites[i, "next_pos_y"] + offset_r)] != 1 ) {
                sprites[i, "pos_y"] = sprites[i, "next_pos_y"]
                has_moved = 1
            }
        }
        if (has_moved) {
            if (sprites[i, "frame_count"] == sprites[i, "frame_wait"]) {
                sprites[i, "frame_count"] = 0
                sprites[i, "texture_num"] \
                    = sprites[i, "texture_num"] == 0 ? 1 : 0
            }
            else {
                sprites[i, "frame_count"]++
            }
        }
        else {
            sprites[i, "state"] = sprites[i, "dist"] > COLLISION_R * 2 \
                                ? STATE["SHIFT"]                       \
                                : STATE["ATTACK"]
        }
    }
}

function _calc_wall(    delta_dist_x, delta_dist_y, \
                        step_x, step_y,             \
                        side_dist_x, side_dist_y,   \
                        has_hit, line_h) {
    if (ray_dir_x == 0) { ray_dir_x = EPSILON }
    if (ray_dir_y == 0) { ray_dir_y = EPSILON }
    delta_dist_x = abs(1 / ray_dir_x)
    delta_dist_y = abs(1 / ray_dir_y)

    if (ray_dir_x < 0) {
        step_x = -1
        side_dist_x = (ray_pos_x - map_x) * delta_dist_x
    }
    else {
        step_x = 1
        side_dist_x = (map_x + 1 - ray_pos_x) * delta_dist_x
    }
    if (ray_dir_y < 0) {
        step_y = -1
        side_dist_y = (ray_pos_y - map_y) * delta_dist_y
    }
    else {
        step_y = 1
        side_dist_y = (map_y + 1 - ray_pos_y) * delta_dist_y
    }
    has_hit = 0
    while (!has_hit) {
        if (side_dist_x < side_dist_y) {
            side_dist_x += delta_dist_x
            map_x += step_x
            hit_side = "x"
        }
        else {
            side_dist_y += delta_dist_y
            map_y += step_y
            hit_side = "y"
        }
        if (world_map[map_x, map_y] == 1) { has_hit = 1 }
    }

    perp_wall_dist = hit_side == "x"                                         \
                   ? abs((map_x - ray_pos_x + (1 - step_x) / 2) / ray_dir_x) \
                   : abs((map_y - ray_pos_y + (1 - step_y) / 2) / ray_dir_y)

    if (perp_wall_dist == 0) { perp_wall_dist = EPSILON }
    line_h = abs(int(SCREEN_H / perp_wall_dist))

    line_start = (-line_h + SCREEN_H) / 2
    line_start = line_start < 0 ? 0 : int(line_start)
    line_end = (line_h + SCREEN_H) / 2
    line_end = line_end >= SCREEN_H ? SCREEN_H - 1 : int(line_end)
}

function _cast_wall(x,    pixel, y) {
    for (y = 0; y < SCREEN_H; y++) {
        if (y < line_start || y > line_end) {
            pixel = y > SCREEN_H * 0.8    \
                  ? "\033[30;42m░\033[0m" \
                  : y > SCREEN_H * 0.5    \
                  ? "\033[33;42m░\033[0m" \
                  : y > SCREEN_H * 0.3    \
                  ? "\033[37;46m░\033[0m" \
                  : "\033[36;46m \033[0m"
        }
        else {
            pixel = hit_side == "y"       \
                  ? "\033[30;47m░\033[0m" \
                  : "\033[37;47m \033[0m"
        }
        pixels[x, y] = pixel
    }
}

function _sort_sprites(    prop_key, value_of, i, j) {
    for (i = 0; i < NUM_SPRITES; i++) {
        for (prop_key in SPRITE_PROP_KEYS) {
            value_of[SPRITE_PROP_KEYS[prop_key]] \
                = sprites[i, SPRITE_PROP_KEYS[prop_key]]
        }
        j = i - 1
        while (j >= 0 && sprites[j, "dist"] < value_of["dist"]) {
            for (prop_key in SPRITE_PROP_KEYS) {
                sprites[j + 1, SPRITE_PROP_KEYS[prop_key]] \
                    = sprites[j, SPRITE_PROP_KEYS[prop_key]]
            }
            j--
        }
        for (prop_key in SPRITE_PROP_KEYS) {
            sprites[j + 1, SPRITE_PROP_KEYS[prop_key]] \
                = value_of[SPRITE_PROP_KEYS[prop_key]]
        }
    }
}

function _calc_sprite(i,    sprite_x, sprite_y) {
    sprite_x = sprites[i, "pos_x"] - pos_x
    sprite_y = sprites[i, "pos_y"] - pos_y

    transform_x = inv_determinant * (dir_y * sprite_x - dir_x * sprite_y)
    transform_y = inv_determinant * (-plane_y * sprite_x + plane_x * sprite_y)

    if (transform_x == 0) { transform_x = EPSILON }
    if (transform_y == 0) { transform_y = EPSILON }
    sprite_screen_x = int((SCREEN_W / 2) * (1 + transform_x / transform_y))

    sprite_w = abs(int(SCREEN_H / transform_y) * 2)
    line_start_x = -sprite_w / 2 + sprite_screen_x
    if (line_start_x < 0) {
        line_offset_x = abs(int(line_start_x))
        line_start_x  = 0
    }
    else {
        line_offset_x = 0
        line_start_x  = int(line_start_x)
    }
    line_end_x = sprite_w / 2 + sprite_screen_x
    line_end_x = line_end_x >= SCREEN_W ? SCREEN_W - 1 : int(line_end_x)

    sprite_h = abs(int(SCREEN_H / transform_y))
    line_start_y = -sprite_h / 2 + SCREEN_H / 2
    if (line_start_y < 0) {
        line_offset_y = abs(int(line_start_y))
        line_start_y  = 0
    }
    else {
        line_offset_y = 0
        line_start_y  = int(line_start_y)
    }
    line_end_y = sprite_h / 2 + SCREEN_H / 2
    line_end_y = line_end_y >= SCREEN_H ? SCREEN_H - 1 : int(line_end_y)
}

function _cast_sprite(i,    texture_x, texture_y, pixel, x, y) {
    sprites[i, "is_target"] = 0
    if (sprite_w == 0 || sprite_h == 0) { return }

    for (x = line_start_x; x <= line_end_x; x++) {
        if (           x < 0 ||           x >= SCREEN_W \
          || transform_y < 0 || transform_y >= z_buffer[x] ) { continue }
        texture_x = int( (x - line_start_x + line_offset_x) \
                         / (sprite_w / TEXTURE_W) )
        if (texture_x > TEXTURE_W - 1) { texture_x = TEXTURE_W - 1 }
        for (y = line_start_y; y <= line_end_y; y++) {
            texture_y = int( (y - line_start_y + line_offset_y) \
                             / (sprite_h / TEXTURE_H) )
            if (texture_y > TEXTURE_H - 1) { texture_y = TEXTURE_H - 1 }
            pixel = texture[sprites[i, "name"],        \
                            sprites[i, "texture_num"], \
                            texture_x, texture_y]
            if (pixel == 0) { continue  }
            if (pixel >= 8) { pixel = 0 }
            pixels[x, y] = sprintf("\033[3%d;4%dm \033[0m", pixel, pixel)
        }

        if (x < hitbox_start || x >= hitbox_end)  { continue }
        if (sprites[i, "name"]  == "treasure")    { continue }
        if (sprites[i, "state"] == STATE["DEAD"]) { continue }
        sprites[i, "is_target"] = 1
    }
}

function _cast_weapon(    pixel, x, y) {
    for (y = 0; y < TEXTURE_H; y++) {
        for (x = 0; x < TEXTURE_W; x++) {
            pixel = texture[weapons[weapon_num, "name"],        \
                            weapons[weapon_num, "texture_num"], \
                            x, y]
            if (pixel == 0) { continue  }
            if (pixel == 9) { pixel = 0 }
            pixels[WEAPON_X + x, WEAPON_Y + y] \
                = pixel == 1            \
                ? "\033[31;43m░\033[0m" \
                : pixel == 2            \
                ? "\033[36;47m░\033[0m" \
                : pixel == 8            \
                ? "\033[30;43m░\033[0m" \
                : sprintf("\033[3%d;4%dm \033[0m", pixel, pixel)
        }
    }
}

function raycast(    camera_x, determinant, i, x) {
    for (x = 0; x < SCREEN_W; x++) {
        camera_x = 2 * x / SCREEN_W - 1
        ray_pos_x = pos_x
        ray_pos_y = pos_y
        ray_dir_x = dir_x + plane_x * camera_x
        ray_dir_y = dir_y + plane_y * camera_x

        map_x = int(ray_pos_x)
        map_y = int(ray_pos_y)

        _calc_wall()
        _cast_wall(x)

        z_buffer[x] = perp_wall_dist
    }

    for (i = 0; i < NUM_SPRITES; i++) {
        sprites[i, "dist"] =   (pos_x - sprites[i, "pos_x"]) ^ 2 \
                             + (pos_y - sprites[i, "pos_y"]) ^ 2
    }
    _sort_sprites()

    determinant = plane_x * dir_y - dir_x * plane_y
    if (determinant == 0) { determinant = EPSILON }
    inv_determinant = 1 / determinant

    for (i = 0; i < NUM_SPRITES; i++) {
        _calc_sprite(i)
        _cast_sprite(i)
    }

    _cast_weapon()
}

function build_info(offset_x, offset_y,    pixmap) {
    pixmap = !is_gameover && is_paused \
           ? sprintf("\033[%d;%dH\033[33m* PAUSED *\033[0m", \
                     1 + offset_y, 5 + offset_x)             \
           : sprintf("\033[%d;%dH\033[36mTERM\033[0mMAZE\033[32m3D\033[0m", \
                     1 + offset_y, 5 + offset_x)

    pixmap = pixmap sprintf("\033[%d;%dH", 2 + offset_y, 1 + offset_x)
    if (is_attacked) { pixmap = pixmap "\033[31m" }
    pixmap = pixmap sprintf("TIME LEFT  %7d", int(time_left / 10))
    pixmap = pixmap sprintf("\033[%d;%dH", 3 + offset_y, 1 + offset_x)
    pixmap = pixmap sprintf("TREASURES  %2d / %2d", \
                            treasure_count, NUM_TREASURES)
    pixmap = pixmap sprintf("\033[%d;%dH", 4 + offset_y, 1 + offset_x)
    pixmap = pixmap sprintf("%-9s  %2d / %2d",                    \
                            toupper(weapons[weapon_num, "name"]), \
                            weapons[weapon_num, "ammo"],          \
                            weapons[weapon_num, "max_ammo"])
    if (is_attacked) { pixmap = pixmap "\033[0m" }

    if (!is_gameover) {
        pixmap = pixmap sprintf("\033[%d;%dHW/A/S/D :     MOVE", \
                                 6 + offset_y, 1 + offset_x)
        pixmap = pixmap sprintf("\033[%d;%dHJ/L     : TURN L/R", \
                                 7 + offset_y, 1 + offset_x)
        pixmap = pixmap sprintf("\033[%d;%dHK       :   ATTACK", \
                                 8 + offset_y, 1 + offset_x)
        pixmap = pixmap sprintf("\033[%d;%dHP       :    PAUSE", \
                                 9 + offset_y, 1 + offset_x)
        pixmap = pixmap sprintf("\033[%d;%dHQ       :     QUIT", \
                                10 + offset_y, 1 + offset_x)
    }
    else {
        if (has_won) {
            pixmap = pixmap sprintf("\033[%d;%dH\033[34m==================", \
                                    6 + offset_y, 1 + offset_x)
            pixmap = pixmap sprintf("\033[%d;%dH     YOU WIN!     ", \
                                    7 + offset_y, 1 + offset_x)
            pixmap = pixmap sprintf("\033[%d;%dH==================\033[0m", \
                                    8 + offset_y, 1 + offset_x)
        }
        else {
            pixmap = pixmap sprintf("\033[%d;%dH\033[31m------------------", \
                                    6 + offset_y, 1 + offset_x)
            pixmap = pixmap sprintf("\033[%d;%dH     YOU LOSE     ", \
                                    7 + offset_y, 1 + offset_x)
            pixmap = pixmap sprintf("\033[%d;%dH------------------\033[0m", \
                                    8 + offset_y, 1 + offset_x)
        }
        pixmap = pixmap sprintf("\033[%d;%dH    GAME OVER!    ", \
                                 9 + offset_y, 1 + offset_x)
        pixmap = pixmap sprintf("\033[%d;%dH  PRESS ANY KEY.  ", \
                                10 + offset_y, 1 + offset_x)
    }

    return pixmap
}

function build_screen(offset_x, offset_y,    pixmap, x, y) {
    for (y = 0; y < SCREEN_H; y++) {
        pixmap = pixmap sprintf("\033[%d;%dH", 1 + offset_y + y, 1 + offset_x)
        for (x = 0; x < SCREEN_W; x++) { pixmap = pixmap pixels[x, y] }
    }

    return pixmap
}

function build_minimap(offset_x, offset_y, \
                           pixmap, pixel,  \
                           i, x1, y1, x2, y2) {
    for (y1 = 0; y1 < MINIMAP_ROW; y1++) {
        pixmap \
            = pixmap sprintf("\033[%d;%dH", 1 + offset_y + y1, 1 + offset_x)
        for (x1 = 0; x1 < MINIMAP_COL; x1++) {
            x2 = int(pos_x) - int((MINIMAP_COL - 1) / 2) + x1
            y2 = int(pos_y) - int((MINIMAP_ROW - 1) / 2) + y1
            if ( (x2 < 0 || x2 > WORLD_MAP_W - 1) \
              || (y2 < 0 || y2 > WORLD_MAP_H - 1) ) {
                pixel = "\033[30;47m░░\033[0m"
            }
            else {
                pixel = world_map[x2, y2] == 1 \
                      ? "\033[37;47m  \033[0m" \
                      : "\033[33;42m░░\033[0m"
            }
            for (i = 0; i < NUM_SPRITES; i++) {
                if ( x2 == int(sprites[i, "pos_x"]) \
                  && y2 == int(sprites[i, "pos_y"]) ) {
                    if (sprites[i, "name"] == "monster") {
                        pixel = sprites[i, "state"] != STATE["DEAD"] \
                              ? "\033[31;41m  \033[0m"               \
                              : "\033[33;42m░░\033[0m"
                    }
                    if (sprites[i, "name"] == "treasure") {
                        pixel = sprites[i, "state"] != STATE["EMPTY"] \
                              ? "\033[33;43m  \033[0m"                \
                              : "\033[33;42m░░\033[0m"
                    }
                    if (sprites[i, "name"] == "tree") {
                        pixel = "\033[32;42m  \033[0m"
                    }
                }
            }
            if ( x1 == int((MINIMAP_COL - 1) / 2) \
              && y1 == int((MINIMAP_ROW - 1) / 2) ) {
                pixel = "\033[34;44m  \033[0m"
            }
            pixmap = pixmap pixel
        }
    }

    return pixmap
}
