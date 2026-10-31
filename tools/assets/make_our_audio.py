import re, os
os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
OWNED = {  # the ids the owner uploaded for this game (legacy/conquest/docs/UPLOAD_ASSETS.md)
    'click': (137499164850957, 0.5), 'build': (122548385802638, 1.2), 'error': (140116904842751, 0.6),
    'notice': (90458037613275, 1.0), 'war': (126284092426471, 2.0), 'win': (133770403709310, 3.0),
}
MUSIC = {'lobby': (119425620491833, 180.0), 'battle': (73509293262264, 240.0)}
RULES = [  # key regex -> owned sound (first match); nothing matched = silent (the director skips a missing key)
    (r'^(ui_error|ui_locked|error)$', 'error'),
    (r'^(defeat|eliminate)$', 'error'),
    (r'^(victory|conquer|reveal_epic|reveal_legendary|crate_preview_epic|crate_preview_legendary|unlock|star_get)$', 'win'),
    (r'^(build|buy_spend|spawn_confirm|expand_pop|crate_open|crate_land|crate_drop)$', 'build'),
    (r'^(alliance|ally_request|queue_start|reveal_common|reveal_rare|crate_preview_common|crate_preview_rare|crate_shimmer)$', 'notice'),
    (r'^(under_attack|nuke_alarm|betrayal|game_start|countdown_gamestart|nuke_explosion|nuke_launch)$', 'war'),
    (r'^(sam_intercept)$', 'build'),
    (r'^(warship)$', 'notice'),
    (r'^(boat_launch|sam_launch|shell_fire)$', 'click'),
    (r'^(ui_click|ui_confirm|ui_tab|ui_back|ui_open|expand|order_ack|spectate_switch|card_flip|card_whoosh|crate_rattle|star_tick|countdown_tick(_\d)?)$', 'click'),
]
def pick(key):
    for rx, name in RULES:
        if re.match(rx, key):
            return name
    return None
def keys_of(path):
    s = open(path, 'rb').read().decode()
    sfx = s[s.index('sfx = {'):]
    return re.findall(r'^\t\t([a-z_0-9]+) = \{ id', sfx, re.M)
HEAD = ('-- Audio keys -> OUR sounds. Only ids the owner uploaded for this game are used (the six SFX and two tracks of\n'
        '-- legacy/conquest/docs/UPLOAD_ASSETS.md); a key with no good match is left out, and the director skips a missing key\n'
        '-- (silent, never someone else\'s sound). More sounds: add the file to assets/audio, upload it (tools/assets/upload_ours.py\n'
        '-- when a key is in .secrets/roblox_api_key), and add its id to docs/OWNED_ASSETS.txt and to RULES in this file\'s generator.\n')
def sfx_lines(keys):
    out = []
    for k in keys:
        n = pick(k)
        if n:
            i, l = OWNED[n]
            out.append(f'\t\t{k} = {{ id = "rbxassetid://{i}", length = {l} }},')
    return out
for mod in ('Audio', 'AudioExtra', 'AudioUI'):
    p = f'src/shared/Assets/{mod}.luau'
    keys = keys_of(p)
    body = [HEAD + '-- (generated; see tools/assets/make_our_audio.py)', 'return {']
    if mod == 'Audio':
        body.append('\tmusic = {')
        body.append(f'\t\tmenu = {{ id = "rbxassetid://{MUSIC["lobby"][0]}", length = {MUSIC["lobby"][1]} }},')
        body.append(f'\t\twar = {{ id = "rbxassetid://{MUSIC["battle"][0]}", length = {MUSIC["battle"][1]} }},')
        body.append('\t},')
    body.append('\tsfx = {')
    body += sfx_lines(keys)
    body += ['\t},', '}']
    open(p, 'wb').write(('\n'.join(body) + '\n').encode())
    print(mod, len(keys), 'keys,', len(sfx_lines(keys)), 'sounded')
sound = ['-- The soundtrack: the two tracks the owner uploaded for this game, played in the moods the playlist asks for.',
         '-- (The upstream\'s pack, Rodrigo Flores\' Orchestral Ambients, is no longer used, so its credit is gone too.)',
         '-- generated; see tools/assets/make_our_audio.py',
         'return {', '\tcredit = "",', '\tlicense = "",', '\ttracks = {',
         f'\t\tlobby = {{ id = "rbxassetid://{MUSIC["lobby"][0]}", length = {MUSIC["lobby"][1]}, title = "Lobby", pack = "Conquer the World" }},',
         f'\t\tbattle = {{ id = "rbxassetid://{MUSIC["battle"][0]}", length = {MUSIC["battle"][1]}, title = "Battle", pack = "Conquer the World" }},',
         '\t},', '\tmoods = {',
         '\t\ttitle = { "lobby" },', '\t\twait = { "lobby" },', '\t\tcalm = { "lobby" },', '\t\twar = { "battle" },',
         '\t\tvictory = { "lobby" },', '\t\tdefeat = { "lobby" },', '\t},', '}']
open('src/shared/Assets/Soundtrack.luau', 'wb').write(('\n'.join(sound) + '\n').encode())
