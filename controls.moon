
{:joystick, :keyboard, :mouse} = love

DEADZONE = 0.25

-- gamepad button -> key name the states already understand
BUTTON_KEYS = {
  a: "return"
  start: "p"
  x: "e"
}

local mouse_active
mover = make_mover "w", "s", "a", "d"

-- the first joystick SDL knows as a gamepad
find_pad = ->
  for j in *joystick.getJoysticks!
    return j if j\isGamepad!

pad = nil

update_pad = ->
  pad = find_pad!
  mouse_active = true if mouse_active == nil and not pad

axis = (name) ->
  return 0 unless pad
  pad\getGamepadAxis name

button = (name) ->
  return false unless pad
  pad\isGamepadDown name

stick = (xaxis, yaxis) ->
  v = Vec2d axis(xaxis), axis(yaxis)
  return nil if v\len! < DEADZONE
  v

move_vector = ->
  v = mover!
  return v unless v\is_zero!
  return v unless pad

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

{
  :update_pad, :move_vector, :aim_vector, :shooting, :beam
  :mouse_moved, :mouse_aims, :button_key, :menu_open, :has_pad, :prompts
}
