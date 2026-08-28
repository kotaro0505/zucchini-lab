export class BallSafety {
  constructor(zones) {
    this.zones = zones
  }

  reset(ball) {
    ball.safety = {
      anchorX: ball.x,
      anchorY: ball.y,
      confined: 0,
      low: 0,
      cooldown: 0,
      rescues: 0
    }
  }

  update(ball, dt, cradled = false) {
    if (!ball.safety) this.reset(ball)
    const s = ball.safety
    s.cooldown = Math.max(0, s.cooldown - dt)
    if (!ball.launched || !ball.shotGate || s.cooldown > 0) return null

    const speed = Math.hypot(ball.vx, ball.vy)
    const inCradle = cradled && ball.y > 958 && ball.x > 150 && ball.x < 650
    if (inCradle) {
      s.anchorX = ball.x
      s.anchorY = ball.y
      s.confined = 0
      s.low = 0
      return null
    }

    if (Math.hypot(ball.x - s.anchorX, ball.y - s.anchorY) > 58) {
      s.anchorX = ball.x
      s.anchorY = ball.y
      s.confined = 0
    } else {
      s.confined += dt
    }
    s.low = speed < 72 ? s.low + dt : Math.max(0, s.low - dt * 1.8)

    if (s.low < 1.2 && s.confined < 3.1) return null
    const zone = this.zones.find(item => ball.x >= item.x1 && ball.x <= item.x2 && ball.y >= item.y1 && ball.y <= item.y2)
    if (!zone) return null

    const rescueX = zone.vx || (ball.x < 400 ? 320 : -320)
    const direction = Math.sign(rescueX)
    ball.x += direction * 6
    ball.vx = direction * Math.max(Math.abs(ball.vx), Math.abs(rescueX))
    ball.vy = Math.min(ball.vy, zone.vy || -380)
    s.anchorX = ball.x
    s.anchorY = ball.y
    s.confined = 0
    s.low = 0
    s.cooldown = 2.2
    s.rescues++
    return { zone: zone.id, rescues: s.rescues, speed: Math.round(speed) }
  }
}
