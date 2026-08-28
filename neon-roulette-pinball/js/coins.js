const columns = [118, 196, 278, 360, 440, 522, 604, 682]

export class CoinShower {
  constructor() { this.reset() }

  reset() {
    this.coins = []
    this.serial = 0
  }

  start(count = 18) {
    for (let i = 0; i < count; i++) {
      const column = columns[(i * 3 + this.serial) % columns.length]
      const row = Math.floor(i / columns.length)
      this.coins.push({
        id: ++this.serial,
        x: column,
        y: -30 - row * 150 - (i % 4) * 44,
        baseX: column,
        r: 19,
        speed: 38 + (i % 5) * 4,
        phase: i * 1.37,
        sway: 8 + (i % 3) * 5,
        spin: i * .8,
        active: true,
        value: i % 6 === 0 ? 3000 : 1500
      })
    }
  }

  update(dt) {
    for (const coin of this.coins) {
      coin.y += coin.speed * dt
      coin.phase += dt * (1.2 + coin.speed / 90)
      coin.spin += dt * 1.35
      coin.x = coin.baseX + Math.sin(coin.phase) * coin.sway
    }
    this.coins = this.coins.filter(coin => coin.active && coin.y < 1235)
  }

  collect(ball) {
    const collected = []
    for (const coin of this.coins) {
      if (!coin.active || coin.y < 30) continue
      if (Math.hypot(ball.x - coin.x, ball.y - coin.y) > ball.r + coin.r + 12) continue
      coin.active = false
      collected.push(coin)
    }
    if (collected.length) this.coins = this.coins.filter(coin => coin.active)
    return collected
  }

  get active() { return this.coins.length > 0 }
}
