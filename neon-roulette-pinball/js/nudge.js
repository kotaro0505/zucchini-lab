export class NudgeController {
  constructor() { this.reset() }

  reset() {
    this.heat = 0
    this.tilt = 0
    this.cooldown = 0
    this.wasTilted = false
    this.sequence = 0
  }

  update(dt) {
    const tiltedBefore = this.tilt > 0
    this.cooldown = Math.max(0, this.cooldown - dt)
    this.heat = Math.max(0, this.heat - dt * .34)
    this.tilt = Math.max(0, this.tilt - dt)
    const recovered = tiltedBefore && this.tilt === 0
    this.wasTilted = this.tilt > 0
    return { recovered }
  }

  use(ballX) {
    if (this.tilt > 0) return { blocked: true, reason: 'tilt' }
    if (this.cooldown > 0) return { blocked: true, reason: 'cooldown' }

    this.cooldown = .2
    this.heat += 1
    if (this.heat >= 2.55) {
      this.heat = 0
      this.tilt = 3.4
      this.wasTilted = true
      return { tilted: true, seconds: this.tilt }
    }

    this.sequence++
    const direction = ballX < 360 ? 1 : ballX > 440 ? -1 : (this.sequence % 2 ? 1 : -1)
    return {
      applied: true,
      direction,
      danger: this.heat >= 1.55,
      forceX: direction * 118,
      forceY: -52
    }
  }

  get tilted() { return this.tilt > 0 }
}
