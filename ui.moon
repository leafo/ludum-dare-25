

{graphics: g} = love

export *

class HorizBar
  color: { 1, 128/255, 128/255, 128/255 }
  border: true
  padding: 1

  new: (@w, @h, @value=0.5)=>

  draw: (x, y) =>
    g.push!
    g.setColor 1,1,1

    if @border
      g.setLineWidth 0.6
      g.rectangle "line", x, y, @w, @h

      g.setColor @color
      w = @value * (@w - @padding*2)

      g.rectangle "fill", x + @padding, y + @padding, w, @h - @padding*2
    else
      g.setColor @color
      w = @value * @w
      g.rectangle "fill", x, y, w, @h

    g.pop!
    g.setColor 1,1,1,1
