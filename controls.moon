
{:joystick, :keyboard, :mouse} = love

DEADZONE = 0.25

-- gamepad button -> key name the states already understand
BUTTON_KEYS = {
  a: "return"
  start: "p"
  x: "e"
}

-- guesses for a joystick that SDL has no gamepad mapping for, so the game is
-- at least playable while the debug overlay is used to build a real mapping
RAW_AXES = { leftx: 1, lefty: 2, rightx: 3, righty: 4 }
RAW_BUTTONS = { a: 1, b: 2, x: 3, y: 4, leftshoulder: 5, rightshoulder: 6, back: 7, start: 8 }

local mouse_active
mover = make_mover "w", "s", "a", "d"

find_pad = ->
  local raw
  for j in *joystick.getJoysticks!
    return j if j\isGamepad!
    raw or= j
  raw

pad = nil
mapped = false

update_pad = ->
  pad = find_pad!
  mapped = pad and pad\isGamepad! or false
  mouse_active = true if mouse_active == nil and not pad

axis = (name) ->
  return 0 unless pad
  if mapped
    pad\getGamepadAxis name
  else
    idx = RAW_AXES[name]
    idx and idx <= pad\getAxisCount! and pad\getAxis(idx) or 0

button = (name) ->
  return false unless pad
  if mapped
    pad\isGamepadDown name
  else
    idx = RAW_BUTTONS[name]
    idx and idx <= pad\getButtonCount! and pad\isDown(idx) or false

stick = (xaxis, yaxis) ->
  v = Vec2d axis(xaxis), axis(yaxis)
  return nil if v\len! < DEADZONE
  v

move_vector = ->
  v = mover!
  return v unless v\is_zero!
  return v unless pad

  if mapped
    if button "dpleft"
      v[1] = -1
    elseif button "dpright"
      v[1] = 1
    if button "dpup"
      v[2] = -1
    elseif button "dpdown"
      v[2] = 1
    return v\normalized! unless v\is_zero!

  s = stick "leftx", "lefty"
  s and s\normalized! or v

-- direction the right stick is pushed, nil when centered
aim_vector = ->
  s = stick "rightx", "righty"
  mouse_active = false if s
  s

-- the right stick both aims and shoots
shooting = -> stick("rightx", "righty") != nil

beam = ->
  keyboard.isDown("space") or button("rightshoulder") or axis("triggerright") > 0.5

-- the mouse aims until the right stick takes over
mouse_moved = -> mouse_active = true
mouse_aims = -> mouse_active

button_key = (btn) -> BUTTON_KEYS[btn]

-- holding select shows a menu where the face buttons run actions instead
menu_open = -> button "back"

has_pad = -> pad != nil

prompts = {
  confirm: -> if pad then "A" else "Enter"
  detonate: -> if pad then "X" else "E"
  pause: -> if pad then "Start" else "P"
}

-- raw state for building a gamepad mapping on a device without one
debug_lines = ->
  return {} unless pad
  lines = {
    "joystick: #{pad\getName!}"
    "guid: #{pad\getGUID!}"
    "gamepad mapping: #{mapped}"
  }

  axes = for i=1,pad\getAxisCount!
    "%.2f"\format pad\getAxis i
  table.insert lines, "axes: " .. table.concat axes, " "

  down = for i=1,pad\getButtonCount!
    continue unless pad\isDown i
    tostring i
  table.insert lines, "buttons down: " .. table.concat down, " "

  hats = for i=1,pad\getHatCount!
    pad\getHat i
  table.insert lines, "hats: " .. table.concat hats, " " if #hats > 0

  lines

{
  :update_pad, :move_vector, :aim_vector, :shooting, :beam
  :mouse_moved, :mouse_aims, :button_key, :menu_open, :has_pad, :prompts
  :debug_lines
}
