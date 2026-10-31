# Release checklist: the steps only the owner can do

Everything else is done and checked by `node tools/check.js`. Each step says what proves it worked. Steps 1 to 3 block
release; 4 to 6 do not, but the game is thinner without them.

## 1. Publish the source: DONE

Public at https://github.com/KolarF1/conquer-the-world (AGPL section 13). `HelpOverlay.SOURCE_REPO` points at it.
Every update published to Roblox needs its source pushed there too, so the public code matches what is live.

## 2. Publish the place and turn on the image APIs

The map and all the art are drawn with EditableImage. Without it **the game is blank**.

1. Open `build/ConquerTheWorld.rbxl` in Studio and use File > Publish to Roblox, under the account that uploaded the sounds.
2. Your account must be 13+ age verified and ID verified.
3. Creator Dashboard > the experience > Settings > Security: turn on **Enable Mesh / Image APIs**.
4. Game Settings > Security: turn on **Enable Studio Access to API Services**, so saves work when testing.

Proof: join the published game. The map draws, and your rank is still there after you rejoin.

## 3. One real phone, and one real second player

Studio cannot show either. I previewed phone layouts at phone size on the desktop and ran public matches with bots only.

On a phone: finish the tutorial, open COMMAND, start a War Room mission. Look for anything cut off and check tapping.
With a friend on another device: join a public match together and play past the first draft.

Send me screenshots of anything wrong, and the F9 console if something breaks.

## 4. Developer products (optional: everything paid stays hidden until then)

Create the products listed in `src/shared/Data/Products.luau` on the Creator Dashboard and paste each id into its `id`.
`tools/assets/make_arsenal_products.py` can make them with an Open Cloud key. Subscriptions: `Data/Subscription.luau`.

Proof: the Crates button shows a price and a test purchase grants the crate.

## 5. Sounds and music (optional: the game plays without them)

Today: six sound effects and two music tracks, all yours. Combat sounds are those same effects at other speeds.
For real ones, tell me to generate them (ElevenLabs bills your account, so I did not), or supply files. Then upload to the account
that owns the game, add the ids to `docs/OWNED_ASSETS.txt` and to `tools/assets/make_our_audio.py`, and remove the sound from
`AudioDirector.BASE_SPEED`. Wanted, in order: nuke explosion, shell fire, SAM launch, warship, boat launch, a second battle track.

## 6. Store page

- Icon: `assets/branding/experience_icon_512.png`. Thumbnails: take them in Studio, the World map mid-match reads best.
- Set the age questionnaire on the Creator Dashboard. Nuclear weapons and war themes need honest answers.
- The Starter Pack's "limited-time" timer is per player and inherited. Check it meets Roblox's rules on paid offers before you add its product.
